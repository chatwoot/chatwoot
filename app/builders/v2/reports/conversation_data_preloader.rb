class V2::Reports::ConversationDataPreloader
  attr_reader :account, :params, :reporting_events_cache, :agent_chat_durations_cache,
              :participating_agents_cache, :user_names_cache

  def initialize(account, params = {})
    @account = account
    @params = params
    @reporting_events_cache = {}
    @participating_agents_cache = {}
    @agent_chat_durations_cache = {}
    @user_names_cache = {}
  end

  def preload_batch_data(conversation_ids)
    return if conversation_ids.empty?

    preload_reporting_events_batch(conversation_ids)
    preload_agent_chat_durations_batch(conversation_ids)
    preload_participating_agents_batch(conversation_ids)
  end

  private

  def preload_reporting_events_batch(conversation_ids)
    events = account.reporting_events
                    .where(conversation_id: conversation_ids)
                    .where(name: %w[conversation_resolved first_response reply_time])
                    .select(:conversation_id, :name, average_value_key)
                    .group_by { |e| [e.conversation_id, e.name] }

    @reporting_events_cache.merge!(events)
  end

  def preload_agent_chat_durations_batch(conversation_ids)
    events = fetch_agent_chat_duration_events(conversation_ids)
    cache_user_names(events)
    cache_agent_chat_durations(events)
  end

  def fetch_agent_chat_duration_events(conversation_ids)
    account.reporting_events
           .where(conversation_id: conversation_ids, name: 'agent_chat_duration')
           .select(:conversation_id, :user_id, average_value_key)
  end

  def cache_user_names(events)
    user_ids = events.filter_map(&:user_id).uniq
    return if user_ids.empty?

    User.where(id: user_ids).pluck(:id, :name).each do |user_id, name|
      @user_names_cache[user_id] = name
    end
  end

  def cache_agent_chat_durations(events)
    events.each do |event|
      key = [event.conversation_id, event.user_id]
      @agent_chat_durations_cache[key] ||= []
      @agent_chat_durations_cache[key] << event
    end
  end

  def preload_participating_agents_batch(conversation_ids)
    participants = fetch_conversation_participants(conversation_ids)
    participants_by_conv = participants.group_by(&:first)

    conversation_ids.each do |conv_id|
      agents = collect_agents_for_conversation(conv_id, participants_by_conv)
      @participating_agents_cache[conv_id] = agents.uniq { |a| a[:id] }.compact
    end
  end

  def fetch_conversation_participants(conversation_ids)
    ConversationParticipant.joins(:user).where(conversation_id: conversation_ids).pluck(:conversation_id, 'users.id', 'users.name')
  end

  def collect_agents_for_conversation(conv_id, participants_by_conv)
    agents = []
    agents += extract_agents_from_participants(conv_id, participants_by_conv)
    agents += extract_agents_from_chat_durations(conv_id, agents)
    agents
  end

  def extract_agents_from_participants(conv_id, participants_by_conv)
    return [] unless participants_by_conv[conv_id]

    participants_by_conv[conv_id].map { |r| { id: r[1], name: r[2] } }
  end

  def extract_agents_from_chat_durations(conv_id, existing_agents)
    agents = []

    @agent_chat_durations_cache.each_key do |key|
      next unless key[0] == conv_id

      user_id = key[1]
      next if existing_agents.any? { |a| a[:id] == user_id }

      agents << { id: user_id, name: @user_names_cache[user_id] }
    end

    agents
  end

  def average_value_key
    @average_value_key ||= ActiveModel::Type::Boolean.new.cast(params[:business_hours]) ? :value_in_business_hours : :value
  end
end
