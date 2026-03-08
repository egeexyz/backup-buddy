# frozen_string_literal: true

require 'shellwords'
require_relative 'rsync_task'

module BackupBuddy
  # Factory that validates rsync availability and spawns lightweight
  # RsyncTask instances with the default rsync arguments.
  class RsyncFactory
    DEFAULT_ARGS = '-avzP --no-links'
    attr_reader :bin

    def initialize(bin: '/usr/bin/rsync')
      @bin = bin
      validate_rsync!
    end

    def spawn(src:, dest:, excludes: '', dry_run: false)
      args = DEFAULT_ARGS
      args = "--dry-run #{args}" if dry_run
      escaped_src = Shellwords.shellescape(src)
      escaped_dest = Shellwords.shellescape(dest)
      cmd = "#{@bin} #{args} #{excludes} #{escaped_src} #{escaped_dest}".squeeze(' ').strip

      RsyncTask.new(
        command: cmd,
        label: src
      )
    end

    private

    def validate_rsync!
      rsync_path = `which #{@bin} 2>/dev/null`.strip
      return unless rsync_path.empty?

      # Fall back to checking the exact path
      return if File.executable?(@bin)

      raise "rsync not found at '#{@bin}'. Install it first."
    end
  end
end
