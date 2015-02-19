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

require 'etc'

require 'chef/resource'
require 'poise'

require 'poise_service/error'


module PoiseService
  class Resource < Chef::Resource
    include Poise
    provides(:poise_service)
    actions(:enable, :disable, :start, :stop, :restart)

    attribute(:service_name, kind_of: String, name_attribute: true)
    attribute(:command, kind_of: String, required: true)
    attribute(:user, kind_of: String, default: 'root')
    attribute(:directory, kind_of: String, default: lazy { _home_dir })

    def options(service_type, val=nil)
      set_or_return(:"options_#{service_type}", val, kind_of: Hash)
    end

    # Override configuration for this particular service
    #
    # @return [Hash]
    def service_config
      @service_config ||= node['poise-service'][service_name] || {}
    end

    def provider(val=nil)
      if val && !val.is_a?(Class)
        service_provider = PoiseService::Providers.provider_for(node, val)
        val = service_provider if service_provider
      end
      super
    end

    def provider_for_action(action)
      unless provider
        # Only do all this if a specific provider isn't given, but you should never do that ...
        provider_name = (node['poise-service'][service_name] && node['poise-service'][service_name]['provider']) || node['poise-service']['provider']
        if provider_name == 'auto'
          # Fire up the auto-detect logic.
          available = Chef::Platform::ServiceHelpers.service_resource_providers
          # Don't allow upstart under docker, it won't work.
          available.delete(:upstart) if node['virtualization'] && %w{docker lxc}.include?(node['virtualization']['system'])
          # These are in order of priority.
          {
            systemd: 'systemd',
            upstart: 'upstart',
            debian: 'sysvinit',
            redhat: 'sysvinit',
            invokercd: 'sysvinit',
          }.each do |check_for, possible_provider_name|
            if available.include?(check_for)
              provider_name = possible_provider_name
              break
            end
          end
          if provider_name == 'auto'
            # Still auto, detection failed
            raise Error.new("Unable to determine the correct service provider for #{service_name}, please set node['poise-service']['provider'].")
          end
        end

        provider(provider_name)
      end
      super
    end

    private

    # Try to find the homedir for the configured user. This will fail if
    # nsswitch.conf was changed during this run such as with LDAP.
    def _home_dir
      # Force a reload in case any users were created earlier in the run.
      Etc.endpwent
      home = begin
        Dir.home(user)
      rescue ArgumentError
        nil
      end
      # Better than nothing
      home || case node['platform_family']
      when 'windows'
        ENV.fetch('SystemRoot', 'C:\\')
      else
        '/'
      end
    end
  end
end
