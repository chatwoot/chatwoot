Rails.application.config.to_prepare do
  next unless defined?(Message)

  unless Message.method_defined?(:_cmt_patch_hook_installed)
    Message.class_eval do
      after_create_commit :_cmt_patch_enqueue, if: :_cmt_patch_candidate?

      def _cmt_patch_hook_installed
        true
      end

      def _cmt_patch_candidate?
        _cmt_text_part_blank? &&
          message_type == 'incoming' &&
          inbox&.channel_type == 'Channel::Api' &&
          conversation&.custom_attributes&.dig('comment_id').to_s.length.positive?
      end

      def _cmt_text_part_blank?
        return true if content.blank?

        content.to_s.split('📎 البوست:').first.to_s.strip.empty?
      end

      def _cmt_patch_enqueue
        CommentTextPatchJob.perform_later(id)
      end
    end
    Rails.logger.info('[cmt-patch] installed Message after_create_commit hook for comments (text-part aware)')
  end
end
