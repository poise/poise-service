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

require 'serverspec'
set :backend, :exec

describe service('poise_test') do
  # CentOS 6 doesn't show upstart services if chkconfig, which is how specinfra
  # checkes what is enabled.
  it { is_expected.to be_enabled } unless os[:family] == 'redhat' && os[:release].start_with?('6')
  it { is_expected.to be_running }
end

describe process('ruby /usr/bin/poise_test') do
  it { is_expected.to be_running }
end
