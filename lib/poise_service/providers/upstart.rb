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
    class Upstart < Base
      provides_service(:upstart)

      private

      def service_resource
        super.tap do |r|
          r.provider(Chef::Provider::Service::Upstart)
        end
      end

      def create_service
        template "/etc/init/#{new_resource.service_name}.conf" do
          owner 'root'
          group 'root'
          mode '755'
          source 'upstart.conf.erb'
          cookbook 'poise-service'
          variables(
            name: new_resource.service_name,
            command: new_resource.command,
            user: new_resource.user,
            working_dir: new_resource.directory,
          )
        end
      end

    end
  end
end
