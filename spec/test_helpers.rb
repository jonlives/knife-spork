require 'fileutils'
require 'tmpdir'

module TestHelpers
  def tempdir
    @tmpdir ||= Dir.mktmpdir("knife-spork")
    File.realpath(@tmpdir)
  end

  def fixtures_path
    File.expand_path(File.dirname(__FILE__) + "/unit/fixtures/")
  end

  def stdout
    stdout_io.string
  end

  def set_chef_config
    knife.config[:chef_repo_path] = tempdir
    knife.config[:cookbook_path] = File.join(fixtures_path, 'cookbooks')
    knife.config[:environment_path] = File.join(fixtures_path, 'environments')
    knife.config[:chef_server_url] = "http://localhost:4000"
    knife.config[:client_key] = File.join(fixtures_path, 'test_client.pem')
    knife.config[:client_name] = "test-client"
    knife.config[:node_name] = "test-node"
    knife.config[:cache_type] = 'BasicFile'
    knife.config[:cache_options] = {:path =>  File.join(fixtures_path, 'checksums')}
  end
end