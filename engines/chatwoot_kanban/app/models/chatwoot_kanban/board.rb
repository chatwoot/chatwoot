module ChatwootKanban
  # A board is an ordered collection of columns scoped to a single Chatwoot account.
  #
  # Schema (table: chatwoot_kanban_boards):
  #   id, account_id, name, description, settings (jsonb),
  #   created_by_id (FK users.id), archived_at, created_at, updated_at
  class Board < ApplicationRecord
    self.table_name = 'chatwoot_kanban_boards'

    # NOTE: we reference Chatwoot's core models by class name (strings) so the
    # engine never has to require host code. ActiveRecord resolves lazily.
    belongs_to :account, class_name: '::Account'
    belongs_to :created_by, class_name: '::User', optional: true

    has_many :columns, -> { order(position: :asc) },
             class_name: 'ChatwootKanban::Column',
             foreign_key: :board_id,
             dependent: :destroy,
             inverse_of: :board

    has_many :cards, through: :columns

    validates :name, presence: true, length: { maximum: 120 }
    validates :account_id, presence: true

    scope :active,   -> { where(archived_at: nil) }
    scope :archived, -> { where.not(archived_at: nil) }

    after_create :seed_default_columns

    def archive!
      update!(archived_at: Time.current)
    end

    def unarchive!
      update!(archived_at: nil)
    end

    def archived?
      archived_at.present?
    end

    private

    def seed_default_columns
      return if columns.exists?

      ChatwootKanban.configuration.default_column_names.each_with_index do |name, idx|
        columns.create!(name: name, position: idx)
      end
    end
  end
end
