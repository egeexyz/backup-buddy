# frozen_string_literal: true

require 'backup_buddy'
require 'tempfile'
require 'fileutils'
require 'open3'

RSpec.describe 'Integration: rsync', :integration do
  describe 'local file copy' do
    let(:src_dir) { Dir.mktmpdir('bb-test-src') }
    let(:dest_dir) { Dir.mktmpdir('bb-test-dest') }
    let(:test_file) { 'hello.txt' }
    let(:test_content) { 'backup buddy integration test' }

    let(:manifest_yaml) do
      <<~YAML
        ---
        name: Integration Test
        concurrency: 1

        backupDestination: #{dest_dir}
        backupPaths:
          - #{src_dir}
      YAML
    end

    let(:manifest_file) do
      file = Tempfile.new(['integration', '.yaml'])
      file.write(manifest_yaml)
      file.close
      file
    end

    before do
      File.write(File.join(src_dir, test_file), test_content)
    end

    after do
      FileUtils.rm_rf(src_dir)
      FileUtils.rm_rf(dest_dir)
      manifest_file.unlink
    end

    it 'copies a file from source to destination' do
      manager = BackupBuddy::BackupManager.new(manifest_file.path)
      manager.run

      src_basename = File.basename(src_dir)
      copied = File.join(dest_dir, src_basename, test_file)
      expect(File.exist?(copied)).to be true
      expect(File.read(copied)).to eq(test_content)
    end

    it 'preserves file content 1:1' do
      manager = BackupBuddy::BackupManager.new(manifest_file.path)
      manager.run

      src_basename = File.basename(src_dir)
      original = File.join(src_dir, test_file)
      copied = File.join(dest_dir, src_basename, test_file)

      # Verify byte-for-byte match
      expect(FileUtils.compare_file(original, copied)).to be true
    end
  end

  describe 'concurrency' do
    let(:src_dirs) do
      3.times.map do |i|
        dir = Dir.mktmpdir("bb-concurrent-#{i}")
        File.write(File.join(dir, "file#{i}.txt"), "content #{i}")
        dir
      end
    end
    let(:dest_dir) { Dir.mktmpdir('bb-concurrent-dest') }

    let(:manifest_yaml) do
      paths = src_dirs.map { |d| "  - #{d}" }.join("\n")
      <<~YAML
        ---
        name: Concurrency Test
        concurrency: 2

        backupDestination: #{dest_dir}
        backupPaths:
        #{paths}
      YAML
    end

    let(:manifest_file) do
      file = Tempfile.new(['concurrent', '.yaml'])
      file.write(manifest_yaml)
      file.close
      file
    end

    after do
      src_dirs.each { |d| FileUtils.rm_rf(d) }
      FileUtils.rm_rf(dest_dir)
      manifest_file.unlink
    end

    it 'copies all paths with bounded concurrency' do
      manager = BackupBuddy::BackupManager.new(manifest_file.path)
      manager.run

      src_dirs.each_with_index do |src, i|
        src_basename = File.basename(src)
        copied = File.join(dest_dir, src_basename, "file#{i}.txt")
        expect(File.exist?(copied)).to be_truthy, "Missing: #{copied}"
      end
    end
  end
end
