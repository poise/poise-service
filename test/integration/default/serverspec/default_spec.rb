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

require 'json'
require 'net/http'
require 'uri'

require 'serverspec'
set :backend, :exec

shared_examples 'a poise_service_test' do |name, base_port, check_service=true|
  def json_http(uri)
    JSON.parse(Net::HTTP.get(URI(uri)))
  end

  describe 'default service' do
    describe service("poise_test_#{name}") do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end if check_service

    describe 'process environment' do
      subject { json_http("http://localhost:#{base_port}/") }
      it { is_expected.to include({
        'user' => 'root',
        'directory' => '/',
      }) }
    end
  end # /describe default service

  describe 'service with parameters' do
    describe service("poise_test_#{name}_params") do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end if check_service

    describe 'process environment' do
      subject { json_http("http://localhost:#{base_port+1}/") }
      it { is_expected.to include({
        'user' => 'poise',
        'directory' => '/tmp',
        'environment' => include({'POISE_ENV' => name}),
      }) }
    end
  end # /describe service with parameters

  describe 'noterm service' do
    describe service("poise_test_#{name}_noterm") do
      it { is_expected.to_not be_enabled }
      it { is_expected.to_not be_running }
    end if check_service

    describe 'process environment' do
      subject { json_http("http://localhost:#{base_port+2}/") }
      it { expect { subject }.to raise_error }
    end
  end # /describe noterm service

  describe 'restart service' do
    describe service("poise_test_#{name}_restart") do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end if check_service

    describe 'process environment' do
      subject { json_http("http://localhost:#{base_port+3}/") }
      it do
        is_expected.to include({
          'file_data' => 'second',
        })
      end
    end
  end # /describe restart service

  describe 'reload service' do
    describe service("poise_test_#{name}_reload") do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end if check_service

    describe 'process environment' do
      subject { json_http("http://localhost:#{base_port+4}/") }
      it do
        is_expected.to include({
          'file_data' => 'second',
        })
      end
    end
  end # /describe reload service
end

# CentOS 6 doesn't show upstart services in chkconfig, which is how specinfra
# checkes what is enabled.
old_upstart = os[:family] == 'redhat' && os[:release].start_with?('6')

describe 'default provider' do
  it_should_behave_like 'a poise_service_test', 'default', 5000, !old_upstart

  describe process('ruby /usr/bin/poise_test') do
    it { is_expected.to be_running }
  end
end

describe 'sysvinit provider', unless: File.exists?('/no_sysvinit') do
  it_should_behave_like 'a poise_service_test', 'sysvinit', 6000
end

describe 'upstart provider', unless: File.exists?('/no_upstart') do
  it_should_behave_like 'a poise_service_test', 'upstart', 7000, !old_upstart
end

describe 'systemd provider', unless: File.exists?('/no_systemd') do
  it_should_behave_like 'a poise_service_test', 'systemd', 8000
end

describe 'dummy provider' do
  it_should_behave_like 'a poise_service_test', 'dummy', 9000, false
end
