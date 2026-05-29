module Captain
  module Guards
    class ConversationResolutionGuard
      # Evaluate whether a conversation should be auto-resolved by Captain.
      # Returns an OpenStruct with :decision (:allow, :soft_block, :hard_block), :score, :reasons
      def self.evaluate(conversation, tool_context = {})
        require 'ostruct'

        reasons = []
        score = 0.0

        state = tool_context.respond_to?(:state) ? tool_context.state : tool_context || {}

        # Signal: explicit user confirmation provided in assistant state
        if state.dig(:conversation, :explicit_user_confirmation) || state[:explicit_user_confirmation]
          score += 0.9
          reasons << 'explicit_user_confirmation'
        end

        # Signal: recent user activity (if user recently sent messages, lower score)
        last_user_msg = conversation.messages.where(incoming: true).order(created_at: :desc).limit(1).first
        if last_user_msg
          if last_user_msg.created_at > 10.minutes.ago
            score -= 0.5
            reasons << 'recent_user_activity'
          else
            score += 0.1
            reasons << 'no_recent_user_activity'
          end
        end

        # Signal: last message authored by an agent/assistant increases confidence
        last_msg = conversation.messages.order(created_at: :desc).limit(1).first
        if last_msg && !last_msg.incoming
          score += 0.2
          reasons << 'last_from_agent'
        end

        # Signal: conversation has an assignee (someone is working) -> lower auto-resolve confidence
        if conversation.assignee_id.present?
          score -= 0.2
          reasons << 'has_assignee'
        end

        # Clamp score
        score = [[score, -1.0].max, 1.0].min

        decision = if score >= 0.9
                     :allow
                   elsif score >= 0.6
                     :soft_block
                   else
                     :hard_block
                   end

        OpenStruct.new(decision: decision, score: score, reasons: reasons)
      end
    end
  end
end
