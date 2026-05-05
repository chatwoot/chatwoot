# == Schema Information
#
# Table name: notes
#
#  id            :bigint           not null, primary key
#  content       :text             not null
#  metadata      :jsonb            not null
#  source        :string           default("manual"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  contact_id    :bigint           not null
#  updated_by_id :bigint
#  user_id       :bigint
#
# Indexes
#
#  index_notes_on_account_id        (account_id)
#  index_notes_on_contact_id        (contact_id)
#  index_notes_on_contact_timeline  (contact_id,created_at,id)
#  index_notes_on_updated_by_id     (updated_by_id)
#  index_notes_on_user_id           (user_id)
#
class Note < ApplicationRecord
  SOURCES = %w[manual captain system].freeze

  before_validation :ensure_account_id
  before_validation :ensure_metadata
  before_validation :ensure_source

  validates :content, presence: true
  validates :account_id, presence: true
  validates :contact_id, presence: true
  validates :source, inclusion: { in: SOURCES }

  belongs_to :account
  belongs_to :contact
  belongs_to :user, optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  scope :latest, -> { order(created_at: :desc, id: :desc) }

  def created_by
    user
  end

  private

  def ensure_account_id
    self.account_id = contact&.account_id
  end

  def ensure_metadata
    self.metadata = {} unless metadata.is_a?(Hash)
  end

  def ensure_source
    self.source = 'manual' if source.blank?
  end
end
