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
  # @param current_message [Message, nil] The message being sent (for context)
  # @return [String] A properly formatted and folded References header value
  def build_references_header(conversation, in_reply_to_message_id, current_message = nil)
    references = get_references_from_replied_message(conversation, current_message)
    references << in_reply_to_message_id

    references = references.compact.uniq
    fold_references_header(references)
  end

  private

  # Gets References header from the message being replied to
  #
  # If the current message has an in_reply_to_external_id, we find that message
  # and extract its stored References header. If no References are found,
  # we return an empty array (minimal approach - no rebuilding).
  #
  # @param conversation [Conversation] The conversation containing the message thread
  # @param current_message [Message, nil] The message being sent (for context)
  # @return [Array<String>] Array of properly formatted message IDs with angle brackets
  def get_references_from_replied_message(conversation, current_message)
    return [] unless current_message&.content_attributes&.dig('in_reply_to_external_id')

    replied_to_message = find_replied_to_message(conversation, current_message)
    return [] unless replied_to_message

    extract_references_from_message(replied_to_message)
  end

  # Finds the message being replied to based on in_reply_to_external_id
  #
  # @param conversation [Conversation] The conversation containing the message thread
  # @param current_message [Message] The message being sent
  # @return [Message, nil] The message being replied to
  def find_replied_to_message(conversation, current_message)
    external_id = current_message.content_attributes['in_reply_to_external_id']

    # Remove angle brackets if present for comparison
    external_id = external_id.gsub(/[<>]/, '') if external_id.is_a?(String)

    conversation.messages.find do |message|
      next unless message.source_id

      source_id = message.source_id.gsub(/[<>]/, '')
      source_id == external_id
    end
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
    references_array.join("\r\n ")
  end
end