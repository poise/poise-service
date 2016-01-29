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

describe PoiseService::ServiceProviders::Dummy do
  service_provider('dummy')
  step_into(:poise_service)
  before do
    allow(Process).to receive(:fork).and_return(0)
    allow(Process).to receive(:kill).with(0, 100)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/var/run/test.pid').and_return(true)
    allow(IO).to receive(:read).and_call_original
    allow(IO).to receive(:read).with('/var/run/test.pid').and_return('100')
  end

  describe '#action_enable' do
    before do
      allow(File).to receive(:exist?).with('/var/run/test.pid').and_return(false, false, false, true)
      expect_any_instance_of(described_class).to receive(:sleep).with(1).once
    end
    recipe do
      poise_service 'test' do
        command 'myapp --serve'
      end
    end

    it { run_chef }
  end # /describe #action_enable

  describe '#action_disable' do
    before do
      expect(Process).to receive(:kill).with('TERM', 100)
      allow(File).to receive(:unlink).and_call_original
      allow(File).to receive(:unlink).with('/var/run/test.pid')
    end
    recipe do
      poise_service 'test' do
        action :disable
      end
    end

    it { run_chef }
  end # /describe #action_disable

  describe '#action_restart' do
    before do
      expect_any_instance_of(described_class).to receive(:action_start)
      expect_any_instance_of(described_class).to receive(:action_stop)
    end
    recipe do
      poise_service 'test' do
        action :restart
      end
    end

    it { run_chef }
  end # /describe #action_restart

  describe '#action_reload' do
    before do
      expect(Process).to receive(:kill).with('HUP', 100)
    end
    recipe do
      poise_service 'test' do
        action :reload
      end
    end

    it { run_chef }
  end # /describe #action_reload

  describe '#service_resource' do
    subject { described_class.new(nil, nil).send(:service_resource) }
    it { expect { subject }.to raise_error NotImplementedError }
  end # /describe #service_resource
end
