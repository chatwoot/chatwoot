# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseUser do
  context 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
  end

  context '#set_uid_to_email' do
    subject(:devise_user) { FactoryBot.build(:devise_user) }

    before { expect(devise_user.uid).to be_empty }
    it do
      devise_user.save!

      expect(devise_user.uid).to eq(devise_user.email)
    end
  end
end
