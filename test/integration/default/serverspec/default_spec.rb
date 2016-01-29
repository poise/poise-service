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

require 'poise_service/spec_helper'

# CentOS 6 doesn't show upstart services in chkconfig, which is how specinfra
# checkes what is enabled.
old_upstart = os[:family] == 'redhat' && os[:release].start_with?('6')

describe 'default provider' do
  it_should_behave_like 'a poise_service_test', 'default', 5000, !old_upstart

  describe process('ruby /usr/bin/poise_test') do
    it { is_expected.to be_running }
  end
end

describe 'sysvinit provider', unless: File.exist?('/no_sysvinit') do
  it_should_behave_like 'a poise_service_test', 'sysvinit', 6000
end

describe 'upstart provider', unless: File.exist?('/no_upstart') do
  it_should_behave_like 'a poise_service_test', 'upstart', 7000, !old_upstart
end

describe 'systemd provider', unless: File.exist?('/no_systemd') do
  it_should_behave_like 'a poise_service_test', 'systemd', 8000
end

describe 'dummy provider' do
  it_should_behave_like 'a poise_service_test', 'dummy', 9000, false
end

describe 'inittab provider', unless: File.exist?('/no_inittab') do
  it_should_behave_like 'a poise_service_test', 'inittab', 10000, false
end
