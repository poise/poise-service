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
  let(:service_provider) { 'auto' }
  let(:service_resource_providers) { %i{debian redhat upstart systemd} }
  let(:default_attributes) do
    {'poise-service' => {provider: service_provider}}
  end
  before do
    PoiseService::Providers::Base.remove_class_variable(:@@service_resource_hints) rescue nil
    allow(Chef::Platform::ServiceHelpers).to receive(:service_resource_providers).and_return(service_resource_providers)
  end

  describe 'provider lookup' do
    let(:resolved_provider) do
      run_chef
      chef_run.find_resource(:poise_service, 'test').provider_for_action(:enable).class.poise_service_provides
    end
    recipe do
      poise_service 'test'
    end
    subject { resolved_provider }

    context 'auto on debian' do
      let(:service_resource_providers) { %i{debian} }
      it { is_expected.to eq :sysvinit }
    end # /context auto on debian

    context 'auto on redhat' do
      let(:service_resource_providers) { %i{redhat} }
      it { is_expected.to eq :sysvinit }
    end # /context auto on redhat

    context 'auto on upstart' do
      let(:service_resource_providers) { %i{upstart} }
      it { is_expected.to eq :upstart }
    end # /context auto on upstart

    # context 'auto on systemd' do
    #   let(:service_resource_providers) { %i{systemd} }
    #   it { is_expected.to eq :systemd }
    # end # /context auto on systemd

    context 'auto on multiple systems' do
      let(:service_resource_providers) { %i{debian invokerd upstart} }
      it { is_expected.to eq :upstart }
    end # /context auto on multiple systems

    context 'global override' do
      let(:service_provider) { 'sysvinit' }
      it { is_expected.to eq :sysvinit }
    end # /context global override

    context 'per-service override' do
      before { default_attributes['poise-service']['test'] = {'provider' => 'sysvinit'} }
      it { is_expected.to eq :sysvinit }
    end # /context global override

    context 'per-service override for a different service' do
      before { default_attributes['poise-service']['other'] = {'provider' => 'sysvinit'} }
      it { is_expected.to eq :upstart }
    end # /context global override for a different service

    context 'recipe DSL override' do
      recipe do
        poise_service 'test' do
          provider :sysvinit
        end
      end
      subject { resolved_provider }
      it { is_expected.to eq :sysvinit }
    end # /context recipe DSL override
  end # /describe provider lookup
end
