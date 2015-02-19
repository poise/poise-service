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
    class Sysvinit < Base
      provides_service(:sysvinit)

      private

      def service_resource
        super.tap do |r|
          r.provider(case node['platform_family']
          when 'debian'
            Chef::Provider::Service::Init::Debian
          when 'rhel'
            Chef::Provider::Service::Init::Redhat
          else
            # This will explode later in the template, but better than nothing for later
            Chef::Provider::Service::Init
          end)
        end
      end

      def create_service
        parts = new_resource.command.split(/ /, 2)
        daemon = ENV['PATH'].split(/:/)
          .map {|path| ::File.absolute_path(parts[0], path) }
          .find {|path| ::File.exist?(path) } || parts[0]
        template "/etc/init.d/#{new_resource.service_name}" do
          owner 'root'
          group 'root'
          mode '755'
          if new_resource.service_config['template']
            parts = new_resource.service_config['template'].split(/:/, 2)
            cookbook parts[0]
            source parts[1]
            unless source && cookbook && !source.empty? && !cookbook.empty?
              raise Error.new("Template override #{new_resource.service_config['template']} for #{new_resource} is invalid. Use the format 'cookbookname:templatepath'.")
            end
          else
            source 'sysvinit.sh.erb'
            cookbook 'poise-service'
          end
          variables(
            platform_family: node['platform_family'],
            name: new_resource.service_name,
            daemon: daemon,
            daemon_options: parts[1].to_s,
            user: new_resource.user,
            pid_file: "/var/run/#{new_resource.service_name}.pid",
            working_dir: new_resource.directory,
          )
        end
      end
    end
  end
end
