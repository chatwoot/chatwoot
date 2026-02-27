# frozen_string_literal: true

# == Schema Information
#
# Table name: platform_app_permissibles
#
#  id               :bigint           not null, primary key
#  permissible_type :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  permissible_id   :bigint           not null
#  platform_app_id  :bigint           not null
#
# Indexes
#
#  index_platform_app_permissibles_on_permissibles     (permissible_type,permissible_id)
#  index_platform_app_permissibles_on_platform_app_id  (platform_app_id)
#  unique_permissibles_index                           (platform_app_id,permissible_id,permissible_type) UNIQUE
#
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
