class Onboarding::HelpCenterGenerationStatus
  KEY = 'onboarding'.freeze
  HELP_CENTER_KEY = 'help_center_generation'.freeze

  class << self
    def create!(account, generation_id)
      update!(account, generation_id, status: 'pending')
    end

    def mark_curating!(account, generation_id)
      update!(account, generation_id, status: 'curating')
    end

    def mark_generating!(account, generation_id)
      update!(account, generation_id, status: 'generating')
    end

    def mark_completed!(account, generation_id)
      update!(account, generation_id, status: 'completed', stale_safe: true)
    end

    def mark_skipped!(account, generation_id, reason:)
      update!(account, generation_id, status: 'skipped', skip_reason: reason)
    end

    def current(account)
      account.custom_attributes.dig(KEY, HELP_CENTER_KEY)
    end

    private

    def update!(account, generation_id, status:, skip_reason: nil, stale_safe: false)
      updated = false
      account.with_lock do
        account.reload
        attrs = account.custom_attributes.deep_dup
        onboarding = attrs[KEY] || {}
        current_generation = onboarding[HELP_CENTER_KEY]
        next if stale_safe && current_generation&.dig('id') != generation_id

        onboarding[HELP_CENTER_KEY] = {
          'id' => generation_id,
          'status' => status,
          'skip_reason' => skip_reason
        }.compact
        attrs[KEY] = onboarding
        account.update!(custom_attributes: attrs)
        updated = true
      end
      updated
    end
  end
end
