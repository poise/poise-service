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

require 'chef/resource'
require 'chef/provider'
require 'poise'


module PoiseService
  # (see OptionsResource::Resource)
  module OptionsResource
    # A `poise_service_options` resource to set per-service options in the Chef
    # recipe DSL.
    #
    # @since 1.0.0
    # @example
    #   poise_service_options 'myapp' do
    #     external_pid_file true
    #     stop_signal :kill
    #   end
    class Resource < Chef::Resource
      include Poise
      provides(:poise_service_options)
      actions(:run)

      attribute(:service_name, kind_of: String, name_attribute: true)
      attribute(:for_provider, kind_of: [String, Symbol])
      attribute(:_options, kind_of: Hash, default: lazy { Mash.new })

      def method_missing(*args, &block)
        super(*args, &block)
      rescue NoMethodError
        key, val = args
        val ||= block
        _options[key] = val
      end

      def after_created
        res = run_context.resource_collection.find(poise_service: service_name)
        res.options(for_provider).update(_options)
      rescue Chef::Exceptions::ResourceNotFound
        raise "Cannot set per-provider options for poise_service[#{service_name}] before the resource is defined." if for_provider
        node.force_override['poise-service'][service_name] = _options
      end
    end

    # Provider for `poise_service_options`.
    #
    # @see Resource
    class Provider < Chef::Provider
      include Poise
      provides(:poise_service_options)

      def action_run
        # This space left intentionally blank.
      end
    end
  end
end
