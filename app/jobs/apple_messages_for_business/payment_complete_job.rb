class AppleMessagesForBusiness::PaymentCompleteJob < ApplicationJob
  queue_as :default

  def perform(channel_id, payment_result)
    channel = Channel::AppleMessagesForBusiness.find(channel_id)
    inbox = channel.inbox

    # Find the conversation where payment was initiated
    conversation = find_payment_conversation(inbox, payment_result)
    return unless conversation

    if payment_result['success']
      create_payment_success_message(conversation, payment_result)
      process_successful_payment(channel, payment_result)
    else
      create_payment_failure_message(conversation, payment_result)
    end

    Rails.logger.info "[AMB Payment] Payment #{payment_result['success'] ? 'completed' : 'failed'} for channel #{channel_id}"
  end

  private

  def find_payment_conversation(inbox, payment_result)
    # Find conversation by transaction ID or other identifier
    if payment_result['conversation_id']
      inbox.conversations.find_by(id: payment_result['conversation_id'])
    else
      # Fallback to most recent conversation
      inbox.conversations.order(updated_at: :desc).first
    end
  end

  def create_payment_success_message(conversation, payment_result)
    Message.create!(
      conversation: conversation,
      inbox: conversation.inbox,
      account: conversation.account,
      message_type: :incoming,
      content: build_success_message_content(payment_result),
      sender: conversation.contact
    )
  end

  def create_payment_failure_message(conversation, payment_result)
    Message.create!(
      conversation: conversation,
      inbox: conversation.inbox,
      account: conversation.account,
      message_type: :incoming,
      content: "Payment failed: #{payment_result['error']}",
      sender: conversation.contact
    )
  end

  def build_success_message_content(payment_result)
    amount = payment_result['amount']
    currency = payment_result['currency']
    transaction_id = payment_result['transaction_id']

    "Payment completed successfully!\n" \
    "Amount: #{format_currency(amount, currency)}\n" \
    "Transaction ID: #{transaction_id}"
  end

  def format_currency(amount, currency)
    "#{currency} #{amount}"
  end

  def process_successful_payment(channel, payment_result)
    # Store payment record or trigger other business logic
    # This could integrate with order management systems, etc.
    Rails.logger.info "[AMB Payment] Processing successful payment: #{payment_result['transaction_id']}"
  end
end