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

describe PoiseService::OptionsResource do
  let(:default_attributes) do
    {'poise-service' => {provider: 'sysvinit', options: {}}}
  end

  describe '#_options' do
    context 'with simple options' do
      recipe do
        poise_service_options 'test' do
          foo 'bar'
          baz 42
        end
      end

      it { is_expected.to run_poise_service_options('test').with(_options: {'foo' => 'bar', 'baz' => 42}) }
    end # /context simple options

    context 'with node options' do
      recipe do
        poise_service_options 'test' do
          foo 'bar'
          baz node.name
        end
      end

      it { is_expected.to run_poise_service_options('test').with(_options: {'foo' => 'bar', 'baz' => 'chefspec.local'}) }
    end # /context with node options

    context 'with new_resource-based options' do
      resource(:poise_test) do
        def foo(val=nil)
          set_or_return(:foo, val, {})
        end
      end
      provider(:poise_test) do
        include Poise
        def action_run
          poise_service_options new_resource.name do
            foo new_resource.foo
          end
        end
      end
      recipe do
        poise_test 'test' do
          foo 'bar'
        end
      end

      it { is_expected.to run_poise_service_options('test').with(_options: {'foo' => 'bar'}) }
    end # /context with new_resource-based options
  end # /describe #_options

  describe 'provider options' do
    let(:service_options) do
      run_chef
      chef_run.find_resource(:poise_service, 'test').provider_for_action(:enable).options
    end

    context 'before service resource' do
      recipe do
        poise_service_options 'test' do
          position 'before'
        end

        poise_service 'test'
      end
      subject { service_options }

      it { is_expected.to eq({'position' => 'before'}) }
    end # /context before service resource

    context 'after service resource' do
      recipe do
        poise_service 'test'

        poise_service_options 'test' do
          position 'after'
        end
      end
      subject { service_options }

      it { is_expected.to eq({'position' => 'after'}) }
    end # /context after service resource

    context 'before service resource for a provider' do
      recipe do
        poise_service_options 'test' do
          for_provider :sysvinit
          position 'before'
        end

        poise_service 'test'
      end
      subject { service_options }

      it { expect { subject }.to raise_error }
    end # /context before service resource for a provider

    context 'after service resource for a provider' do
      recipe do
        poise_service 'test'

        poise_service_options 'test' do
          for_provider :sysvinit
          position 'after'
        end
      end
      subject { service_options }

      it { is_expected.to eq({'position' => 'after'}) }
    end # /context after service resource for a provider

    context 'after service resource for a non-matching provider' do
      recipe do
        poise_service 'test'

        poise_service_options 'test' do
          for_provider :upstart
          position 'after'
        end
      end
      subject { service_options }

      it { is_expected.to eq({}) }
    end # /context after service resource for a non-matching provider

    context 'mutiple options' do
      recipe do
        poise_service_options 'test1' do
          service_name 'test'
          position 'before'
          one 1
        end

        poise_service 'test'

        poise_service_options 'test2' do
          service_name 'test'
          for_provider :sysvinit
          two 2
        end

        poise_service_options 'test3' do
          service_name 'test'
          position 'after'
          three 3
        end

        poise_service_options 'test4' do
          service_name 'test'
          for_provider :upstart
          four 4
        end
      end
      subject { service_options }

      it { is_expected.to eq({'position' => 'before', 'one' => 1, 'two' => 2, 'three' => 3}) }
    end # /context mutiple options

    context 'using a service_name name' do
      recipe do
        poise_service 'test' do
          service_name 'longer'
        end

        poise_service_options 'longer' do
          kind 'service_name'
        end
      end
      subject { service_options }

      it { is_expected.to eq({'kind' => 'service_name'}) }
    end # /context using a service_name name
  end # /describe provider options
end
