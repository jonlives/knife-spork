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

  def cookbook_path
    File.expand_path('cookbooks', tempdir)
  end

  def environment_path
    File.expand_path('environments', tempdir)
  end

  def stdout
    stdout_io.string
  end

  def set_chef_config
    knife.config[:chef_repo_path] = tempdir
    knife.config[:cookbook_path] = File.join(tempdir, 'cookbooks')
    knife.config[:environment_path] = File.join(tempdir, 'environments')
    knife.config[:chef_server_url] = "http://localhost:4000"
    knife.config[:client_key] = File.join(tempdir, 'test_client.pem')
    knife.config[:client_name] = "test-client"
    knife.config[:node_name] = "test-node"
    knife.config[:cache_type] = 'BasicFile'
    knife.config[:cache_options] = {:path =>  File.join(tempdir, 'checksums')}
  end


  def copy_test_data
    FileUtils.cp_r "#{fixtures_path}/.", tempdir
  end

  def cleanup_test_data
    FileUtils.rm_r Dir.glob("#{tempdir}/*")
  end
end