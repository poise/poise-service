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

describe PoiseService::Resources::PoiseService::Resource do
  service_provider('auto')
  service_resource_hints(%i{debian redhat upstart systemd})

  describe 'provider lookup' do
    recipe(subject: false) do
      poise_service 'test'
    end
    subject do
      chef_run.find_resource(:poise_service, 'test').provider_for_action(:enable).class.provides
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

  describe '#clean_signal' do
    let(:signal) { }
    subject do
      described_class.new(nil, nil).send(:clean_signal, signal)
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

  describe '#options' do
    subject { chef_run.find_resource('poise_service', 'test') }
    recipe(subject: false) do
      poise_service 'test' do
        options template: 'source.erb'
        options :sysvinit, template: 'override.erb'
      end
    end

    its(:options) { are_expected.to eq({'template' => 'source.erb'}) }
    it { expect(subject.options(:sysvinit)).to eq({'template' => 'override.erb'}) }
  end # /describe #options

  describe '#default_directory' do
    let(:user) { 'root' }
    subject do
      described_class.new('test', chef_run.run_context).tap {|r| r.user(user) }.send(:default_directory)
    end

    context 'with root' do
      context 'on Linux' do
        let(:chefspec_options) { {platform: 'ubuntu', version: '14.04'} }
        it { is_expected.to eq '/' }
      end # /context 'on Linux

      context 'on Windows' do
        let(:chefspec_options) { {platform: 'windows', version: '2012R2'} }
        before { allow(Poise::Utils::Win32).to receive(:admin_user).and_return('Administrator') } if defined?(Poise::Utils::Win32)
        it { is_expected.to eq 'C:\\' }
      end # /context on Windows
    end # /context with root

    context 'with a normal user' do
      let(:user) { 'poise' }
      before do
        expect(Dir).to receive(:home).with('poise').and_return('/home/poise')
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with('/home/poise').and_return(true)
      end

      it { is_expected.to eq '/home/poise' }
    end # /context with a normal user

    context 'with an invalid user' do
      let(:user) { 'poise' }
      before do
        expect(Dir).to receive(:home).with('poise').and_raise(ArgumentError)
      end

      it { is_expected.to eq '/' }
    end # /context with an invalid user

    context 'with a non-existent directory' do
      let(:user) { 'poise' }
      before do
        expect(Dir).to receive(:home).with('poise').and_return('/home/poise')
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with('/home/poise').and_return(false)
      end

      it { is_expected.to eq '/' }
    end # /context with a non-existent directory

    context 'with a blank directory' do
      let(:user) { 'poise' }
      before do
        expect(Dir).to receive(:home).with('poise').and_return('')
      end

      it { is_expected.to eq '/' }
    end # /context with a blank directory
  end # /describe #default_directory

  describe '#restart_on_update' do
    service_provider('sysvinit')
    step_into(:poise_service)
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/etc/init.d/test').and_return(true)
    end
    subject { chef_run.template('/etc/init.d/test') }

    context 'with true' do
      recipe(subject: false) do
        poise_service 'test' do
          command 'myapp --serve'
        end
      end
      it { is_expected.to notify('poise_service[test]').to(:restart) }
    end # /context with true

    context 'with false' do
      recipe(subject: false) do
        poise_service 'test' do
          command 'myapp --serve'
          restart_on_update false
        end
      end
      it { is_expected.to_not notify('poise_service[test]').to(:restart) }
    end # /context with false

    context 'with immediately' do
      recipe(subject: false) do
        poise_service 'test' do
          command 'myapp --serve'
          restart_on_update 'immediately'
        end
      end
      it { is_expected.to notify('poise_service[test]').to(:restart).immediately }
    end # /context with immediately

    context 'with :immediately' do
      recipe(subject: false) do
        poise_service 'test' do
          command 'myapp --serve'
          restart_on_update :immediately
        end
      end
      it { is_expected.to notify('poise_service[test]').to(:restart).immediately }
    end # /context with :immediately
  end # /describe #restart_on_update

  describe '#pid' do
    subject { described_class.new(nil, nil) }
    it do
      fake_pid = double('pid')
      expect(subject).to receive(:provider_for_action).with(:pid).and_return(double(pid: fake_pid))
      expect(subject.pid).to eq fake_pid
    end
  end # /describe #pid
end
