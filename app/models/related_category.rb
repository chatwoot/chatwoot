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
class RelatedCategory < ApplicationRecord
  belongs_to :related_category, class_name: 'Category'
  belongs_to :category, class_name: 'Category'
end
