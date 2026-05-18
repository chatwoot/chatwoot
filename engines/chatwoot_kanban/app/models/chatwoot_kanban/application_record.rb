module ChatwootKanban
  # Engine-level base class. Keeps our tables on the same DB as Chatwoot
  # but isolates STI / class lookup to ChatwootKanban::*.
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true
  end
end
