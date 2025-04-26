# == Schema Information
#
# Table name: facebook_comment_configs
#
#  id                    :bigint           not null, primary key
#  account_id            :bigint           not null
#  inbox_id              :bigint           not null
#  webhook_url           :string           not null
#  status                :integer          default(0)
#  additional_attributes :jsonb            default({})
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_facebook_comment_configs_on_account_id_and_inbox_id  (account_id,inbox_id) UNIQUE
#

class FacebookCommentConfig < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  
  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :webhook_url, presence: true, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])
  
  # Các trạng thái: active, inactive
  enum status: { active: 0, inactive: 1 }
  
  def webhook_secret
    additional_attributes['webhook_secret']
  end
  
  def webhook_secret=(value)
    self.additional_attributes = additional_attributes.merge('webhook_secret' => value)
  end
end
