# Builds RFC 5322 compliant References headers for email threading
#
# This module provides functionality to construct proper References headers
# that maintain email conversation threading according to RFC 5322 standards.
module ReferencesHeaderBuilder
  # Builds a complete References header for an email reply
  #
  # According to RFC 5322, the References header should contain:
  # - References from the message being replied to (if available)
  # - The In-Reply-To message ID as the final element
  # - Proper line folding if the header exceeds 998 characters
  #
  # If the message being replied to has no stored References, we use a minimal
  # approach with only the In-Reply-To message ID rather than rebuilding.
  #
  # @param conversation [Conversation] The conversation containing the message thread
  # @param in_reply_to_message_id [String] The message ID being replied to
  # @return [String] A properly formatted and folded References header value
  def build_references_header(conversation, in_reply_to_message_id)
    references = get_references_from_replied_message(conversation, in_reply_to_message_id)
    references << in_reply_to_message_id

    references = references.compact.uniq
    fold_references_header(references)
  rescue StandardError => e
    Rails.logger.error("Error building references header for ##{conversation.id}: #{e.message}")
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    ''
  end

  private

  # Gets References header from the message being replied to
  #
  # Finds the message by its source_id matching the in_reply_to_message_id
  # and extracts its stored References header. If no References are found,
  # we return an empty array (minimal approach - no rebuilding).
  #
  # @param conversation [Conversation] The conversation containing the message thread
  # @param in_reply_to_message_id [String] The message ID being replied to
  # @return [Array<String>] Array of properly formatted message IDs with angle brackets
  def get_references_from_replied_message(conversation, in_reply_to_message_id)
    return [] if in_reply_to_message_id.blank?

    replied_to_message = find_replied_to_message(conversation, in_reply_to_message_id)
    return [] unless replied_to_message

    extract_references_from_message(replied_to_message)
  end

  # Finds the message being replied to based on its source_id
  #
  # @param conversation [Conversation] The conversation containing the message thread
  # @param in_reply_to_message_id [String] The message ID to search for
  # @return [Message, nil] The message being replied to
  def find_replied_to_message(conversation, in_reply_to_message_id)
    return nil if in_reply_to_message_id.blank?

    # Remove angle brackets if present for comparison
    normalized_id = in_reply_to_message_id.gsub(/[<>]/, '')

    # Use database query to find the message efficiently
    # Search for exact match or with angle brackets
    conversation.messages
                .where.not(source_id: nil)
                .where('source_id = ? OR source_id = ? OR source_id = ?',
                       normalized_id,
                       "<#{normalized_id}>",
                       in_reply_to_message_id)
                .first
  end

  # Extracts References header from a message's content_attributes
  #
  # @param message [Message] The message to extract References from
  # @return [Array<String>] Array of properly formatted message IDs with angle brackets
  def extract_references_from_message(message)
    return [] unless message.content_attributes&.dig('email', 'references')

    references = message.content_attributes['email']['references']
    Array.wrap(references).map do |ref|
      ref.start_with?('<') ? ref : "<#{ref}>"
    end
  end

  # Folds References header to comply with RFC 5322 line folding requirements
  #
  # RFC 5322 requires that continuation lines in folded headers start with
  # whitespace (space or tab). This method joins message IDs with CRLF + space,
  # ensuring the first line has no leading space and all continuation lines
  # start with a space as required by the RFC.
  #
  # @param references_array [Array<String>] Array of message IDs to be folded
  # @return [String] A properly folded header value with CRLF line endings
  def fold_references_header(references_array)
    return '' if references_array.empty?
    return references_array.first if references_array.size == 1

    references_array.join("\r\n ")
  end
end
