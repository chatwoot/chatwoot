# == Schema Information
#
# Table name: related_categories
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  category_id         :bigint
#  related_category_id :bigint
#
# Indexes
#
#  index_related_categories_on_category_id_and_related_category_id  (category_id,related_category_id) UNIQUE
#  index_related_categories_on_related_category_id_and_category_id  (related_category_id,category_id) UNIQUE
#
require 'rails_helper'

RSpec.describe RelatedCategory do
  describe 'associations' do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:related_category) }
  end
end
