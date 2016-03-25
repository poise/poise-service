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

require 'spec_helper'

describe PoiseService::ServiceProviders::Systemd do
  service_provider('systemd')
  step_into(:poise_service)
  recipe do
    poise_service 'test' do
      command 'myapp --serve'
    end
  end

  it { is_expected.to render_file('/etc/systemd/system/test.service').with_content(<<-EOH) }
[Unit]
Description=test

[Service]
Environment=
ExecStart=myapp --serve
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=TERM
User=root
WorkingDirectory=/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOH

  context 'with action :disable' do
    recipe do
      poise_service 'test' do
        action :disable
      end
    end

    it { is_expected.to delete_file('/etc/systemd/system/test.service') }
  end # /context with action :disable

  describe '#pid' do
    context 'service is running' do
      before do
        fake_cmd = double('shellout', error?: false, live_stream: true, run_command: nil, stdout: <<-EOH)
test.service - test
   Loaded: loaded (/etc/systemd/system/test.service; enabled)
   Active: active (running) since Tue 2015-03-24 08:16:12 UTC; 15h ago
 Main PID: 10029 (myapp)
   CGroup: /system.slice/test.service
           └─10029 /opt/chef/embedded/bin/ruby /usr/bin/myapp --serve

Mar 24 08:16:12 hostname systemd[1]: Started test.
EOH
        expect(Mixlib::ShellOut).to receive(:new).with(%w{systemctl status test}, kind_of(Hash)).and_return(fake_cmd)
      end
      subject { described_class.new(double(service_name: 'test'), nil) }
      its(:pid) { is_expected.to eq 10029 }
    end # context service is running

    context 'service is stopped' do
      before do
        fake_cmd = double('shellout', error?: false, live_stream: true, run_command: nil, stdout: <<-EOH)
test.service - test
   Loaded: loaded (/etc/systemd/system/test.service; enabled)
   Active: inactive (dead) since Tue 2015-03-24 23:23:56 UTC; 4s ago
 Main PID: 10029 (code=killed, signal=TERM)

Mar 24 23:23:56 hostname systemd[1]: Stopping test...
EOH
        expect(Mixlib::ShellOut).to receive(:new).with(%w{systemctl status test}, kind_of(Hash)).and_return(fake_cmd)
      end
      subject { described_class.new(double(service_name: 'test'), nil) }
      its(:pid) { is_expected.to be_nil }
    end # context service is stopped

    context 'systemctl errors' do
      before do
        fake_cmd = double('shellout', error?: true, live_stream: true, run_command: nil)
        expect(Mixlib::ShellOut).to receive(:new).with(%w{systemctl status test}, kind_of(Hash)).and_return(fake_cmd)
      end
      subject { described_class.new(double(service_name: 'test'), nil) }
      its(:pid) { is_expected.to be_nil }
    end # context systemctl errors
  end # /describe #pid
end
