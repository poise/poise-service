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

# CentOS 6 doesn't show upstart services in chkconfig, which is how specinfra
# checkes what is enabled.
old_upstart = os[:family] == 'redhat' && os[:release].start_with?('6')

describe 'upstart provider', unless: File.exists?('/no_upstart') do
  describe 'poise_test_upstart' do
    describe service('poise_test_upstart') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end unless old_upstart

    describe process('ruby /usr/bin/poise_test_upstart') do
      it { is_expected.to be_running }
    end

    describe 'process environment' do
      subject { json_http('http://localhost:7000/') }
      it { is_expected.to include({
        'user' => 'root',
        'directory' => '/',
      }) }
    end
  end

  describe 'poise_test_upstart2' do
    describe service('poise_test_upstart2') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end unless old_upstart

    describe 'process environment' do
      subject { json_http('http://localhost:7001/') }
      it { is_expected.to include({
        'user' => 'poise',
        'directory' => '/tmp',
        'environment' => include({'POISE_ENV' => 'upstart'}),
      }) }
    end
  end # /describe poise_test_upstart2

  describe 'poise_test_upstart3' do
    describe service('poise_test_upstart3') do
      it { is_expected.to_not be_enabled }
      it { is_expected.to_not be_running }
    end
  end # /describe poise_test_upstart3
end
