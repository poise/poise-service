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

require 'chef/node_map'
require 'chef/platform/provider_priority_map'

module PoiseService
  module Providers
    def self.provider_map
      @provider_map ||= Chef::NodeMap.new
    end

    def self.provider_for(node, name)
      provider_map.get(node, name.to_sym)
    end
  end
end

require 'poise_service/providers/systemd'
require 'poise_service/providers/sysvinit'
require 'poise_service/providers/upstart'

# Set up priority maps
Chef::Platform::ProviderPriorityMap.instance.priority(:poise_service, [
  PoiseService::Providers::Systemd,
  PoiseService::Providers::Upstart,
  PoiseService::Providers::Sysvinit,
])
