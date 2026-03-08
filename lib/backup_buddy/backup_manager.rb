# frozen_string_literal: true

require 'yaml'
require 'open3'
require 'foghorn'
require_relative 'rsync_factory'

module BackupBuddy
  # Reads manifest, uses RsyncFactory to spawn tasks, and runs em
  # through a thread pool with configurable concurrency.
  class BackupManager
    DEFAULT_CONCURRENCY = 3

    attr_reader :name, :destination, :paths,
                :concurrency, :excludes, :dry_run

    def initialize(manifest_path, dry_run: false)
      manifest = YAML.load_file(manifest_path)

      @name        = manifest['name']
      @destination = manifest['backupDestination']
      @paths       = manifest['backupPaths'] || []
      @concurrency = manifest.fetch('concurrency', DEFAULT_CONCURRENCY)
      @excludes    = build_excludes(manifest['ignorePatterns'])
      @dry_run     = dry_run

      rsync_bin = manifest.fetch('rsync_path', '/usr/bin/rsync')
      @factory  = RsyncFactory.new(bin: rsync_bin)
    end

    def run
      valid_paths = validate_paths(@paths)
      return if valid_paths.empty?
      return unless valid_destination?(@destination)

      print_header(valid_paths)

      tasks = valid_paths.map { |path| spawn_task(path) } # Spawn tasks from the factory
      results = run_pool(tasks)                           # Run on thread pool w/concurrency control!

      print_summary(tasks, results)
    end

    private

    def valid_destination?(dest)
      return true unless dest.start_with?('/')
      return true if File.directory?(dest)

      Foghorn.error("Destination '#{dest}' does not exist or is not a directory. Please create it first.")
      false
    end

    def build_excludes(patterns)
      return '' unless patterns.is_a?(Array)

      patterns.map { |p| "--exclude='#{p}'" }.join(' ')
    end

    def validate_paths(paths)
      valid = []
      paths.each do |path|
        if valid_path?(path)
          valid << path
        else
          Foghorn.warn("Skipping '#{path}' — local paths must start with /, remote paths must be host:/absolute/path")
        end
      end
      valid
    end

    def valid_path?(path)
      return true if path.start_with?('/')

      # Remote rsync path: host:/absolute/path
      if path.include?(':')
        _host, remote_path = path.split(':', 2)
        return remote_path.start_with?('/')
      end

      false
    end

    def spawn_task(src_path)
      @factory.spawn(
        src: src_path,
        dest: @destination,
        excludes: @excludes,
        dry_run: @dry_run
      )
    end

    def run_pool(tasks)
      queue = Queue.new
      tasks.each { |t| queue << t }

      results = Array.new(tasks.length)
      mutex = Mutex.new

      # Spawn worker threads up to concurrency limit
      workers = @concurrency.times.map do
        Thread.new do
          loop do
            task, index = mutex.synchronize do
              break nil if queue.empty?

              t = queue.pop
              i = tasks.index(t)
              [t, i]
            end
            break unless task

            exit_code = execute_task(task)
            mutex.synchronize { results[index] = exit_code }
          end
        end
      end

      workers.each(&:join)
      results
    end

    def execute_task(task)
      prefix = "[#{task.label}]"
      Foghorn.debug("#{prefix} #{task.command}")

      status = nil
      Open3.popen3(task.command) do |_stdin, stdout, stderr, wait_thr|
        stdout_reader = Thread.new do
          stdout.each_line { |line| Foghorn.info("#{prefix} #{line.chomp}") }
        end

        stderr_reader = Thread.new do
          stderr.each_line { |line| Foghorn.warn("#{prefix} #{line.chomp}") }
        end

        stdout_reader.join
        stderr_reader.join
        status = wait_thr.value
      end

      code = status&.exitstatus || 1
      if code.zero?
        Foghorn.success("#{prefix} completed")
      else
        Foghorn.error("#{prefix} failed (exit #{code})")
      end
      code
    end

    def print_header(valid_paths)
      Foghorn.warn('DRY RUN — no files will be modified') if @dry_run
      Foghorn.info("Starting Job: #{@name}")
      Foghorn.info("Destination: #{@destination}")
      Foghorn.debug("Paths: #{valid_paths.length} | Concurrency: #{@concurrency}")
    end

    def print_summary(tasks, exit_codes)
      puts
      Foghorn.info('≈≈ Backup Summary ≈≈')

      tasks.each_with_index do |task, i|
        code = exit_codes[i] || 1
        if code.zero?
          Foghorn.success("  OK #{task.label}")
        else
          Foghorn.error("  FAILED (exit #{code}) #{task.label}")
        end
      end

      failures = exit_codes.count { |c| c.nil? || !c.zero? }
      if failures.zero?
        Foghorn.success("All #{tasks.length} paths completed successfully.")
      else
        Foghorn.error("#{failures}/#{tasks.length} paths failed.")
      end
    end
  end
end
