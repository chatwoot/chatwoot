# Two changes to how a conversation is handed to an agent bot (#721). Upstream is kept on purpose
# where it chose: any bot of the account can still be assigned through the API, and the assigned
# bot gets the conversation's events (AgentBotListener#agent_bots_for, chatwoot/chatwoot#12836),
# which is what delegating to a specialist bot relies on.
#
# Declared here instead of as autoloaded classes, for the reason import_guards.rb gives: a
# reloadable module handed to `prepend` is a new object after every reload. Kept out of the files
# involved, which are upstream's, so that each sync conflicts on one line at most.
module AgentBotAssignment
  # The assignee dropdown listed every bot of the account, so the bot answering a WhatsApp inbox was
  # one click away from an e-mail conversation it had never been set up for; in production that
  # conversation sat in pending for five days with no owner. The dropdown now offers the inbox's own
  # active bot, and the bots connected to no inbox of the account, global ones included, which is
  # where a specialist bot lives. Any other connection takes a bot off the list, whatever its status
  # and whatever the inbox: an inactive one still says which inbox the bot was built for, and an
  # observer (AgentBotObserver) never answers, so handing it a conversation strands it the same way.
  #
  # With several inboxes asked for, a bot has to pass for each of them, the rule agents already
  # follow in the same action.
  #
  # Called from the controller's own index rather than prepended over it: Enterprise prepends its
  # half of that action, and a module put in front of it would wrap upstream's Enterprise code.
  module DropdownOffersNoForeignBot
    def self.offered(agent_bots, inboxes, account)
      return agent_bots if agent_bots.blank?

      connected = [AgentBotInbox, AgentBotObserver].flat_map do |connection|
        connection.where(account_id: account.id, agent_bot_id: agent_bots.map(&:id)).distinct.pluck(:agent_bot_id)
      end.to_set
      agent_bots.select { |agent_bot| inboxes.all? { |inbox| offered_for?(agent_bot, inbox, connected) } }
    end

    def self.offered_for?(agent_bot, inbox, connected)
      bot_inbox = inbox.agent_bot_inbox
      return true if bot_inbox&.active? && bot_inbox.agent_bot_id == agent_bot.id

      connected.exclude?(agent_bot.id)
    end
  end

  # Assigning a user writes "Assigned to <agent> by <user>"; assigning a bot wrote "Conversation
  # unassigned by <user>" when it replaced a human, and nothing at all otherwise, so the change had
  # no author. It now gets the same sentence. The bot the inbox hands a new conversation is left
  # out, as nobody assigned it.
  module BotAssignmentActivity
    private

    def process_assignment_activities
      # The customer's message handing a reopened conversation back to the inbox bot says why instead.
      return create_reopen_agent_bot_activity if reopen_agent_bot_handoff?
      return super if saved_change_to_team_id? || !ai_assignee_handed_over?

      user_name = activity_message_owner(Current.user&.name)
      return unless user_name

      content = I18n.t('conversations.activity.assignee.assigned', assignee_name: ai_assignee.name, user_name: user_name)
      ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content))
    end

    def ai_assignee_handed_over?
      return false if previously_new_record? || ai_assignee.blank?

      saved_change_to_assignee_agent_bot_id? || saved_change_to_ai_assignee_type?
    end
  end
end

Rails.application.config.to_prepare do
  Conversation.prepend(AgentBotAssignment::BotAssignmentActivity)
end
