# == Schema Information
#
# Table name: folders
#
#  id          :bigint           not null, primary key
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :integer          not null
#  category_id :integer          not null
#
require 'rails_helper'

RSpec.describe Folder do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:category_id) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:category) }
    it { is_expected.to have_many(:articles) }
  end
end
