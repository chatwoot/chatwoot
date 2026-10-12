module SalesRouting::Assignment
  private

  def store_routing
    @store_routing ||= SalesRouting::Configuration.new(inbox: inbox)
  end

  def perform_for_conversation(conversation)
    return super unless store_routing.enabled?

    inbox.with_lock do
      conversation.with_lock do
        next false unless assignable?(conversation)
        next false unless SalesRouting::Classifier.new(conversation: conversation).perform

        super
      end
    end
  end

  def assignment_attributes(conversation, agent)
    return super unless store_routing.enabled?

    super.merge(SalesRouting::AgentSelector.new(conversation: conversation, configuration: store_routing, round: []).assignment_attributes(agent))
  end

  def prioritize_conversations(scope)
    return super unless store_routing.enabled?

    # Drain overnight leads oldest first; retain the configured daytime priority afterwards.
    overnight = "conversations.additional_attributes #>> '{store_routing,outside_business_hours}' = 'true'"
    original_order = super(scope).order_values
    scope.reorder(Arel.sql("CASE WHEN #{overnight} THEN 0 ELSE 1 END"),
                  Arel.sql("CASE WHEN #{overnight} THEN conversations.created_at END ASC"), *original_order)
  end

  def find_available_agent(conversation = nil)
    return super unless store_routing.enabled?

    selector = SalesRouting::AgentSelector.new(conversation: conversation, configuration: store_routing, round: (@store_round ||= []))
    agents = selector.candidates(filter_agents_by_role(inbox.available_agents))
    agents = filter_agents_by_rate_limit(agents)
    agents = filter_agents_by_capacity(agents) if capacity_filtering_enabled?
    selector.select(agents)
  end
end
