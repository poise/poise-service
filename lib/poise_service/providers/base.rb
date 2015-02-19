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

      def self.provides_service(name, opts={}, &block)
        PoiseService::Providers.provider_map.set(name.to_sym, self, opts, &block)
      end

      def action_enable
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

      def service_resource
        @service_resource ||= Chef::Resource::Service.new(new_resource.service_name, run_context).tap do |r|
          r.supports(status: true, restart: true)
        end
      end

    end
  end
end
