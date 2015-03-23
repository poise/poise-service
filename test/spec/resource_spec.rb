#
# Copyright 2015, Noah Kantrowitz
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

describe PoiseService::Resource do
  service_provider('auto')
  service_resource_hints(%i{debian redhat upstart systemd})

  describe 'provider lookup' do
    recipe(subject: false) do
      poise_service 'test'
    end
    subject do
      chef_run.find_resource(:poise_service, 'test').provider_for_action(:enable).class.poise_service_provides
    end

    context 'auto on debian' do
      service_resource_hints(:debian)
      it { is_expected.to eq :sysvinit }
    end # /context auto on debian

    context 'auto on redhat' do
      service_resource_hints(:redhat)
      it { is_expected.to eq :sysvinit }
    end # /context auto on redhat

    context 'auto on upstart' do
      service_resource_hints(:upstart)
      it { is_expected.to eq :upstart }
    end # /context auto on upstart

    context 'auto on systemd' do
      service_resource_hints(:systemd)
      it { is_expected.to eq :systemd }
    end # /context auto on systemd

    context 'auto on multiple systems' do
      service_resource_hints(%i{debian invokerd upstart})
      it { is_expected.to eq :upstart }
    end # /context auto on multiple systems

    context 'global override' do
      service_provider('sysvinit')
      it { is_expected.to eq :sysvinit }
    end # /context global override

    context 'per-service override' do
      service_provider('test', 'sysvinit')
      it { is_expected.to eq :sysvinit }
    end # /context global override

    context 'per-service override for a different service' do
      service_provider('other', 'sysvinit')
      it { is_expected.to eq :systemd }
    end # /context global override for a different service

    context 'recipe DSL override' do
      recipe(subject: false) do
        poise_service 'test' do
          provider :sysvinit
        end
      end
      it { is_expected.to eq :sysvinit }
    end # /context recipe DSL override
  end # /describe provider lookup

  describe '#clean_stop_signal' do
    let(:signal) { }
    subject do
      described_class.new(nil, nil).tap {|r| r.stop_signal(signal) }.send(:clean_stop_signal)
    end

    context 'with a short string' do
      let(:signal) { 'term' }
      it { is_expected.to eq 'TERM' }
    end # /context with a short string

    context 'with a long string' do
      let(:signal) { 'sigterm' }
      it { is_expected.to eq 'TERM' }
    end # /context with a long string

    context 'with a short string in caps' do
      let(:signal) { 'TERM' }
      it { is_expected.to eq 'TERM' }
    end # /context with a short string in caps

    context 'with a long string in caps' do
      let(:signal) { 'SIGTERM' }
      it { is_expected.to eq 'TERM' }
    end # /context with a long string in caps

    context 'with a number' do
      let(:signal) { 15 }
      it { is_expected.to eq 'TERM' }
    end # /context with a number

    context 'with a symbol' do
      let(:signal) { :term }
      it { is_expected.to eq 'TERM' }
    end # /context with a symbol

    context 'with an invalid string' do
      let(:signal) { 'nope' }
      it { expect { subject }.to raise_error PoiseService::Error }
    end # /context with an invalid string

    context 'with an invalid number' do
      let(:signal) { 100 }
      it { expect { subject }.to raise_error PoiseService::Error }
    end # /context with an invalid number
  end # /describe #clean_stop_signal
end
