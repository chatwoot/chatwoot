class ConversationMonitors::PreviewJob < ApplicationJob
  queue_as :monitors_live
  SAMPLE_SIZE = 5
  EXPIRY = 15.minutes

  def self.cache_key(account_id, user_id, token)
    "conversation_monitors:preview:#{account_id}:#{user_id}:#{token}"
  end

  def self.read(key)
    value = Redis::Alfred.get(key)
    JSON.parse(value, symbolize_names: true) if value
  end

  def self.write(key, value)
    Redis::Alfred.setex(key, value.to_json, EXPIRY)
  end

  def perform(account_id, user_id, token)
    @key = self.class.cache_key(account_id, user_id, token)
    request = self.class.read(@key)
    account = Account.find_by(id: account_id)
    return unless request&.dig(:status) == 'pending' && allowed?(account, user_id)

    @monitor = ConversationMonitors::Monitor.new(id: 0, condition: request[:condition], model: ConversationMonitors::Configuration.model)
    conversations = sample(account)
    write_result(conversations)
  rescue CustomExceptions::MonitorEvaluationError => e
    self.class.write(@key, { status: 'error', error: e.code })
  end

  private

  def allowed?(account, user_id)
    account && ConversationMonitors::Configuration.enabled?(account) && account.account_users.find_by(user_id: user_id)&.administrator?
  end

  def sample(account)
    account.conversations.where(created_at: 7.days.ago..).includes(:contact, :inbox, :assignee).order(id: :desc).limit(SAMPLE_SIZE).to_a
  end

  def write_result(conversations)
    matches = conversations.select { |conversation| matches?(conversation) }
    self.class.write(@key, { status: 'complete', sampled: conversations.size, excluded: @excluded.to_i,
                             conversation_ids: matches.map(&:id) })
  end

  def matches?(conversation)
    state = ConversationMonitors::ContextBuilder.new(conversation).build
    response = ConversationMonitors::JevClient.new(account_id: conversation.account_id).evaluate(state: state, monitors: [@monitor])
    ConversationMonitors::JevClient.score(response['answers']['0']) >= ConversationMonitors::Configuration::THRESHOLD
  rescue CustomExceptions::MonitorEvaluationError => e
    raise unless %w[context_limit no_text].include?(e.code)

    @excluded = @excluded.to_i + 1
    false
  end
end
