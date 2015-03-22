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

require 'spec_helper'

describe PoiseService::Providers::Sysvinit do
  service_provider('sysvinit')
  step_into(:poise_service)
  before do
    allow_any_instance_of(described_class).to receive(:notifying_block) {|&block| block.call }
  end
  recipe do
    poise_service 'test' do
      command 'myapp --serve'
    end
  end

  context 'on Ubuntu' do
    let(:chefspec_options) { { platform: 'ubuntu', version: '14.04'} }

    it { is_expected.to render_file('/etc/init.d/test').with_content(<<-'EOH') }
  start-stop-daemon --start --quiet --background \
      --pidfile "/var/run/test.pid" --make-pidfile \
      --chuid "root" --chdir "/" \
      --exec "myapp" -- --serve
EOH

    context 'with an external PID file' do
      before do
        default_attributes['poise-service']['test'] ||= {}
        default_attributes['poise-service']['test']['pid_file'] = '/tmp/pid'
      end

      it { is_expected.to render_file('/etc/init.d/test').with_content(<<-'EOH') }
  start-stop-daemon --start --quiet --background \
      --pidfile "/tmp/pid" \
      --chuid "root" --chdir "/" \
      --exec "myapp" -- --serve
EOH
    end # /context with an external PID file
  end # /context on Ubuntu

  context 'on CentOS' do
    let(:chefspec_options) { { platform: 'centos', version: '7.0'} }

    it { is_expected.to render_file('/etc/init.d/test').with_content(<<-EOH) }
  ( cd "/" && daemon --user "root" --pidfile "/var/run/test.pid" "myapp --serve" >/dev/null 2>&1 ) &
  sleep 1 # Give it some time to start before checking for a pid
  _pid "myapp" > "/var/run/test.pid" || return 3
EOH

    context 'with an external PID file' do
      before do
        default_attributes['poise-service']['test'] ||= {}
        default_attributes['poise-service']['test']['pid_file'] = '/tmp/pid'
      end

      it { is_expected.to render_file('/etc/init.d/test').with_content(<<-EOH) }
  ( cd "/" && daemon --user "root" --pidfile "/tmp/pid" "myapp --serve" >/dev/null 2>&1 ) &
EOH
    end # /context with an external PID file
  end # /context on CentOS
end
