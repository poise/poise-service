#
# Copyright 2015-2016, Noah Kantrowitz
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
  module Resources
    # (see PoiseServiceUser::Resource)
    # @since 1.0.0
    module PoiseServiceUser
      # Shells to look for in order.
      # @api private
      DEFAULT_SHELLS = %w{/bin/nologin /usr/bin/nologin /bin/false}

      # A `poise_service_user` resource to create service users/groups.
      #
      # @since 1.0.0
      # @provides poise_service_user
      # @action create
      # @action remove
      # @example
      #   poise_service_user 'myapp' do
      #     home '/var/tmp'
      #     group 'nogroup'
      #   end
      class Resource < Chef::Resource
        include Poise
        provides(:poise_service_user)
        actions(:create, :remove)

        # @!attribute user
        #   Name of the user to create. Defaults to the name of the resource.
        #   @return [String]
        attribute(:user, kind_of: String, name_attribute: true)
        # @!attribute group
        #   Name of the group to create. Defaults to the name of the user,
        #   except on Windows where it defaults to false. Set to false to
        #   disable group creation.
        #   @return [String, false]
        attribute(:group, kind_of: [String, FalseClass], default: lazy { default_group })
        # @!attribute uid
        #   UID of the user to create. Optional, if not set the UID will be
        #   allocated automatically.
        #   @return [Integer]
        attribute(:uid, kind_of: Integer)
        # @!attribute gid
        #   GID of the group to create. Optional, if not set the GID will be
        #   allocated automatically.
        #   @return [Integer]
        attribute(:gid, kind_of: Integer)
        # @!attribute shell
        #   Login shell for the user. Optional, if not set the shell will be
        #   determined automatically.
        #   @return [String]
        attribute(:shell, kind_of: String, default: lazy { default_shell })
        # @!attribute home
        #   Home directory of the user. This directory will not be created if it
        #   does not exist. Optional.
        #   @return [String]
        attribute(:home, kind_of: String)

        private

        # Find a default shell for service users. Tries to use nologin, but fall
        # back on false.
        #
        # @api private
        # @return [String]
        def default_shell
          DEFAULT_SHELLS.find {|s| ::File.exist?(s) } || DEFAULT_SHELLS.last
        end

        # Find the default group name. Returns false on Windows because service
        # groups aren't needed there. Otherwise use the name of the service user.
        #
        # @api private
        # @return [String, false]
        def default_group
          if node.platform_family?('windows')
            false
          else
            user
          end
        end
      end

      # Provider for `poise_service_user`.
      #
      # @since 1.0.0
      # @see Resource
      # @provides poise_service_user
      class Provider < Chef::Provider
        include Poise
        provides(:poise_service_user)

        # `create` action for `poise_service_user`. Ensure the user and group (if
        # enabled) exist.
        #
        # @return [void]
        def action_create
          notifying_block do
            create_group if new_resource.group
            create_user
          end
        end

        # `remove` action for `poise_service_user`. Ensure the user and group (if
        # enabled) are destroyed.
        #
        # @return [void]
        def action_remove
          notifying_block do
            remove_user
            remove_group if new_resource.group
          end
        end

        private

        # Create the system group.
        #
        # @api private
        # @return [void]
        def create_group
          group new_resource.group do
            gid new_resource.gid
            # Solaris doesn't support the idea of system groups.
            system true unless node.platform_family?('solaris2')
          end
        end

        # Create the system user.
        #
        # @api private
        # @return [void]
        def create_user
          user new_resource.user do
            comment "Service user for #{new_resource.name}"
            gid new_resource.group if new_resource.group
            home new_resource.home
            shell new_resource.shell
            # Solaris doesn't support the idea of system users.
            system true unless node.platform_family?('solaris2')
            uid new_resource.uid
          end
        end

        # Remove the system group.
        #
        # @api private
        # @return [void]
        def remove_group
          create_group.tap do |r|
            r.action(:remove)
          end
        end

        # Remove the system user.
        #
        # @api private
        # @return [void]
        def remove_user
          create_user.tap do |r|
            r.action(:remove)
          end
        end
      end
    end
  end
end
