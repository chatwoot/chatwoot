# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlatformAppPermissible do
  let!(:platform_app_permissible) { create(:platform_app_permissible) }

  context 'with validations' do
    it { is_expected.to validate_presence_of(:platform_app) }
  end

  context 'with associations' do
    it { is_expected.to belong_to(:platform_app) }
    it { is_expected.to belong_to(:permissible) }
  end

  describe 'with factories' do
    it { expect(platform_app_permissible).present? }
  end
end
