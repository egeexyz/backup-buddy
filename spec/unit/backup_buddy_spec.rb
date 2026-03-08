# frozen_string_literal: true

require 'backup_buddy'
require 'tempfile'

RSpec.describe BackupBuddy::RsyncFactory do
  subject { described_class.new }

  describe '#spawn' do
    it 'creates a task with default rsync args' do
      task = subject.spawn(src: '/tmp/src', dest: '/tmp/dest')
      expect(task.command).to include('-avzP --no-links')
    end

    it 'includes exclude flags in the command' do
      task = subject.spawn(
        src: '/tmp/src',
        dest: '/tmp/dest',
        excludes: "--exclude='.git' --exclude='*.log'"
      )
      expect(task.command).to include("--exclude='.git'")
      expect(task.command).to include("--exclude='*.log'")
    end

    it 'returns an RsyncTask' do
      task = subject.spawn(src: '/tmp/src', dest: '/tmp/dest')
      expect(task).to be_a(BackupBuddy::RsyncTask)
    end

    it 'shell-escapes paths with spaces' do
      task = subject.spawn(src: '/tmp/my files', dest: '/tmp/dest')
      expect(task.command).to include('my\\ files')
    end

    it 'injects --dry-run flag when dry_run is true' do
      task = subject.spawn(src: '/tmp/src', dest: '/tmp/dest', dry_run: true)
      expect(task.command).to include('--dry-run')
    end

    it 'omits --dry-run flag when dry_run is false' do
      task = subject.spawn(src: '/tmp/src', dest: '/tmp/dest', dry_run: false)
      expect(task.command).not_to include('--dry-run')
    end
  end

  describe '#initialize (validate_rsync!)' do
    it 'does not raise an error when rsync is executable' do
      allow(File).to receive(:executable?).and_return(true)
      allow_any_instance_of(described_class).to receive(:`).and_return('')

      expect { described_class.new(bin: '/usr/bin/rsync') }.not_to raise_error
    end

    it 'raises an error when rsync is utterly missing' do
      allow(File).to receive(:executable?).and_return(false)
      allow_any_instance_of(described_class).to receive(:`).and_return('')

      expect { described_class.new(bin: '/missing-rsync') }.to raise_error(%r{rsync not found at '/missing-rsync'})
    end
  end
end

RSpec.describe BackupBuddy::BackupManager do
  let(:manifest_yaml) do
    <<~YAML
      ---
      name: Test Backup
      concurrency: 2
      rsync_path: "/usr/bin/rsync"
      backupDestination: /tmp/backup-buddy-test-dest
      backupPaths:
        - /tmp/backup-buddy-test-src
      ignorePatterns:
        - .git
        - "*.log"
    YAML
  end

  let(:manifest_file) do
    file = Tempfile.new(%w[test-manifest .yaml])
    file.write(manifest_yaml)
    file.close
    file
  end

  after { manifest_file.unlink }

  subject { described_class.new(manifest_file.path) }

  describe '#initialize' do
    it 'parses the manifest name' do
      expect(subject.name).to eq('Test Backup')
    end

    it 'parses the backup destination' do
      expect(subject.destination).to eq('/tmp/backup-buddy-test-dest')
    end

    it 'parses backup paths' do
      expect(subject.paths).to eq(['/tmp/backup-buddy-test-src'])
    end

    it 'parses concurrency' do
      expect(subject.concurrency).to eq(2)
    end

    it 'builds exclude flags from ignore patterns' do
      expect(subject.excludes).to include("--exclude='.git'")
      expect(subject.excludes).to include("--exclude='*.log'")
    end
  end

  describe '#initialize with defaults' do
    let(:manifest_yaml) do
      <<~YAML
        ---
        name: Minimal Manifest
        backupDestination: /tmp/dest
        backupPaths:
          - /tmp/src
      YAML
    end

    it 'defaults concurrency to 3' do
      expect(subject.concurrency).to eq(3)
    end

    it 'handles missing ignore patterns gracefully' do
      expect(subject.excludes).to eq('')
    end
  end

  describe 'path validation' do
    it 'accepts local absolute paths' do
      expect(subject.send(:valid_path?, '/tmp/local-path')).to be true
    end

    it 'accepts remote rsync paths with absolute remote path' do
      expect(subject.send(:valid_path?, 'nextcloud.local:/mnt/data/files/')).to be true
      expect(subject.send(:valid_path?, 'myhost:/var/backups')).to be true
    end

    it 'rejects bare relative paths' do
      expect(subject.send(:valid_path?, 'relative/bad-path')).to be false
    end

    it 'rejects paths with no slash or colon' do
      expect(subject.send(:valid_path?, 'nohost-noslash')).to be false
    end

    it 'rejects remote paths with relative remote portion' do
      expect(subject.send(:valid_path?, 'host:relative/path')).to be false
    end
  end

  describe '#run (mocked)' do
    let(:manifest_yaml) do
      <<~YAML
        ---
        name: Mocked Run Test
        concurrency: 2
        backupDestination: /tmp/dest
        backupPaths:
          - /tmp/path-a
          - /tmp/path-b
      YAML
    end

    it 'spawns tasks and executes them through the thread pool' do
      allow(subject).to receive(:execute_task).and_return(0)

      subject.run

      expect(subject).to have_received(:execute_task).twice
    end

    it 'reports failures from non-zero exit codes' do
      allow(subject).to receive(:execute_task).and_return(23)

      expect { subject.run }.to output(/FAILED/).to_stdout
    end
  end

  describe 'dry run' do
    it 'defaults dry_run to false' do
      expect(subject.dry_run).to be false
    end

    it 'accepts dry_run flag' do
      manager = described_class.new(manifest_file.path, dry_run: true)
      expect(manager.dry_run).to be true
    end

    it 'shows DRY RUN banner when enabled' do
      manager = described_class.new(manifest_file.path, dry_run: true)
      allow(manager).to receive(:execute_task).and_return(0)

      expect { manager.run }.to output(/DRY RUN/).to_stdout
    end
  end
end
