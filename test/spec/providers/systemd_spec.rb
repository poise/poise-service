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

describe PoiseService::Providers::Systemd do
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
KillSignal=TERM
User=root
WorkingDirectory=/

[Install]
WantedBy=multi-user.target
EOH
end
