# frozen_string_literal: true

# == Schema Information
#
# Table name: platform_apps
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'
require Rails.root.join 'spec/models/concerns/access_tokenable_shared.rb'

RSpec.describe PlatformApp do
  let(:platform_app) { create(:platform_app) }

  context 'with validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  context 'with associations' do
    it { is_expected.to have_many(:platform_app_permissibles) }
  end

  describe 'with concerns' do
    it_behaves_like 'access_tokenable'
  end

  describe 'with factories' do
    it { expect(platform_app).present? }
  end
end
