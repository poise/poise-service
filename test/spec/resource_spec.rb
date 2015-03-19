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
    let(:resolved_provider) do
      run_chef
      chef_run.find_resource(:poise_service, 'test').provider_for_action(:enable).class.poise_service_provides
    end
    recipe do
      poise_service 'test'
    end
    subject { resolved_provider }

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

    # context 'auto on systemd' do
    #   service_resource_hints(:systemd)
    #   it { is_expected.to eq :systemd }
    # end # /context auto on systemd

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
