module Current
  ATTRIBUTES = %i[user account account_user executed_by contact inbox conversation_snapshot].freeze

  ATTRIBUTES.each { |attribute| thread_mattr_accessor attribute }

  def self.reset
    ATTRIBUTES.each { |attribute| public_send(:"#{attribute}=", nil) }
  end

  # Runs the block against a clean Current and gives the caller its own values back
  # afterwards. Mailers need both halves: a mail is rendered for one account, not for
  # whoever happened to ask for it, and the code that asked is still running once the
  # mail is built.
  def self.isolate
    previous = ATTRIBUTES.index_with { |attribute| public_send(attribute) }
    reset
    yield
  ensure
    previous.each { |attribute, value| public_send(:"#{attribute}=", value) }
  end
end
