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

require 'poise_boiler/spec_helper'
require 'poise_service'


module PoiseServiceHelper
  def service_provider(name=nil, provider, &block)
    provider ||= block.call if block
    before do
      override_attributes['poise-service'] ||= {}
      if name
        override_attributes['poise-service'][name] ||= {}
        override_attributes['poise-service'][name]['provider'] = provider
      else
        override_attributes['poise-service']['provider'] = provider
      end
    end
  end

  def service_resource_hints(hints, &block)
    hints ||= block.call if block
    before do
      begin
        PoiseService::ServiceProviders::Base.remove_class_variable(:@@service_resource_hints)
      rescue NameError
        # This space left intentionally blank.
      end
      allow(Chef::Platform::ServiceHelpers).to receive(:service_resource_providers).and_return(Array(hints))
    end
  end
end

RSpec.configure do |config|
  config.extend PoiseServiceHelper
end
