# == Schema Information
#
# Table name: passkeys
#
#  id           :bigint           not null, primary key
#  backed_up    :boolean          default(FALSE), not null
#  last_used_at :datetime
#  name         :string           not null
#  public_key   :text             not null
#  sign_count   :bigint           default(0), not null
#  transports   :jsonb            not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_passkeys_on_external_id  (external_id) UNIQUE
#  index_passkeys_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Passkey < ApplicationRecord
  MAX_PER_USER = 10

  belongs_to :user

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :name, presence: true, length: { maximum: 64 }
end
