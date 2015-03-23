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

service_script = <<-EOH
require 'webrick'
require 'json'
require 'etc'
server = WEBrick::HTTPServer.new(Port: ARGV[0] ? ARGV[0].to_i : 8000)
server.mount_proc '/' do |req, res|
  res.body = {
    directory: Dir.getwd,
    user: Etc.getpwuid(Process.uid).name,
    group: Etc.getgrgid(Process.gid).name,
    environment: ENV.to_hash,
  }.to_json
end
EOH

file '/usr/bin/poise_test' do
  owner 'root'
  group 'root'
  mode '755'
  content <<-EOH
#!/opt/chef/embedded/bin/ruby
#{service_script}
server.start
EOH
end

file '/usr/bin/poise_test_noterm' do
  owner 'root'
  group 'root'
  mode '755'
  content <<-EOH
#!/opt/chef/embedded/bin/ruby
trap('HUP', 'IGNORE')
trap('STOP', 'IGNORE')
trap('TERM', 'IGNORE')
#{service_script}
while true
  begin
    server.start
  rescue Exception
  rescue StandardError
  end
end
EOH
end

poise_service_user 'poise' do
  home '/tmp'
end
