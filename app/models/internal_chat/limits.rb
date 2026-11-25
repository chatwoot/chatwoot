class InternalChat::Limits
  # rise-brasil: internal chat Pro is unlocked for every installation of this fork,
  # matching `useInternalChatPro` on the frontend.
  def self.unlimited?
    true
  end

  def self.polls_enabled?
    unlimited?
  end

  def self.max_private_channels
    unlimited? ? nil : 2
  end

  def self.search_history_days
    unlimited? ? nil : 90
  end
end
