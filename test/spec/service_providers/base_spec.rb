#
# Copyright 2015-2016, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'

describe PoiseService::ServiceProviders::Base do
  let(:new_resource) { double('new_resource') }
  let(:run_context) { double('run_context') }
  let(:service_resource) do
    double('service_resource').tap do |r|
      allow(r).to receive(:updated_by_last_action).with(false)
      allow(r).to receive(:updated_by_last_action?).and_return(false)
    end
  end
  let(:options) { Hash.new }
  subject(:provider) do
    described_class.new(new_resource, run_context).tap do |provider|
      allow(provider).to receive(:notifying_block) {|&block| block.call }
      allow(provider).to receive(:service_resource).and_return(service_resource)
      allow(provider).to receive(:options).and_return(options)
    end
  end

  describe '#action_enable' do
    it do
      expect(subject).to receive(:create_service).ordered
      expect(service_resource).to receive(:run_action).with(:enable).ordered
      expect(service_resource).to receive(:run_action).with(:start).ordered
      subject.action_enable
    end
  end # /describe #action_enable

  describe '#action_disable' do
    it do
      expect(service_resource).to receive(:run_action).with(:stop).ordered
      expect(service_resource).to receive(:run_action).with(:disable).ordered
      expect(subject).to receive(:destroy_service).ordered
      subject.action_disable
    end
  end # /describe #action_disable

  describe '#action_start' do
    it do
      expect(service_resource).to receive(:run_action).with(:start).ordered
      subject.action_start
    end

    context 'with never_start' do
      before { options['never_start'] = true }
      it do
        expect(service_resource).to_not receive(:run_action).with(:start).ordered
        subject.action_start
      end
    end # /context with never_start
  end # /describe #action_start

  describe '#action_stop' do
    it do
      expect(service_resource).to receive(:run_action).with(:stop).ordered
      subject.action_stop
    end

    context 'with never_stop' do
      before { options['never_stop'] = true }
      it do
        expect(service_resource).to_not receive(:run_action).with(:stop).ordered
        subject.action_stop
      end
    end # /context with never_stop
  end # /describe #action_stop

  describe '#action_restart' do
    it do
      expect(service_resource).to receive(:run_action).with(:restart).ordered
      subject.action_restart
    end

    context 'with never_restart' do
      before { options['never_restart'] = true }
      it do
        expect(service_resource).to_not receive(:run_action).with(:restart).ordered
        subject.action_restart
      end
    end # /context with never_restart
  end # /describe #action_restart

  describe '#action_reload' do
    it do
      expect(service_resource).to receive(:run_action).with(:reload).ordered
      subject.action_reload
    end

    context 'with never_reload' do
      before { options['never_reload'] = true }
      it do
        expect(service_resource).to_not receive(:run_action).with(:reload).ordered
        subject.action_reload
      end
    end # /context with never_reload
  end # /describe #action_reload

  describe '#pid' do
    it do
      expect { subject.send(:pid) }.to raise_error(NotImplementedError)
    end
  end # /describe #pid

  describe '#create_service' do
    it do
      expect { subject.send(:create_service) }.to raise_error(NotImplementedError)
    end
  end # /describe #create_service

  describe '#destroy_service' do
    it do
      expect { subject.send(:destroy_service) }.to raise_error(NotImplementedError)
    end
  end # /describe #destroy_service

  describe '#service_template' do
    let(:new_resource) do
      double('new_resource',
             command: 'myapp --serve',
             cookbook_name: :test_cookbook,
             directory: '/cwd',
             environment: Hash.new,
             reload_signal: 'HUP',
             restart_on_update: true,
             service_name: 'myapp',
             stop_signal: 'TERM',
             user: 'root',
             )
    end
    let(:run_context) { chef_run.run_context }
    let(:options) { Hash.new }
    let(:block) { Proc.new { } }
    before do
      allow(provider).to receive(:options).and_return(options)
    end
    subject do
      provider.send(:service_template, '/test', 'source.erb', &block)
    end

    context 'with no block' do
      its(:owner) { is_expected.to eq 'root' }
      its(:source) { is_expected.to eq 'source.erb'}
      its(:cookbook) { is_expected.to eq 'poise-service'}
    end # /context with no block

    context 'with a block' do
      let(:block) do
        Proc.new do
          owner('nobody')
          variables.update(mykey: 'myvalue')
        end
      end
      its(:owner) { is_expected.to eq 'nobody' }
      its(:variables) { are_expected.to include({mykey: 'myvalue'}) }
      its(:source) { is_expected.to eq 'source.erb'}
      its(:cookbook) { is_expected.to eq 'poise-service'}
    end # /context with a block

    context 'with a template override' do
      let(:options) { {'template' => 'override.erb'} }
      its(:source) { is_expected.to eq 'override.erb'}
      its(:cookbook) { is_expected.to eq 'test_cookbook'}
    end # /context with a template override

    context 'with a template and cookbook override' do
      let(:options) { {'template' => 'other:override.erb'} }
      its(:source) { is_expected.to eq 'override.erb'}
      its(:cookbook) { is_expected.to eq 'other'}
    end # /context with a template and cookbook override
  end # /describe #service_template

  describe '#options' do
    service_provider('dummy')
    subject { chef_run.poise_service('test').provider_for_action(:enable).options }

    context 'with an options resource' do
      recipe(subject: false) do
        poise_service 'test' do
          service_name 'other'
        end

        poise_service_options 'test' do
          command 'myapp'
        end
      end

      it { is_expected.to eq({'command' => 'myapp', 'provider' => 'dummy', 'restart_delay' => 1}) }
    end # /context with an options resource

    context 'with an options resource using service_name' do
      recipe(subject: false) do
        poise_service 'test' do
          service_name 'other'
        end

        poise_service_options 'other' do
          command 'myapp'
        end
      end

      it { is_expected.to eq({'command' => 'myapp', 'provider' => 'dummy', 'restart_delay' => 1}) }
    end # /context with an options resource using service_name

    context 'with node attributes' do
      before do
        override_attributes['poise-service']['test'] = {command: 'myapp'}
      end
      recipe(subject: false) do
        poise_service 'test' do
          service_name 'other'
        end
      end

      it { is_expected.to eq({'command' => 'myapp', 'provider' => 'dummy', 'restart_delay' => 1}) }
    end # /context with node attributes

    context 'with node attributes using service_name' do
      before do
        override_attributes['poise-service']['other'] = {command: 'myapp'}
      end
      recipe(subject: false) do
        poise_service 'test' do
          service_name 'other'
        end
      end

      it { is_expected.to eq({'command' => 'myapp', 'provider' => 'dummy', 'restart_delay' => 1}) }
    end # /context with node attributes using service_name
  end # /describe #options
end
