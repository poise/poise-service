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
  # (see UserResource::Resource)
  module UserResource
    # A `poise_service_user` resource to create service users/groups.
    #
    # @since 1.0.0
    # @example
    #   poise_service_user 'myapp' do
    #     home '/var/tmp'
    #     group 'nogroup'
    #   end
    class Resource < Chef::Resource
      include Poise
      provides(:poise_service_user)
      actions(:create, :remove)

      attribute(:user, kind_of: String, name_attribute: true)
      attribute(:group, kind_of: [String, FalseClass], name_attribute: true)
      attribute(:uid, kind_of: Integer)
      attribute(:gid, kind_of: Integer)
      attribute(:home, kind_of: String)
    end

    # Provider for `poise_service_user`.
    #
    # @see Resource
    class Provider < Chef::Provider
      include Poise
      provides(:poise_service_user)

      def action_create
        notifying_block do
          create_group if new_resource.group
          create_user
        end
      end

      def action_remove
        notifying_block do
          remove_user
          remove_group if new_resource.group
        end
      end

      private

      def create_group
        group new_resource.group do
          gid new_resource.gid
          system true
        end
      end

      def create_user
        user new_resource.user do
          comment "Service user for #{new_resource.name}"
          gid new_resource.group if new_resource.group
          home new_resource.home
          shell '/bin/false'
          system true
          uid new_resource.uid
        end
      end

      def remove_group
        create_group.tap do |r|
          r.action(:remove)
        end
      end

      def remove_user
        create_user.tap do |r|
          r.action(:remove)
        end
      end
    end
  end
end
