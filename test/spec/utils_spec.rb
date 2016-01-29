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

describe PoiseService::Utils do
  describe '#parse_service_name' do
    let(:path) { }
    subject { described_class.parse_service_name(path) }

    context 'with /home/myapp' do
      let(:path) { '/home/myapp' }
      it { is_expected.to eq 'myapp' }
    end # /context with /home/myapp

    context 'with /opt/myapp' do
      let(:path) { '/opt/myapp' }
      it { is_expected.to eq 'myapp' }
    end # /context with /opt/myapp

    context 'with /srv/myapp/current' do
      let(:path) { '/srv/myapp/current' }
      it { is_expected.to eq 'myapp' }
    end # /context with /srv/myapp/current

    context 'with /var/current' do
      let(:path) { '/var/current' }
      it { is_expected.to eq 'current' }
    end # /context with /var/current
  end # /describe #parse_service_name
end
