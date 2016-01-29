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

require 'poise_service/service_mixin'

include PoiseService::ServiceMixin

def action_enable
  notifying_block do
    file "/usr/bin/poise_mixin_#{new_resource.service_name}" do
      owner 'root'
      group 'root'
      mode '755'
      content <<-EOH
#!/opt/chef/embedded/bin/ruby
require 'webrick'
server = WEBrick::HTTPServer.new(Port: #{new_resource.port})
server.mount_proc '/' do |req, res|
  res.body = #{new_resource.message.inspect}
end
server.start
EOH
    end
  end
  super
end

def service_options(resource)
  resource.command("/usr/bin/poise_mixin_#{new_resource.service_name}")
end
