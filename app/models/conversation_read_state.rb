class ConversationReadState < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :user

  validates :last_seen_at, presence: true
  validates :user_id, uniqueness: { scope: :conversation_id }

  def self.last_seen_arel(user_id)
    conversations = Conversation.arel_table
    lookup = arel_table.project(arel_table[:last_seen_at])
                       .where(arel_table[:conversation_id].eq(conversations[:id]).and(arel_table[:user_id].eq(user_id)))
    Arel::Nodes::NamedFunction.new('COALESCE',
                                   [Arel::Nodes::Grouping.new(lookup.ast), conversations[:read_baseline_at], Arel.sql("'-infinity'::timestamp")])
  end
end
