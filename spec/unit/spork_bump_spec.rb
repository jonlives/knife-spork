require 'spec_helper'
require 'chef/knife/spork-bump'
require 'knife-spork/runner'
require 'fileutils'

module KnifeSpork
  describe SporkBump do

    let(:stdout_io) { StringIO.new }
    let(:stderr_io) { StringIO.new }

    subject(:knife) do
      SporkBump.new(argv).tap do |c|
        allow(c.ui).to receive(:stdout).and_return(stdout_io)
      end
    end

    before(:all) do
      copy_test_data
    end

    after(:all) do
      cleanup_test_data
    end

    let(:argv) { ["example"] }

    let(:metadata_file) { "#{cookbook_path}/example/metadata.rb" }

    describe '#run' do
      before(:each) { set_chef_config }
      it 'calls bump method' do
        expect(knife).to receive(:bump)
        knife.run
      end
    end

    describe '#bump' do
      before(:each) { set_chef_config }
      it 'automatically bumps patch level' do
        knife.instance_variable_set(:@cookbook, knife.load_cookbook(argv.first))
        knife.send(:bump)
        File.read(metadata_file).should include "version \"0.0.2\""
      end

      it 'manually bumps patch version level' do
        knife.instance_variable_set(:@cookbook, knife.load_cookbook(argv.first))
        knife.instance_variable_set(:@name_args, ["example","patch"])
        knife.send(:bump)
        File.read(metadata_file).should include "version \"0.0.3\""
      end

      it 'manually bumps minor version level' do
        knife.instance_variable_set(:@cookbook, knife.load_cookbook(argv.first))
        knife.instance_variable_set(:@name_args, ["example","minor"])
        knife.send(:bump)
        File.read(metadata_file).should include "version \"0.1.0\""
      end

      it 'manually bumps major version level' do
        knife.instance_variable_set(:@cookbook, knife.load_cookbook(argv.first))
        knife.instance_variable_set(:@name_args, ["example","major"])
        knife.send(:bump)
        File.read(metadata_file).should include "version \"1.0.0\""
      end

      it 'manually sets version to 0.0.1' do
        knife.instance_variable_set(:@cookbook, knife.load_cookbook(argv.first))
        knife.instance_variable_set(:@name_args, ["example", "manual", "0.0.1"])
        knife.send(:bump)
        File.read(metadata_file).should include "version \"0.0.1\""
      end
    end
  end
end