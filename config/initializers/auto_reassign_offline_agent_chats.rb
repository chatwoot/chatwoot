Rails.application.config.to_prepare do
  OnlineStatusTracker.singleton_class.class_eval do
    alias_method :set_status_original, :set_status

    def set_status(account_id, user_id, status)
      result = set_status_original(account_id, user_id, status)

      if status.to_s == 'offline'
        Rails.logger.info "Agent #{user_id} went offline in account #{account_id} -> reassign chats"
        ReassignOfflineAgentChatsJob.perform_later(user_id, account_id)
      end

      result
    end
  end

  Rails.logger.info 'OnlineStatusTracker patched successfully'
end
