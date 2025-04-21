# == Schema Information
#
# Table name: ai_agents
#
#  id                 :bigint           not null, primary key
#  context_limit      :integer          default(10)
#  control_flow_rules :boolean          default(FALSE), not null
#  description        :string
#  flow_data          :jsonb            not null
#  history_limit      :integer          default(20)
#  llm_model          :string           default("gpt-4o")
#  message_await      :integer          default(5)
#  message_limit      :integer          default(1000)
#  name               :string           not null
#  routing_conditions :text
#  system_prompts     :text             not null
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

  def push_event_data(_inbox = nil)
    {
      id: id,
      name: name,
      type: 'agent_bot'
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
    %i[
      id uid name description system_prompts welcoming_message
      routing_conditions control_flow_rules model_name
      history_limit context_limit message_await message_limit
      timezone created_at updated_at account_id chat_flow_id
    ]
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
