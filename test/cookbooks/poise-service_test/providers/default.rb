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

action :run do
  poise_service "poise_test_#{new_resource.name}" do
    provider new_resource.service_provider if new_resource.service_provider
    command "/usr/bin/poise_test #{new_resource.base_port}"
  end

  poise_service "poise_test_#{new_resource.name}_params" do
    provider new_resource.service_provider if new_resource.service_provider
    command "/usr/bin/poise_test #{new_resource.base_port + 1}"
    environment POISE_ENV: new_resource.name
    user 'poise'
  end

  poise_service "poise_test_#{new_resource.name}_noterm" do
    provider new_resource.service_provider if new_resource.service_provider
    action [:enable, :disable]
    command "/usr/bin/poise_test_noterm #{new_resource.base_port + 2}"
    stop_signal 'kill'
  end

  {'restart' => 3, 'reload' => 4}.each do |action, port|
    # Stop it before writing the file so we always start with first.
    poise_service "poise_test_#{new_resource.name}_#{action} stop" do
      provider new_resource.service_provider if new_resource.service_provider
      action(:disable)
      service_name "poise_test_#{new_resource.name}_#{action}"
    end

    # Write the content to the read on service launch.
    file "/etc/poise_test_#{new_resource.name}_#{action}" do
      content 'first'
    end

    # Launch the service, reading in first.
    poise_service "poise_test_#{new_resource.name}_#{action}" do
      provider new_resource.service_provider if new_resource.service_provider
      command "/usr/bin/poise_test #{new_resource.base_port + port} /etc/poise_test_#{new_resource.name}_#{action}"
    end

    # Rewrite the file to second, restart/reload to trigger an update.
    file "/etc/poise_test_#{new_resource.name}_#{action} again" do
      path "/etc/poise_test_#{new_resource.name}_#{action}"
      content 'second'
      notifies action.to_sym, "poise_service[poise_test_#{new_resource.name}_#{action}]"
    end
  end
end
