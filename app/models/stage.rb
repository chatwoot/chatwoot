# == Schema Information
#
# Table name: stages
#
#  id             :bigint           not null, primary key
#  allow_disabled :boolean          default(FALSE), not null
#  code           :string           not null
#  description    :string
#  disabled       :boolean          default(FALSE), not null
#  name           :string           not null
#  stage_type     :integer          not null
#  status         :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :integer          not null
#
# Indexes
#
#  index_stages_on_account_id_and_code  (account_id,code) UNIQUE
#
class Stage < ApplicationRecord
  belongs_to :account
  has_many :contacts, dependent: :nullify
  validates :account_id, presence: true
  validates :stage_type, presence: true
  validates :code, presence: true
  validates :name, presence: true
  validates :status, presence: true
  enum stage_type: { leads: 0, deals: 1, both: 2 }
  enum status: { ongoing: 0, ended: 1 }

  STAGE_TYPE_MAPPING = {
    'leads' => 0,
    'deals' => 1,
    'both' => 2
  }.freeze
end
