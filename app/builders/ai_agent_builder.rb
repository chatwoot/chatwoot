class AIAgentBuilder
  def initialize(account)
    @account = account
    @attributes = {}
  end

  def name(name)
    @attributes[:name] = name
    self
  end

  def system_prompts(system_prompts)
    @attributes[:system_prompts] = system_prompts
    self
  end

  def welcoming_message(welcoming_message)
    @attributes[:welcoming_message] = welcoming_message
    self
  end

  def timezone(timezone)
    @attributes[:timezone] = timezone
    self
  end

  def build
    @account.ai_agents.new(@attributes)
  end

  def save
    ai_agent = build
    ai_agent.save
    ai_agent
  end
end
