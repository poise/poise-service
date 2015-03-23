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
  # `poise_service` resource. Provides a unified service interface with a
  # dependency injection framework.
  #
  # @since 1.0.0
  # @example
  #   poise_service 'myapp' do
  #     command 'myapp --serve'
  #     user 'myuser'
  #     directory '/home/myapp'
  #   end
  class Resource < Chef::Resource
    include Poise
    provides(:poise_service)
    actions(:enable, :disable, :start, :stop, :restart)

    attribute(:service_name, kind_of: String, name_attribute: true)
    attribute(:command, kind_of: String, required: true)
    attribute(:user, kind_of: String, default: 'root')
    attribute(:directory, kind_of: String, default: lazy { default_directory })
    attribute(:environment, kind_of: Hash, default: {})
    attribute(:stop_signal, kind_of: [String, Symbol, Integer], default: 'TERM')
    attribute(:reload_signal, kind_of: [String, Symbol, Integer], default: 'HUP')


    def options(service_type=nil, val=nil)
      key = :options
      if !val && service_type.is_a?(Hash)
        val = service_type
      elsif service_type
        key = :"options_#{service_type}"
      end
      set_or_return(key, val, kind_of: Hash, default: lazy { Mash.new })
    end

    # Allow setting the provider directly using the same names as the attribute
    # settings.
    #
    # @param val [String, Symbol, Class, nil] Value to set the provider to.
    # @return [Class]
    # @example
    #   poise_service 'myapp' do
    #     provider :sysvinit
    #   end
    def provider(val=nil)
      if val && !val.is_a?(Class)
        service_provider = PoiseService::Providers.provider_for(node, val)
        Chef::Log.debug("#{self} Checking for poise-service provider for #{val}: #{service_provider && service_provider.name}")
        val = service_provider if service_provider
      end
      super
    end

    # Resource DSL callback.
    #
    # @api private
    def after_created
      # Set signals to clean values.
      stop_signal(clean_signal(stop_signal))
      reload_signal(clean_signal(reload_signal))
    end

    private

    # Try to find the home diretory for the configured user. This will fail if
    # nsswitch.conf was changed during this run such as with LDAP. Defaults to
    # the system root directory.
    #
    # @see #directory
    # @return [String]
    def default_directory
      # For root we always want the system root path.
      unless user == 'root'
        # Force a reload in case any users were created earlier in the run.
        Etc.endpwent
        home = begin
          Dir.home(user)
        rescue ArgumentError
          nil
        end
      end
      # Better than nothing
      home || case node['platform_family']
      when 'windows'
        ENV.fetch('SystemRoot', 'C:\\')
      else
        '/'
      end
    end

    # Clean up a signal string/integer. Ints are mapped to the signal name,
    # and strings are reformatted to upper case and without the SIG.
    #
    # @see #stop_signal
    # @param signal [String, Symbol, Integer] Signal value to clean.
    # @return [String]
    def clean_signal(signal)
      if signal.is_a?(Integer)
        raise Error.new("Unknown signal #{signal}") unless (0..31).include?(signal)
        Signal.signame(signal)
      else
        short_sig = signal.to_s.upcase
        short_sig = short_sig[3..-1] if short_sig.start_with?('SIG')
        raise Error.new("Unknown signal #{signal}") unless Signal.list.include?(short_sig)
        short_sig
      end
    end
  end
end
