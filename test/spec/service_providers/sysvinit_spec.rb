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

describe PoiseService::ServiceProviders::Sysvinit do
  service_provider('sysvinit')
  step_into(:poise_service)
  let(:test_provider) { chef_run.poise_service('test').provider_for_action(:enable) }
  let(:service_provider) { test_provider.send(:service_resource).provider_for_action(:enable) }
  recipe do
    poise_service 'test' do
      command 'myapp --serve'
    end
  end

  context 'on Ubuntu' do
    let(:chefspec_options) { { platform: 'ubuntu', version: '14.04'} }

    it { expect(service_provider).to be_a Chef::Provider::Service::Debian }
    it { is_expected.to render_file('/etc/init.d/test').with_content(<<-EOH) }
  start-stop-daemon --start --quiet --background \\
      --pidfile "/var/run/test.pid" --make-pidfile \\
      --chuid "root" --chdir "/" \\
      --exec "myapp" -- --serve
EOH

    context 'with an external PID file' do
      before do
        override_attributes['poise-service']['test'] ||= {}
        override_attributes['poise-service']['test']['pid_file'] = '/tmp/pid'
      end

      it { is_expected.to render_file('/etc/init.d/test').with_content(<<-EOH) }
  start-stop-daemon --start --quiet --background \\
      --pidfile "/tmp/pid" \\
      --chuid "root" --chdir "/" \\
      --exec "myapp" -- --serve
EOH
    end # /context with an external PID file


    context 'with a non-default internal PID file' do
      before do
        override_attributes['poise-service']['test'] ||= {}
        override_attributes['poise-service']['test']['pid_file'] = '/tmp/pid'
        override_attributes['poise-service']['test']['pid_file_external'] = false
      end

      it { is_expected.to render_file('/etc/init.d/test').with_content(<<-EOH) }
  start-stop-daemon --start --quiet --background \\
      --pidfile "/tmp/pid" --make-pidfile \\
      --chuid "root" --chdir "/" \\
      --exec "myapp" -- --serve
EOH
    end # /context with a non-default internal PID file
  end # /context on Ubuntu

  context 'on CentOS' do
    let(:chefspec_options) { { platform: 'centos', version: '7.0'} }

    it { expect(service_provider).to be_a Chef::Provider::Service::Redhat }
    it { is_expected.to render_file('/etc/init.d/test').with_content(<<-EOH) }
  Dir.chdir("/")
  IO.write(pid_file, Process.pid)
  ent = Etc.getpwnam("root")
  if Process.euid != ent.uid || Process.egid != ent.gid
    Process.initgroups(ent.name, ent.gid)
    Process::GID.change_privilege(ent.gid) if Process.egid != ent.gid
    Process::UID.change_privilege(ent.uid) if Process.euid != ent.uid
  end
  Kernel.exec(*["myapp", "--serve"])
EOH

    context 'with an external PID file' do
      before do
        override_attributes['poise-service']['test'] ||= {}
        override_attributes['poise-service']['test']['pid_file'] = '/tmp/pid'
      end

      it { is_expected.to render_file('/etc/init.d/test').with_content(<<-EOH) }
  Dir.chdir("/")
  ent = Etc.getpwnam("root")
  if Process.euid != ent.uid || Process.egid != ent.gid
    Process.initgroups(ent.name, ent.gid)
    Process::GID.change_privilege(ent.gid) if Process.egid != ent.gid
    Process::UID.change_privilege(ent.uid) if Process.euid != ent.uid
  end
  Kernel.exec(*["myapp", "--serve"])
EOH
    end # /context with an external PID file

    context 'with a non-default internal PID file' do
      before do
        override_attributes['poise-service']['test'] ||= {}
        override_attributes['poise-service']['test']['pid_file'] = '/tmp/pid'
        override_attributes['poise-service']['test']['pid_file_external'] = false
      end

      it { is_expected.to render_file('/etc/init.d/test').with_content(<<-EOH) }
pid_file = "/tmp/pid"
File.unlink(pid_file) if File.exist?(pid_file)
if Process.fork
  sleep(1) until File.exist?(pid_file)
else
  Process.daemon(true)
  Dir.chdir("/")
  IO.write(pid_file, Process.pid)
  ent = Etc.getpwnam("root")
  if Process.euid != ent.uid || Process.egid != ent.gid
    Process.initgroups(ent.name, ent.gid)
    Process::GID.change_privilege(ent.gid) if Process.egid != ent.gid
    Process::UID.change_privilege(ent.uid) if Process.euid != ent.uid
  end
  Kernel.exec(*["myapp", "--serve"])
EOH
    end # /context with a non-default internal PID file
  end # /context on CentOS

  context 'on Debian' do
    let(:chefspec_options) { { platform: 'debian', version: '8.7'} }
    it { expect(service_provider).to be_a Chef::Provider::Service::Debian }
  end # /context on Debian

  context 'on Amazon Linux' do
    let(:chefspec_options) { { platform: 'amazon', version: '2016.09'} }
    it { expect(service_provider).to be_a Chef::Provider::Service::Redhat }
  end # /context on Amazon Linux

  context 'with action :disable' do
    recipe do
      poise_service 'test' do
        action :disable
      end
    end

    it { is_expected.to delete_file('/etc/init.d/test') }
    it { is_expected.to delete_file('/var/run/test.pid') }
  end # /context with action :disable

  describe '#pid' do
    subject { described_class.new(nil, nil) }
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/pid').and_return(true)
      allow(IO).to receive(:read).and_call_original
      allow(IO).to receive(:read).with('/pid').and_return('100')
      expect(subject).to receive(:pid_file).and_return('/pid').at_least(:once)
    end
    its(:pid) { is_expected.to eq 100 }
  end # /describe #pid
end
