#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'
require 'chef/knife/spork-upload'
require 'chef/cookbook_uploader'
require 'knife-spork/runner'

module KnifeSpork
  describe SporkUpload do

    let(:stdout_io) { StringIO.new }
    let(:stderr_io) { StringIO.new }
    let(:default_cookbook_path) do
      File.expand_path('cookbooks', fixtures_path)
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
      it 'uploads cookbook' do
        knife.instance_variable_set(:@cookbooks, knife.load_cookbooks(argv))
        knife.send(:upload)
      end
    end
  end
end