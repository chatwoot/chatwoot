# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Package do
  describe 'associations' do
    it { is_expected.to have_many(:account_packages).dependent(:destroy_async) }
    it { is_expected.to have_many(:accounts).through(:account_packages) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1).backed_by_column_of_type(:integer) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    describe 'limits' do
      Package::LIMIT_ATTRIBUTES.each do |limit_attribute|
        it { is_expected.to validate_numericality_of(limit_attribute).is_greater_than_or_equal_to(0).only_integer }
        it { is_expected.to allow_value(nil).for(limit_attribute) }
      end
    end
  end
end
