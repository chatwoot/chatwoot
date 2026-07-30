class BulkActionsJob < ApplicationJob
  include DateRangeHelper

  queue_as :medium
  attr_accessor :records

  MODEL_TYPE = ['Conversation'].freeze

  def perform(account:, params:, user:)
    @account = account
    @user = user
    Current.user = user
    @params = params
    @records = records_to_updated(params[:ids])
    bulk_update
  ensure
    Current.reset
  end

  def bulk_update
    bulk_remove_labels
    bulk_conversation_update
  end

  def bulk_conversation_update
    params = available_params(@params)
    records.each do |conversation|
      bulk_add_labels(conversation)
      bulk_snoozed_until(conversation)
      bulk_update_read_status(conversation)
      conversation.update(params) if params
    end
  end

  def bulk_update_read_status(conversation)
    case @params[:read_status]
    when 'read'
      mark_conversation_read(conversation)
    when 'unread'
      mark_conversation_unread(conversation)
    end
  end

  def mark_conversation_read(conversation)
    Notification::MarkConversationReadService.new(user: @user, account: @account, conversation: conversation).perform
    conversation.update(agent_last_seen_at: DateTime.now.utc, assignee_last_seen_at: DateTime.now.utc)
  end

  def mark_conversation_unread(conversation)
    last_incoming_message = conversation.messages.incoming.last
    last_seen_at = last_incoming_message.created_at - 1.second if last_incoming_message.present?
    conversation.update(agent_last_seen_at: last_seen_at, assignee_last_seen_at: last_seen_at)
  end

  def bulk_remove_labels
    records.each do |conversation|
      remove_labels(conversation)
    end
  end

  def available_params(params)
    return unless params[:fields]

    params[:fields].delete_if { |key, value| value.nil? && key == 'status' }
  end

  def bulk_add_labels(conversation)
    conversation.add_labels(@params[:labels][:add]) if @params[:labels] && @params[:labels][:add]
  end

  def bulk_snoozed_until(conversation)
    conversation.snoozed_until = parse_date_time(@params[:snoozed_until].to_s) if @params[:snoozed_until]
  end

  def remove_labels(conversation)
    return unless @params[:labels] && @params[:labels][:remove]

    labels = conversation.label_list - @params[:labels][:remove]
    conversation.update(label_list: labels)
  end

  def records_to_updated(ids)
    current_model = @params[:type].camelcase
    return unless MODEL_TYPE.include?(current_model)

    scope = current_model.constantize.where(account_id: @account.id, display_id: ids)
    Conversations::PermissionFilterService.new(scope, @user, @account).perform
  end
end
