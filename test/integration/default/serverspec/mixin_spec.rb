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

require 'net/http'
require 'uri'

require 'serverspec'
set :backend, :exec

describe 'poise_service_test_mixin' do
  let(:port) { }
  let(:url) { "http://localhost:#{port}/" }
  subject { Net::HTTP.get(URI(url)) }

  describe 'default' do
    let(:port) { 4000 }
    it { is_expected.to eq 'Hello world!'}
  end

  describe 'update' do
    let(:port) { 4001 }
    it { is_expected.to eq 'second' }
  end
end
