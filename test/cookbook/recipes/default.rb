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

require 'poise_service/resources/poise_service_test'

# Create the various services.
poise_service_test 'default' do
  base_port 5000
end

if node['platform_family'] == 'rhel' && node['platform_version'].start_with?('7') || \
   node['platform'] == 'ubuntu' && node['platform_version'].to_i >= 16
  file '/no_sysvinit'
  file '/no_upstart'
  file '/no_inittab'

  poise_service_test 'systemd' do
    service_provider :systemd
    base_port 8000
  end
else
  file '/no_systemd'

  poise_service_test 'sysvinit' do
    service_provider :sysvinit
    base_port 6000
  end

  if node['platform_family'] == 'rhel' && node['platform_version'].start_with?('5')
    file '/no_upstart'

    poise_service_test 'inittab' do
      service_provider :inittab
      base_port 10000
    end
  else
    file '/no_inittab'

    poise_service_test 'upstart' do
      service_provider :upstart
      base_port 7000
    end
  end
end

poise_service_test 'dummy' do
  service_provider :dummy
  base_port 9000
end

include_recipe 'poise-service_test::mixin'
