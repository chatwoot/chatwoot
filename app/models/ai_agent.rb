# == Schema Information
#
# Table name: ai_agents
#
#  id                 :bigint           not null, primary key
#  context_limit      :integer          default(10)
#  control_flow_rules :boolean          default(FALSE), not null
#  history_limit      :integer          default(20)
#  message_await      :integer          default(5)
#  message_limit      :integer          default(1000)
#  model_name         :string           default("gpt-4o")
#  name               :string           not null
#  routing_conditions :text
#  system_prompts     :text             not null
#  timezone           :string           default("UTC"), not null
#  welcoming_message  :text             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :integer          not null
#
class AIAgent < ApplicationRecord
  belongs_to :account

  validates :name, :system_prompts, :welcoming_message, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

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
end
