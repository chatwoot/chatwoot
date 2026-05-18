module ChatwootKanban
  class Label < ApplicationRecord
    self.table_name = 'chatwoot_kanban_labels'

    belongs_to :account, class_name: '::Account'

    has_many :card_labels,
             class_name: 'ChatwootKanban::CardLabel',
             foreign_key: :label_id,
             dependent: :destroy,
             inverse_of: :label

    has_many :cards, through: :card_labels

    validates :name,  presence: true, length: { maximum: 60 },
                      uniqueness: { scope: :account_id, case_sensitive: false }
    validates :color, presence: true, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: 'must be a hex color' }
  end
end
