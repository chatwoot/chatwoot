# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseUser do
  context 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
