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

if node['platform_family'] == 'rhel' && node['platform_version'].start_with?('7')
  file '/no_sysvinit'
  return
end

file '/usr/bin/poise_test_sysvinit' do
  owner 'root'
  group 'root'
  mode '744'
  content <<-EOH
#!/opt/chef/embedded/bin/ruby
sleep(1) while true
EOH
end

poise_service 'poise_test_sysvinit' do
  command '/usr/bin/poise_test_sysvinit'
  provider :sysvinit
end

poise_service 'poise_test_sysvinit2' do
  command '/usr/bin/poise_test_sysvinit'
  provider :sysvinit
  options :sysvinit, template: 'override.sh.erb'
end
