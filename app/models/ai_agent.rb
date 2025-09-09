# == Schema Information
#
# Table name: ai_agents
#
#  id                 :bigint           not null, primary key
#  agent_type         :string           default(NULL), not null
#  context_limit      :integer          default(10)
#  control_flow_rules :boolean          default(FALSE), not null
#  description        :string
#  display_flow_data  :jsonb
#  flow_data          :jsonb            not null
#  history_limit      :integer          default(20)
#  llm_model          :string           default("gpt-4o")
#  message_await      :integer          default(5)
#  message_limit      :integer          default(1000)
#  name               :string           not null
#  routing_conditions :text
#  system_prompts     :text             not null
#  template_type      :string           default("flowise"), not null
#  timezone           :string           default("UTC"), not null
#  welcoming_message  :text             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :integer          not null
#  chat_flow_id       :string
#  template_id        :bigint
#
class AiAgent < ApplicationRecord
  belongs_to :account
  has_many :ai_agent_selected_labels, dependent: :destroy
  has_many :labels, through: :ai_agent_selected_labels
  has_many :ai_agent_followups, dependent: :destroy
  has_many :agent_bot_inboxes, dependent: :nullify
  has_one :knowledge_source, dependent: :destroy

  validates :name, :system_prompts, :welcoming_message, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  enum template_type: { flowise: 'FLOWISE', jangkau: 'JANGKAU' }
  enum agent_type: { single_agent: 'single_agent', multi_agent: 'multi_agent', custom_agent: 'custom_agent' }

  scope :flowise, -> { where(template_type: :flowise) }
  scope :jangkau, -> { where(template_type: :jangkau) }
  scope :single_agent, -> { where(agent_type: :single_agent) }
  scope :multi_agent, -> { where(agent_type: :multi_agent) }
  scope :custom_agent, -> { where(agent_type: :custom_agent) }

  accepts_nested_attributes_for :ai_agent_selected_labels, allow_destroy: true

  before_validation :set_default_messages

  def set_default_messages
    self.system_prompts ||= 'Default system prompt'
    self.welcoming_message ||= 'Welcome!'
  end

  def push_event_data(_inbox = nil)
    {
      id: id,
      name: name,
      type: 'agent_bot'
    }
  end

  def self.agent_type_matches?(param_type, enum_key)
    agent_types[param_type] == agent_types[enum_key]
  end

  def self.source_type_matches?(param_type, enum_key)
    template_types[param_type] == template_types[enum_key]
  end

  def self.add_ai_agent(params, chat_flow, document_store)
    agent = new(
      params.merge(
        system_prompts: 'template.system_prompt',
        welcoming_message: 'template.welcoming_message',
        flow_data: chat_flow['flow_data'],
        display_flow_data: chat_flow['display_flow_data'],
        chat_flow_id: chat_flow['id']
      )
    )

    agent.build_knowledge_source(
      name: document_store['name'],
      store_id: document_store['id'],
      store_config: chat_flow['store_config']
    )

    agent.save!
    agent
  end

  def as_create_json
    {
      id: id,
      name: name,
      description: description,
      agent_type: agent_type,
      template_type: template_type,
      display_flow_data: display_flow_data,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def as_detailed_json
    as_json(json_options).transform_keys { |key| map_key(key) }
  end

  def timezone_object
    ActiveSupport::TimeZone[timezone]
  end

  def current_time_in_timezone
    timezone_object.now
  end

  def system_prompt_length
    system_prompts.length
  end

  delegate :length, to: :welcoming_message, prefix: true

  private

  def json_options
    {
      only: base_attributes,
      include: included_associations
    }
  end

  def base_attributes
    %i[id uid name description welcoming_message agent_type template_type display_flow_data]
  end

  def included_associations
    {
      ai_agent_selected_labels: {
        only: [:id, :label_id, :label_conditions],
        include: {
          label: {
            only: [:id, :name]
          }
        }
      },
      ai_agent_followups: {
        only: [:id, :prompts, :delay, :send_as_exact_message, :handoff_to_agent_after_sending]
      }
    }
  end

  def map_key(key)
    {
      'ai_agent_selected_labels' => 'selected_labels',
      'ai_agent_followups' => 'followups'
    }[key] || key
  end
end
