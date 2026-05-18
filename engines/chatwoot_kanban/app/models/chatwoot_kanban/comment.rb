module ChatwootKanban
  class Comment < ApplicationRecord
    self.table_name = 'chatwoot_kanban_comments'

    belongs_to :card,   class_name: 'ChatwootKanban::Card', inverse_of: :comments
    belongs_to :author, class_name: '::User', foreign_key: :author_id

    validates :content, presence: true, length: { maximum: 5_000 }

    # Extract @mentions from content (simple — looks for "@<digits>" tokens
    # rendered by the frontend after picking a user from the autocomplete).
    before_save :extract_mentions

    def mentioned_user_ids
      Array(mentions).filter_map { |m| m['user_id'] || m[:user_id] }
    end

    private

    def extract_mentions
      ids = content.to_s.scan(/@(\d+)/).flatten.uniq.map(&:to_i)
      self.mentions = ids.map { |id| { user_id: id } }
    end
  end
end
