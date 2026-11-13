class Search::MessageSearchCursor
  PURPOSE = 'message-search-cursor'.freeze
  CIPHER = 'aes-256-gcm'.freeze

  def initialize(account_id)
    @account_id = account_id
    key = Rails.application.key_generator.generate_key(PURPOSE, ActiveSupport::MessageEncryptor.key_len(CIPHER))
    @encryptor = ActiveSupport::MessageEncryptor.new(key, cipher: CIPHER, serializer: JSON, url_safe: true)
  end

  def read(token)
    return unless token

    cursor = @encryptor.decrypt_and_verify(token, purpose: PURPOSE)
    raise ArgumentError, 'Invalid message search cursor' unless cursor && cursor['account_id'] == @account_id

    cursor
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    raise ArgumentError, 'Invalid message search cursor'
  end

  def write(after:, offset:)
    return unless after

    @encryptor.encrypt_and_sign({ account_id: @account_id, after: after, offset: offset }, purpose: PURPOSE)
  end
end
