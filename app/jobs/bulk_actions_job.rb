class BulkActionsJob < ApplicationJob
  queue_as :medium
  attr_accessor :conversations

  def perform(account:, params:, method_type:, user:)
    @conversation_ids = params.delete(:conversation_ids)
    @labels = params.delete(:labels)
    @conversations = account.conversations.where(display_id: @conversation_ids)
    @method_type = method_type
    Current.user = user
    bulk_update(params)
  end

  def bulk_update(params)
    if @method_type == :delete
      bulk_delete_conversation(params)
    else
      bulk_conversation_update(params)
    end
  end

  def bulk_conversation_update(params)
    params = available_params(params)
    conversations.each do |conversation|
      add_labels(conversation)
      conversation.update(params)
    end
  end

  def bulk_delete_conversation(_params)
    conversations.each do |conversation|
      remove_labels(conversation)
    end
  end

  def available_params(params)
    params.delete_if { |_k, v| v.nil? }
  end

  def add_labels(conversation)
    conversation.add_labels(@labels) if @labels.present?
  end

  def remove_labels(conversation)
    labels = conversation.label_list - @labels
    conversation.update(label_list: labels)
  end
end
