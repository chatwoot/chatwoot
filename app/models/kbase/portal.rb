# == Schema Information
#
# Table name: kbase_portals
#
#  id                          :bigint           not null, primary key
#  bg_body_color               :string
#  bg_footer_color             :string
#  bg_header_color             :string
#  bg_helpcenter_color         :string
#  custom_domain               :string
#  favicon                     :string
#  form_input_focus_glow_color :string
#  form_primary_btn_color      :string
#  link_text_color             :string
#  link_text_hover_color       :string
#  linkback_url                :string
#  logo                        :string
#  name                        :string
#  phone                       :string
#  portal_base_color           :string
#  portal_base_font            :string
#  portal_heading_color        :string
#  portal_heading_font         :string
#  show_author                 :boolean
#  subdomain                   :string
#  tab_active_color            :string
#  tab_bg_color                :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  account_id                  :integer
#
class Kbase::Portal < ApplicationRecord
  belongs_to :account
  has_many :portal_categories
  has_many :categories, through: :portal_categories
  has_many :folders,  through: :categories
  has_many :articles, through: :folders

  validates :account_id, presence: true
  validates :name, presence: true
  validates :subdomain, presence: true
end
