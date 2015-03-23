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

include_recipe 'poise-service_test::_service'

if node['platform_family'] == 'rhel' && node['platform_version'].start_with?('7')
  file '/no_sysvinit'
  return
end

poise_service 'poise_test_sysvinit' do
  provider :sysvinit
  command '/usr/bin/poise_test 6000'
end

poise_service 'poise_test_sysvinit2' do
  provider :sysvinit
  command '/usr/bin/poise_test 6001'
  environment POISE_ENV: 'sysvinit'
  user 'poise'
end

poise_service 'poise_test_sysvinit3' do
  provider :sysvinit
  action [:enable, :disable]
  command '/usr/bin/poise_test_noterm 6002'
  stop_signal 'kill'
end

