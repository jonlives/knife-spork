#!/usr/bin/env rake
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
require 'chef_zero/server'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = [].tap do |a|
    a.push('--color')
    a.push('--format doc')
  end.join(' ')
end

desc 'Run all tests'
task :test => [:spec]

task :preseed_test_environment do
  puts "Creating checksums directory"
  `mkdir spec/unit/fixtures/checksums`
  puts "Starting chef-zero server"
  @server = ChefZero::Server.new(port: 4000)
  @server.start_background
  puts "Uploading test data"
  system("knife cookbook upload example -c spec/unit/fixtures/knife.rb")
  system("knife environment from file spec/unit/fixtures/environments/example.json -c spec/unit/fixtures/knife.rb")
end

task :cleanup_test_environment do
  puts "Stopping chef-zero server"
  @server.stop
  puts "Cleaning up checksums"
  `rm -rf spec/unit/fixtures/checksums`
end

task :default => [:preseed_test_environment, :test, :cleanup_test_environment]