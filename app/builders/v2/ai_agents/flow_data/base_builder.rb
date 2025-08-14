class V2::AiAgents::FlowData::BaseBuilder
  attr_reader :account, :templates, :params

  def initialize(account, templates, params)
    @account = account
    @templates = templates
    @params = params
  end

  def perform(collection_name = 'default_collection') # rubocop:disable Metrics/MethodLength
    tpl = base_template
    tpl[:type] = @params[:agent_type]
    tpl[:bot_name] = @params[:name]

    @templates.each do |template|
      tpl[:enabled_agents] << template.name_id
    end

    if @params[:agent_type] == AiAgent.agent_types[:multi_agent]
      tpl[:supervisor] = {
        persona: supervisor_prompt,
        routing_system: []
      }
      @templates.each do |template|
        tpl[:supervisor][:routing_system] << {
          name: template.name_id,
          description: template.description
        }
      end
    end
    tpl[:agents_config] = @templates.map { |template| agent_object(template, collection_name) }
    tpl
  end

  private

  def agent_object(template, collection_name = 'default_collection')
    {
      agent_id: SecureRandom.alphanumeric(8),
      type: template.name_id,
      name: template.name,
      bot_prompt: {
        persona: template.system_prompt,
        instructions: template.system_prompt_rules,
        handover_conditions: template.handover_prompt
      },
      configurations: {},
      collection_name: collection_name,
      tools: [
        {
          name: 'default_tool'
        }
      ]
    }
  end

  def base_template
    raise NotImplementedError, 'Subclass must implement base_template'
  end

  def supervisor_prompt
    <<~PROMPT
      Anda adalah Agen layanan untuk sebuah bisnis. Peran Anda adalah memberikan dukungan pelanggan yang membantu, profesional, dan empatik. Gunakan Bahasa Indonesia untuk membalas pelanggan, kecuali pelanggan berbicara dalam bahasa lain.
    PROMPT
  end
end
