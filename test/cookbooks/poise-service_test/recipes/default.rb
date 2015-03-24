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

# Write out the scripts to run as services.
service_script = <<-EOH
require 'webrick'
require 'json'
require 'etc'
FILE_DATA = ''
def load_file
  FILE_DATA.replace(IO.read(ARGV[1]))
end
server = WEBrick::HTTPServer.new(Port: ARGV[0].to_i)
server.mount_proc '/' do |req, res|
  res.body = {
    directory: Dir.getwd,
    user: Etc.getpwuid(Process.uid).name,
    group: Etc.getgrgid(Process.gid).name,
    environment: ENV.to_hash,
    file_data: FILE_DATA,
    pid: Process.pid,
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
if ARGV[1]
  load_file
  trap('HUP') do
    load_file
  end
end
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

# Create the various services.
poise_service_user 'poise' do
  home '/tmp'
end

poise_service_test 'default' do
  base_port 5000
end

if node['platform_family'] == 'rhel' && node['platform_version'].start_with?('7')
  file '/no_sysvinit'
  file '/no_upstart'

  poise_service_test 'systemd' do
    service_provider :systemd
    base_port 8000
  end
else
  file '/no_systemd'

  poise_service_test 'sysvinit' do
    service_provider :sysvinit
    base_port 6000
  end

  poise_service_test 'upstart' do
    service_provider :upstart
    base_port 7000
  end
end

poise_service_test 'dummy' do
  service_provider :dummy
  base_port 9000
end
