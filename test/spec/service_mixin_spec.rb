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

describe PoiseService::ServiceMixin do
  context 'in a resource' do
    resource(:poise_test) do
      include PoiseService::ServiceMixin
    end
    subject { resource(:poise_test) }

    it { is_expected.to include PoiseService::ServiceMixin }
    it { is_expected.to include PoiseService::ServiceMixin::Resource }
  end # /context in a resource

  context 'in a provider' do
    provider(:poise_test) do
      include PoiseService::ServiceMixin
    end
    subject { provider(:poise_test) }

    it { is_expected.to include PoiseService::ServiceMixin }
    it { is_expected.to include PoiseService::ServiceMixin::Provider }
  end # /context in a provider
end # /describe PoiseService::ServiceMixin

describe PoiseService::ServiceMixin::Resource do
  subject { resource(:poise_test).new('test', nil) }

  context 'with Poise already included' do
    resource(:poise_test) do
      include Poise
      provides(:poise_test_other)
      actions(:doit)
      include PoiseService::ServiceMixin::Resource
    end

    it { expect(Array(subject.action)).to eq %i{doit} }
    its(:allowed_actions) { is_expected.to eq %i{nothing doit enable disable start stop restart reload} }
    its(:service_name) { is_expected.to eq 'test' }
  end # /context with Poise already included

  context 'without Poise already included' do
    resource(:poise_test) do
      include PoiseService::ServiceMixin::Resource
      actions(:doit)
    end

    it { expect(Array(subject.action)).to eq %i{enable} }
    its(:allowed_actions) { is_expected.to eq %i{nothing enable disable start stop restart reload doit} }
    its(:service_name) { is_expected.to eq 'test' }
  end # /context without Poise already included
end # /describe PoiseService::ServiceMixin::Resource

describe PoiseService::ServiceMixin::Provider do
  let(:new_resource) { double('new_resource', name: 'test') }
  let(:service_resource) { double('service_resource', updated_by_last_action: nil) }
  provider(:poise_test) do
    include PoiseService::ServiceMixin::Provider
  end
  subject { provider(:poise_test).new(new_resource, nil) }

  describe 'actions' do
    before do
      allow(subject).to receive(:notify_if_service) {|&block| block.call }
      allow(subject).to receive(:service_resource).and_return(service_resource)
    end

    describe '#action_enable' do
      it do
        expect(service_resource).to receive(:run_action).with(:enable)
        subject.action_enable
      end
    end # /describe #action_enable

    describe '#action_disable' do
      it do
        expect(service_resource).to receive(:run_action).with(:disable)
        subject.action_disable
      end
    end # /describe #action_disable

    describe '#action_start' do
      it do
        expect(service_resource).to receive(:run_action).with(:start)
        subject.action_start
      end
    end # /describe #action_start

    describe '#action_stop' do
      it do
        expect(service_resource).to receive(:run_action).with(:stop)
        subject.action_stop
      end
    end # /describe #action_stop

    describe '#action_restart' do
      it do
        expect(service_resource).to receive(:run_action).with(:restart)
        subject.action_restart
      end
    end # /describe #action_restart

    describe '#action_reload' do
      it do
        expect(service_resource).to receive(:run_action).with(:reload)
        subject.action_reload
      end
    end # /describe #action_reload
  end # /describe actions

  describe '#notify_if_service' do
    before do
      allow(subject).to receive(:service_resource).and_return(service_resource)
    end

    context 'with an update' do
      it do
        expect(service_resource).to receive(:updated_by_last_action?).and_return(true)
        expect(new_resource).to receive(:updated_by_last_action).with(true)
        subject.send(:notify_if_service)
      end
    end # /context with an update

    context 'with no update' do
      it do
        expect(service_resource).to receive(:updated_by_last_action?).and_return(false)
        subject.send(:notify_if_service)
      end
    end # /context with no update
  end # /describe #notify_if_service

  describe '#service_resource' do
    it do
      allow(new_resource).to receive(:source_line).and_return('path.rb:1')
      allow(new_resource).to receive(:service_name).and_return('test')
      fake_poise_service = double('poise_service')
      expect(PoiseService::Resources::PoiseService::Resource).to receive(:new).with('test', nil).and_return(fake_poise_service)
      expect(fake_poise_service).to receive(:declared_type=).with(:poise_service)
      expect(fake_poise_service).to receive(:enclosing_provider=).with(subject)
      expect(fake_poise_service).to receive(:source_line=).with('path.rb:1')
      expect(fake_poise_service).to receive(:service_name).with('test')
      expect(subject).to receive(:service_options).with(fake_poise_service)
      subject.send(:service_resource)
    end
  end # /describe #service_resource

  describe '#service_options' do
    it { expect(subject.send(:service_options, nil)).to be_nil }
  end # /describe #service_options
end # /describe PoiseService::ServiceMixin::Provider
