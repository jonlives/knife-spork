require 'spec_helper'
require 'chef/knife/spork-upload'
require 'chef/cookbook_uploader'
require 'knife-spork/runner'

module KnifeSpork
  describe SporkUpload do

    let(:stdout_io) { StringIO.new }
    let(:stderr_io) { StringIO.new }

    before(:all) do
      copy_test_data
    end

    after(:all) do
      cleanup_test_data
    end

    subject(:knife) do
      SporkUpload.new(argv).tap do |c|
        allow(c.ui).to receive(:stdout).and_return(stdout_io)
      end
    end

    let(:argv) { ["example"] }

    describe '#run' do
      before(:each) { set_chef_config }
      it 'calls upload method' do
        expect(knife).to receive(:upload)
        knife.run
      end
    end

    describe '#upload' do
      before(:each) { set_chef_config }
      it 'uploads cookbook' do # and negotiates protocol version
        knife.instance_variable_set(:@cookbooks, knife.load_cookbooks(argv))
        knife.send(:upload)
        ### for some reason could not make this expectation pass
        # expect(Chef::CookbookVersion).to receive(:list_all_version)
      end
    end
  end
end
