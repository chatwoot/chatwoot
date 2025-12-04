# == Schema Information
#
# Table name: global_email_templates
#
#  id            :bigint           not null, primary key
#  description   :text
#  friendly_name :string           not null
#  html          :text             not null
#  name          :string           not null
#  template_type :integer          default("content"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_global_email_templates_on_name           (name) UNIQUE
#  index_global_email_templates_on_template_type  (template_type)
#
class GlobalEmailTemplate < ApplicationRecord
  enum template_type: { layout: 0, content: 1 }

  validates :name, presence: true, uniqueness: true
  validates :friendly_name, presence: true
  validates :template_type, presence: true
  validates :html, presence: true
end
