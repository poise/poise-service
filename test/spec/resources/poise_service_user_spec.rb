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

describe PoiseService::Resources::PoiseServiceUser do
  step_into(:poise_service_user)
  # We need a platform because Chef no longer maps the user resource for chefspec.
  # https://github.com/chef/chef/issues/5242
  let(:chefspec_options) { {platform: 'ubuntu', version: '14.04'} }
  let(:shells) { [] }
  before do
    allow(File).to receive(:exist?).and_call_original
    described_class::DEFAULT_SHELLS.each do |shell|
      allow(File).to receive(:exist?).with(shell).and_return(shells.include?(shell))
    end
  end
  recipe do
    poise_service_user 'poise'
  end

  it { is_expected.to create_group('poise').with(gid: nil, system: true) }
  it { is_expected.to create_user('poise').with(gid: 'poise', home: nil, system: true, uid: nil, shell: '/bin/false') }

  context 'with an explicit user and group name' do
    recipe do
      poise_service_user 'poise' do
        user 'poise_user'
        group 'poise_group'
      end
    end

    it { is_expected.to create_group('poise_group').with(gid: nil, system: true) }
    it { is_expected.to create_user('poise_user').with(gid: 'poise_group', home: nil, system: true, uid: nil, shell: '/bin/false') }
  end # /context with an explicit user and group name

  context 'with no group' do
    recipe do
      poise_service_user 'poise' do
        group false
      end
    end

    it { is_expected.to_not create_group('poise') }
    it { is_expected.to create_user('poise').with(gid: nil, home: nil, system: true, uid: nil, shell: '/bin/false') }
  end # /context with no group

  context 'with explicit uid' do
    recipe do
      poise_service_user 'poise' do
        uid 100
      end
    end

    it { is_expected.to create_group('poise').with(gid: nil, system: true) }
    it { is_expected.to create_user('poise').with(gid: 'poise', home: nil, system: true, uid: 100, shell: '/bin/false') }
  end # /context with explicit uid

  context 'with explicit gid' do
    recipe do
      poise_service_user 'poise' do
        gid 100
      end
    end

    it { is_expected.to create_group('poise').with(gid: 100, system: true) }
    it { is_expected.to create_user('poise').with(gid: 'poise', home: nil, system: true, uid: nil, shell: '/bin/false') }
  end # /context with explicit gid

  context 'with home directory' do
    recipe do
      poise_service_user 'poise' do
        home '/home/poise'
      end
    end

    it { is_expected.to create_group('poise').with(gid: nil, system: true) }
    it { is_expected.to create_user('poise').with(gid: 'poise', home: '/home/poise', system: true, uid: nil, shell: '/bin/false') }
  end # /context with home directory

  context 'with shell' do
    recipe do
      poise_service_user 'poise' do
        shell '/bin/bash'
      end
    end

    it { is_expected.to create_group('poise').with(gid: nil, system: true) }
    it { is_expected.to create_user('poise').with(gid: 'poise', home: nil, system: true, uid: nil, shell: '/bin/bash') }
  end # /context with shell

  context 'with /bin/nologin existing' do
    let(:shells) { %w{/bin/nologin} }
    recipe do
      poise_service_user 'poise'
    end

    it { is_expected.to create_user('poise').with(shell: '/bin/nologin') }
  end # /context with /bin/nologin existing

  context 'with action :remove' do
    recipe do
      poise_service_user 'poise' do
        action :remove
      end
    end

    it { is_expected.to remove_group('poise') }
    it { is_expected.to remove_user('poise') }

    context 'with an explicit user and group name' do
      recipe do
        poise_service_user 'poise' do
          action :remove
          user 'poise_user'
          group 'poise_group'
        end
      end

      it { is_expected.to remove_group('poise_group') }
      it { is_expected.to remove_user('poise_user') }
    end # /context with an explicit user and group name

    context 'with no group' do
      recipe do
        poise_service_user 'poise' do
          action :remove
          group false
        end
      end

      it { is_expected.to_not remove_group('poise') }
      it { is_expected.to remove_user('poise') }
    end # /context with no group
  end # context with action :remove

  context 'on Solaris' do
    let(:chefspec_options) { {platform: 'solaris2', version: '5.11'} }

    it { is_expected.to create_group('poise').with(gid: nil, system: nil) }
    it { is_expected.to create_user('poise').with(gid: 'poise', home: nil, system: false, uid: nil, shell: '/bin/false') }
  end # /context on Solaris

  context 'on Windows' do
    let(:chefspec_options) { {platform: 'windows', version: '2012R2'} }

    it { is_expected.to_not create_group('poise') }
    it { is_expected.to create_user('poise').with(gid: nil, home: nil, system: true, uid: nil, shell: '/bin/false') }
  end # /context on Windows

end
