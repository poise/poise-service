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

require 'poise_service/providers/base'

module PoiseService
  module Providers
    class Systemd < Base
      poise_service_provides(:systemd)

      def self.provides_auto?(node, resource)
        # Don't allow systemd under docker, it won't work.
        return false if node['virtualization'] && %w{docker lxc}.include?(node['virtualization']['system'])
        service_resource_hints.include?(:systemd)
      end

      private

      def service_resource
        super.tap do |r|
          r.provider(Chef::Provider::Service::Systemd)
        end
      end

      def create_service
        service_template("/etc/systemd/system/#{new_resource.service_name}.service", 'systemd.service.erb')
      end

      def destroy_service
        file "/etc/systemd/system/#{new_resource.service_name}.service" do
          action :delete
        end
      end

    end
  end
end
