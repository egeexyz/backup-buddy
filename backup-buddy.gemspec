# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'backup-buddy'
  spec.version       = File.read(File.expand_path('VERSION', __dir__)).strip
  spec.authors       = ['Egee']
  spec.summary       = 'Back up your things with rsync!'
  spec.description   = 'A Ruby harness around rsync to back up files and folders in parallel with threads.'
  spec.homepage      = 'https://github.com/egeexyz/backup-buddy'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*', 'bin/*', 'VERSION', 'LICENSE', 'README.md']

  spec.add_dependency 'foghorn-logger', '~> 1.0'
  spec.bindir        = 'bin'
  spec.executables   = ['backup-buddy']
  spec.require_paths = ['lib']
end
