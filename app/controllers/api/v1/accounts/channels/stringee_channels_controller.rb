class Api::V1::Accounts::Channels::StringeeChannelsController < Api::V1::Accounts::BaseController
  include Api::V1::StringeePccHelper
  before_action :fetch_inbox, :current_agents_ids, only: [:destroy, :update_agents]

  def index
    stringee_phone_calls = Current.account.stringee_phone_calls.includes(:inbox)
    channels_info = stringee_phone_calls.pluck('inboxes.name', :phone_number)
    render json: channels_info.map { |inbox_name, phone_number| { alias: inbox_name, number: phone_number } }
  end

  def number_to_call
    inboxes = Current.account.inboxes.where(channel_type: 'Channel::StringeePhoneCall')
    inbox = inboxes.joins(:inbox_members).where(inbox_members: { user_id: Current.user.id }).first
    if inbox
      render json: { number: inbox.channel.phone_number }
    else
      render json: { number: nil }
    end
  end

  def create
    phone_number = params[:phone_number]
    inbox_name = params[:inbox_name]

    queue_id = create_queue("#{inbox_name} queue")
    return if queue_id.blank?

    # TODO: need to consider with the way adding new number to Stringee
    # number_id = add_number(phone_number, inbox_name, queue_id)
    number_id = 'XXXXXX'
    return if number_id.blank?

    inbox = nil
    ActiveRecord::Base.transaction do
      channel = Current.account.stringee_phone_calls.create!(phone_number: phone_number, queue_id: queue_id, number_id: number_id)
      inbox = Current.account.inboxes.create!(name: inbox_name, channel: channel)
    end
    render json: inbox.as_json
  rescue StandardError => e
    handle_exception(e)
  end

  def destroy
    current_agents_ids.each { |user_id| remove_agent_from_stringee(user_id) }
    # TODO: need to consider with the way adding new number to Stringee
    # remove_number(@inbox.channel.number_id)
    delete_queue(@inbox.channel.queue_id)
  end

  def update_agents
    # get all the user_ids which the inbox currently has as members.
    # get the list of user_ids from params
    # the missing ones are the agents which are to be deleted from StringeePCC
    # the new ones are the agents which are to be added to StringeePCC
    ActiveRecord::Base.transaction do
      agents_to_be_added_ids.each { |user_id| add_agent_to_stringee(user_id) }
      agents_to_be_removed_ids.each { |user_id| remove_agent_from_stringee(user_id) }
    end
  rescue StandardError => e
    Rails.logger.error("Failed to update Stringee agents: #{e.message}")
  end

  private

  def add_agent_to_stringee(user_id)
    return if user_in_stringee_channel(user_id)

    user = User.find(user_id)
    agent_id = create_agent(user.name, user.stringee_user_id)
    return if agent_id.blank?

    user.custom_attributes['agent_id'] = agent_id
    user.custom_attributes['stringee_access_token'] = user.stringee_access_token
    user.save!
  end

  def remove_agent_from_stringee(user_id)
    return if user_in_stringee_channel(user_id)

    user = User.find(user_id)
    agent_id = user.custom_attributes['agent_id']
    return if agent_id.blank?

    delete_agent(agent_id)
    user.custom_attributes.delete('agent_id')
    user.custom_attributes.delete('stringee_access_token')
    user.save!
  end

  def user_in_stringee_channel(user_id)
    other_stringee_channels = Current.account.inboxes.where(channel_type: 'Channel::StringeePhoneCall').where.not(id: @inbox.id)
    other_stringee_channels.joins(:inbox_members).exists?(inbox_members: { user_id: user_id })
  end

  def agents_to_be_added_ids
    params[:user_ids] - @current_agents_ids
  end

  def agents_to_be_removed_ids
    @current_agents_ids - params[:user_ids]
  end

  def current_agents_ids
    @current_agents_ids = @inbox.members.pluck(:id)
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def handle_exception(exception)
    ChatwootExceptionTracker.new(exception).capture_exception
    Rails.logger.error "Error in create inbox for Stringee phone call channel: #{exception.message}"
  end
end
