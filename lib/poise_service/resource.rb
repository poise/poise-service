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
    attribute(:environment, kind_of: Hash, default: {}) # ADD TO SYSV AND UPSTART

    def options(service_type=nil, val=nil)
      if !val && service_type.is_a?(Hash)
        key = :options
        val = service_type
      else
        key = :"options_#{service_type}"
      end
      set_or_return(key, val, kind_of: Hash, default: Chef::Mash.new)
    end

    def provider(val=nil)
      if val && !val.is_a?(Class)
        service_provider = PoiseService::Providers.provider_for(node, val)
        Chef::Log.debug("#{self} Checking for poise-service provider for #{val}: #{service_provider && service_provider.name}")
        val = service_provider if service_provider
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
