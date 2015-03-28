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

require 'halite/helper_base'


module PoiseService
  class SpecHelper < Halite::HelperBase
    def install
      # For the json_http helper below.
      require 'json'
      require 'net/http'
      require 'uri'

      # Load and configure Serverspec.
      require 'serverspec'
      set :backend, :exec

      # Set up the shared example for poise_service_test.
      RSpec.shared_examples 'a poise_service_test' do |name, base_port, check_service=true|
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

        describe 'pid file' do
          subject { IO.read("/tmp/poise_test_#{name}_pid") }
          it { is_expected.to match /\d+/ }
          its(:to_i) { is_expected.to eq json_http("http://localhost:#{base_port}/")['pid'] }
          it { Process.kill(0, subject.to_i) }
        end # /describe pid file
      end # /shared_examples a poise_service_test
    end # /def install
  end
end
