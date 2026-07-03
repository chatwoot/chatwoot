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
      next unless params

      assign_conversation(conversation, params)
      conversation.update(params.except(:assignee_id, :assignee_type))
    end
  end

  # Resolve the assignee in-memory (bots aren't a Conversation column) so the single update
  # in the caller persists it in one write and skips invalid records instead of aborting.
  def assign_conversation(conversation, params)
    return unless params.key?(:assignee_id)

    if params[:assignee_type].to_s == 'AgentBot'
      conversation.assign_attributes(
        assignee_agent_bot: AgentBot.accessible_to(@account).find_by(id: params[:assignee_id]),
        assignee: nil
      )
    else
      conversation.assign_attributes(
        assignee: @account.users.find_by(id: params[:assignee_id]),
        assignee_agent_bot: nil
      )
    end
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
