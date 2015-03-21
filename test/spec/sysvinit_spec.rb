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

  let(:chefspec_options) { { platform: 'ubuntu', version: '14.04'} }

  recipe do
    poise_service 'test' do
      command 'myapp --serve'
    end
  end

  it { is_expected.to render_file('/etc/init.d/test').with_content(<<-'EOH') }
  start-stop-daemon --start --quiet --background \
      --pidfile "/var/run/test.pid" --make-pidfile \
      --chuid "root" --chdir "/" \
      --exec "myapp" -- --serve
EOH
end
