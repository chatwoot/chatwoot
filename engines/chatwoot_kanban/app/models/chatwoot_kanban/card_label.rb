module ChatwootKanban
  # Join model so we can record timestamps on label assignment (useful for "labeled at" sort).
  class CardLabel < ApplicationRecord
    self.table_name = 'chatwoot_kanban_card_labels'

    belongs_to :card,  class_name: 'ChatwootKanban::Card',  inverse_of: :card_labels
    belongs_to :label, class_name: 'ChatwootKanban::Label', inverse_of: :card_labels

    validates :card_id, uniqueness: { scope: :label_id }
  end
end
