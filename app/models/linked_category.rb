# == Schema Information
#
# Table name: linked_categories
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  category_id        :bigint
#  linked_category_id :bigint
#
# Indexes
#
#  index_linked_categories_on_category_id_and_linked_category_id  (category_id,linked_category_id) UNIQUE
#  index_linked_categories_on_linked_category_id_and_category_id  (linked_category_id,category_id) UNIQUE
#
class LinkedCategory < ApplicationRecord
  belongs_to :linked_category, class_name: 'Category'
  belongs_to :category, class_name: 'Category'
end
