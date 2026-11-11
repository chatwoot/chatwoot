# Picks the automation event a rule's name and description imply, such as message_created for
# "Tag refund requests". Jev picks from the events the form offers.
class Captain::AutomationEventRecommendation
  MODEL = Captain::FilterRecommendationService::MODEL
  MIN_PROBABILITY = 0.5
  CACHE_TTL = Captain::FilterRecommendationService::CACHE_TTL
  EVENT_CRITERIA = {
    'conversation_created' => 'A new conversation starts',
    'conversation_updated' => 'A conversation changes, such as its status, assignee, team, priority or labels',
    'conversation_opened' => 'A conversation is opened or reopened',
    'conversation_resolved' => 'A conversation is resolved or closed',
    # Without the second sentence, rules about what customers say, such as "Tag refund requests", got no event.
    'message_created' => 'A message arrives from the customer or is sent by an agent. ' \
                         'Rules about what a message says, such as a request, a question, a complaint or a tone, run here',
    'monitor_matched' => 'A conversation monitor finds a match'
  }.freeze
  NONE_CRITERION = { 'none' => '`description` does not say when the rule should run' }.freeze

  class Error < StandardError; end

  # `events` lists the event names the automation form offers.
  pattr_initialize [:account!, :query!, :events!]

  # The event name, or nil when Jev is unsure, finds none, or cannot answer.
  def perform
    return if Captain::JevClient.api_key.blank? || criteria.size == NONE_CRITERION.size

    event = Captain::JevAnswers.confident_choice(cached_answers['event'], MIN_PROBABILITY)
    event if events.include?(event)
  rescue Captain::JevClient::HTTPError, Faraday::Error, JSON::ParserError, Error => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    nil
  end

  private

  def cached_answers
    cache_key = "captain:automation_event_recommendation:#{Digest::SHA256.hexdigest([MODEL, question, query].to_json)}"
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { ask }
  end

  def ask
    body = Captain::JevClient.request_body(model: MODEL, state: { description: query }, questions: { event: question })
    response = Captain::JevClient.new(account_id: account.id, feature: 'filter_recommendations').call(body: body)
    answers = response['answers'] if response.is_a?(Hash)
    raise Error, 'Jev returned an invalid response' unless answers.is_a?(Hash)

    answers
  end

  def question
    {
      type: 'choice',
      instructions: '`description` names and describes an automation rule. When should the rule run?',
      criteria: criteria
    }
  end

  def criteria
    @criteria ||= EVENT_CRITERIA.slice(*events).merge(NONE_CRITERION)
  end
end

Captain::AutomationEventRecommendation.prepend_mod_with('Captain::AutomationEventRecommendation')
