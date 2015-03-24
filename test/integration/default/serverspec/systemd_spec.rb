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

describe 'systemd provider', unless: File.exists?('/no_systemd') do
  describe 'poise_test_systemd' do
    describe service('poise_test_systemd') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe 'process environment' do
      subject { json_http('http://localhost:8000/') }
      it { is_expected.to include({
        'user' => 'root',
        'directory' => '/',
      }) }
    end
  end # /describe poise_test_systemd

  describe 'poise_test_systemd2' do
    describe service('poise_test_systemd2') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe 'process environment' do
      subject { json_http('http://localhost:8001/') }
      it { is_expected.to include({
        'user' => 'poise',
        'directory' => '/tmp',
        'environment' => include({'POISE_ENV' => 'systemd'}),
      }) }
    end
  end # /describe poise_test_systemd2

  describe 'poise_test_systemd3' do
    describe service('poise_test_systemd3') do
      it { is_expected.to_not be_enabled }
      it { is_expected.to_not be_running }
    end

    describe 'process environment' do
      subject { json_http('http://localhost:8002/') }
      it { expect { subject }.to raise_error }
    end
  end # /describe poise_test_systemd3
end
