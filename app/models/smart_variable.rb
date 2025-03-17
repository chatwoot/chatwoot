# == Schema Information
#
# Table name: smart_variables
#
#  id         :bigint           not null, primary key
#  data       :jsonb
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SmartVariable < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
