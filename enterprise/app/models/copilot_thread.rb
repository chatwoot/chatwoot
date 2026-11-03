# == Schema Information
#
# Table name: copilot_threads
#
#  id           :bigint           not null, primary key
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  assistant_id :integer
#  user_id      :bigint           not null
#
# Indexes
#
#  index_copilot_threads_on_account_id    (account_id)
#  index_copilot_threads_on_assistant_id  (assistant_id)
#  index_copilot_threads_on_user_id       (user_id)
#
class CopilotThread < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  has_many :copilot_messages, dependent: :destroy_async
  has_many :copilot_runs, dependent: :destroy_async

  validates :title, presence: true

  def push_event_data
    {
      id: id,
      title: title,
      created_at: created_at.to_i,
      user: user.push_event_data,
      account_id: account_id
    }
  end

  # True while Copilot works on a turn, so the agent waits for the answer or stops it. A turn waiting on a change the
  # agent has not approved is not working, because the agent's next message rejects that change.
  def working?
    CopilotRun::Turn.unfinished.exists?(copilot_thread: self) && !CopilotRun::Action.awaiting_approval.exists?(copilot_thread: self)
  end

  # A message the old Copilot never answered has no turn to stop, so it is marked stopped instead, and the panel lets the
  # agent write again.
  def stop
    turns = CopilotRun::Turn.unfinished.where(copilot_thread: self)
    return turns.find_each(&:stop) if turns.exists?

    request = copilot_messages.user.order(:id).last
    request.update!(message: request.message.merge('status' => 'stopped')) unless request.copilot_run
  end

  # A collection or review saved in this thread, which a Copilot tool call can read from.
  def saved_set(id, types: [CopilotRun::Collection, CopilotRun::Review])
    copilot_runs.where(account: account, user: user, type: types.map(&:sti_name)).find(id)
  end

  def previous_history
    copilot_messages
      .where(message_type: %w[user assistant])
      .order(created_at: :asc)
      .map do |copilot_message|
        {
          content: copilot_message.message['content'],
          role: copilot_message.message_type
        }
      end
  end
end
