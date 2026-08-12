class Captain::Routines::Operations::Actions::ConversationSendReply < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.send_reply', effect: 'customer_visible_write',
    description: 'Send a customer-visible reply in one conversation.',
    arguments: { conversation_id: 'conversation ID or reference', content: 'literal reply content or rich_message reference' },
    required: %w[conversation_id content]
  )
end
