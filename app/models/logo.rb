# == Schema Information
#
# Table name: logos
#
#  id         :bigint           not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Logo < ApplicationRecord
  has_one_attached :avatar
end
