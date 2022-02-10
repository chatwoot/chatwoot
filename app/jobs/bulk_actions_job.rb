class BulkActionsJob < ApplicationJob
  queue_as :medium
  attr_accessor :conversations

  def perform(account:, params:)
    @conversation_ids = params.delete(:conversation_ids)
    @labels = params.delete(:labels)
    @conversations = account.conversations.where(display_id: @conversation_ids)
    bulk_conversation_update(params)
  end

  def bulk_conversation_update(params)
    params = available_params(params)
    conversations.each do |conversation|
      update_labels(conversation)
      conversation.update(params)
    end
  end

  def available_params(params)
    params.delete_if { |_k, v| v.nil? }
  end

  def update_labels(conversation)
    conversation.add_labels(@labels) if @labels.present?
  end
end
