# == Schema Information
#
# Table name: user_pinned_labels
#
#  id         :bigint           not null, primary key
#  position   :integer          default(0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  label_id   :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_pinned_labels_on_label_id              (label_id)
#  index_user_pinned_labels_on_user_id               (user_id)
#  index_user_pinned_labels_on_user_id_and_label_id  (user_id,label_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (label_id => labels.id)
#  fk_rails_...  (user_id => users.id)
#
class UserPinnedLabel < ApplicationRecord
  belongs_to :user
  belongs_to :label

  validates :user_id, uniqueness: { scope: :label_id }

  scope :ordered, -> { order(:position) }
end
