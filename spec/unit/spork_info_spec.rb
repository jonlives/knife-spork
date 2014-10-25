require 'spec_helper'
require 'chef/knife/spork-info'
require 'knife-spork/runner'

module KnifeSpork
    describe SporkInfo do

      let(:stdout_io) { StringIO.new }
      let(:stderr_io) { StringIO.new }

      subject(:knife) do
        SporkInfo.new(argv).tap do |c|
          allow(c.ui).to receive(:stdout).and_return(stdout_io)
        end
      end

      let(:argv) { [] }

      describe '#run' do
        it 'displays spork info' do
          expect(knife).to receive(:info)
          knife.run
        end
      end

      describe '#info' do
        before(:each) { set_chef_config }
        let(:fake_ui) { double(:ui, msg: nil) }

        before do
          allow(knife).to receive(:ui) { fake_ui }
        end

        it 'only calls ui.msg' do
          expect(fake_ui).to receive(:msg)
          knife.send(:info)
        end
      end
    end
end