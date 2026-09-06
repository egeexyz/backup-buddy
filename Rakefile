# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'fileutils'

VERSION_FILE = 'VERSION'

def get_current_version
  File.read(VERSION_FILE).strip
end

def write_version(new_version)
  old_version = get_current_version
  File.write(VERSION_FILE, "#{new_version}\n")
  puts "Bumped version: #{old_version} -> #{new_version}"
end

RSpec::Core::RakeTask.new(:rspec)

desc 'Run RuboCop linter'
task :lint do
  sh 'bundle exec rubocop'
end

desc 'Run tests and linter'
task test: %i[rspec lint]

task spec: :test

task default: :test

desc 'Increment the patch version (0.1.0 -> 0.1.1)'
task :bump do
  major, minor, patch = get_current_version.split('.').map(&:to_i)
  write_version("#{major}.#{minor}.#{patch + 1}")
end

namespace :bump do
  desc 'Increment the minor version (0.1.0 -> 0.2.0)'
  task :minor do
    major, minor, _patch = get_current_version.split('.').map(&:to_i)
    write_version("#{major}.#{minor + 1}.0")
  end

  desc 'Increment the major version (0.1.0 -> 1.0.0)'
  task :major do
    major, _minor, _patch = get_current_version.split('.').map(&:to_i)
    write_version("#{major + 1}.0.0")
  end
end

desc 'Build the gem into the dist directory'
task :build do
  FileUtils.mkdir_p('dist')

  puts 'Building the gem...'
  sh 'gem build backup-buddy.gemspec'

  gem_file = "backup-buddy-#{get_current_version}.gem"
  FileUtils.mv(gem_file, "dist/#{gem_file}")
  puts "Successfully built dist/#{gem_file}"
end

desc 'Publish the gem to RubyGems'
task push: :build do
  gem_file = "dist/backup-buddy-#{get_current_version}.gem"
  puts "Pushing #{gem_file} to RubyGems..."
  sh "gem push #{gem_file}"
end
