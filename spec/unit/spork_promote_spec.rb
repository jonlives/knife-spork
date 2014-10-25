require 'spec_helper'
require 'chef/knife/spork-promote'
require 'knife-spork/runner'

module KnifeSpork
  describe SporkPromote do

    let(:stdout_io) { StringIO.new }
    let(:stderr_io) { StringIO.new }

    before(:all) do
      copy_test_data
    end

    after(:all) do
      cleanup_test_data
    end

    subject(:knife) do
      SporkPromote.new(argv).tap do |c|
        allow(c.ui).to receive(:stdout).and_return(stdout_io)
      end
    end

    let(:environment_file) { "#{environment_path}/example.json" }

    let(:argv) { ["example", "example"] }

    describe '#run' do
      before(:each) { set_chef_config }
      it 'calls promote method' do
        expect(knife).to receive(:promote)
        knife.run
      end

      it 'calls save_environment_changes method by default' do
        expect(knife).to receive(:save_environment_changes)
        knife.run
      end

      it 'calls save_environment_changes_remote method when --remote is specified' do
        knife.config[:remote] = true
        expect(knife).to receive(:save_environment_changes_remote)
        knife.run
      end
    end

    describe '#promote' do
      before(:each) { set_chef_config }
      it 'updates version constraint for cookbook' do
        knife.instance_variable_set(:@environments, ["example"])
        knife.instance_variable_set(:@cookbook, "example")
        expect(knife).to receive(:update_version_constraints)
        knife.send(:promote, knife.load_environment_from_file("example"), "example")
      end
    end

    describe '#save_environment_changes' do
      before(:each) { set_chef_config }
      it 'updates the constraint in the environment file' do
        knife.instance_variable_set(:@environments, ["example"])
        knife.instance_variable_set(:@cookbook, "example")
        knife.send(:save_environment_changes, "example", knife.pretty_print_json(knife.load_environment_from_file("example").to_hash))
        File.read(environment_file).should include "\"example\": \"= 0.0.1\""
      end
    end

    describe '#save_environment_changes_remote' do
      before(:each) { set_chef_config }
      it 'saves the environment change to the server' do
        knife.instance_variable_set(:@environments, ["example"])
        knife.instance_variable_set(:@cookbook, "example")
        knife.send(:save_environment_changes_remote, "example")
      end
    end
  end
end