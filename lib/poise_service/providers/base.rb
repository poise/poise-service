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

require 'chef/provider'
require 'poise'


module PoiseService
  module Providers
    class Base < Chef::Provider
      include Poise

      # Poise-service version of provides() to set the name and register with the map.
      def self.poise_service_provides(val=nil, opts={}, &block)
        if val
          @poise_service_provider = val
          PoiseService::Providers.provider_map.set(val.to_sym, self, opts, &block)
        end
        @poise_service_provider
      end

      def self.provides?(node, resource)
        return false unless resource.resource_name == :poise_service
        provider_name = (node['poise-service'][resource.name] && node['poise-service'][resource.name]['provider']) || node['poise-service']['provider']
        provider_name == poise_service_provides.to_s || ( provider_name == 'auto' && provides_auto?(node, resource) )
      end

      # Subclass hook to provide auto-detection for service providers.
      #
      # @param node [Chef::Node] Node to check against.
      # @param resource [Chef::Resource] Resource to check against.
      # @returns [Boolean]
      def self.provides_auto?(node, resource)
        false
      end

      # Cache this forever because it runs a dozen or so stats every time and I call it a lot.
      def self.service_resource_hints
        @@service_resource_hints ||= Chef::Platform::ServiceHelpers.service_resource_providers
      end

      # Helper for subclasses to compile the sources of service-level options.
      # Only used internally but has to be public for the scope-promotion in
      # Chef::Resource (enclosing_provider) to work correctly.
      #
      # @returns [Hash]
      def options
        @options ||= Mash.new.tap do |opts|
          opts.update(new_resource.options)
          if node['poise-service']['options']
            opts.update(node['poise-service']['options'])
          end
          opts.update(new_resource.options(self.class.poise_service_provides))
          if node['poise-service'][new_resource.service_name]
            opts.update(node['poise-service'][new_resource.service_name])
          end
          if node['poise-service'][new_resource.name]
            opts.update(node['poise-service'][new_resource.name])
          end
        end
      end

      def action_enable
        include_recipe(*Array(recipes)) if recipes
        notifying_block do
          create_service
        end
        enable_service
        action_start
      end

      def action_disable
        action_stop
        disable_service
        notifying_block do
          destroy_service
        end
      end

      def action_start
        notify_if_service do
          service_resource.run_action(:start)
        end
      end

      def action_stop
        notify_if_service do
          service_resource.run_action(:stop)
        end
      end

      def action_restart
        notify_if_service do
          service_resource.run_action(:restart)
        end
      end

      def action_reload
        notify_if_service do
          service_resource.run_action(:reload)
        end
      end

      private

      # Recipes to include for this provider to work. Subclasses can override.
      #
      # @return [String, Array]
      def recipes
      end

      # Subclass hook to create the required files et al for the service.
      def create_service
        raise NotImplementedError
      end

      # Subclass hook to remove the required files et al for the service.
      def destroy_service
        raise NotImplementedError
      end

      def enable_service
        notify_if_service do
          service_resource.run_action(:enable)
        end
      end

      def disable_service
        notify_if_service do
          service_resource.run_action(:disable)
        end
      end

      def notify_if_service(&block)
        service_resource.updated_by_last_action(false)
        block.call
        new_resource.updated_by_last_action(true) if service_resource.updated_by_last_action?
      end

      # Subclass hook to create the resource used to delegate start, stop, and
      # restart actions.
      def service_resource
        @service_resource ||= Chef::Resource::Service.new(new_resource.service_name, run_context).tap do |r|
          r.supports(status: true, restart: true)
        end
      end

      def service_template(path, default_source, &block)
        template path do
          owner 'root'
          group 'root'
          mode '644'
          if options['template']
            # If we have a template override, allow specifying a cookbook via
            # "cookbook:template".
            parts = options['template'].split(/:/, 2)
            if parts.length == 2
              source parts[1]
              cookbook parts[0]
            else
              source parts.first
              cookbook new_resource.cookbook_name.to_s
            end
          else
            source default_source
            cookbook 'poise-service'
          end
          variables(
            command: new_resource.command,
            directory: new_resource.directory,
            environment: new_resource.environment,
            name: new_resource.service_name,
            new_resource: new_resource,
            options: options,
            stop_signal: new_resource.stop_signal,
            user: new_resource.user,
          )
          instance_exec(&block) if block
        end
      end

    end
  end
end
