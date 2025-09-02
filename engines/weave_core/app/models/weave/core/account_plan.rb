module Weave
  module Core
    class AccountPlan < ApplicationRecord
      self.table_name = 'weave_core_account_plans'

      belongs_to :account, class_name: '::Account'

      PLAN_KEYS = %w[basic pro premium app custom].freeze
      STATUSES = %w[active trial suspended].freeze
      TRIAL_DURATION_DAYS = 7

      validates :plan_key, inclusion: { in: PLAN_KEYS }
      validates :status, inclusion: { in: STATUSES }
      validates :account_id, presence: true, uniqueness: true

      scope :trial, -> { where(status: 'trial') }
      scope :active, -> { where(status: 'active') }
      scope :expired_trials, -> { trial.where('trial_ends_at < ?', Time.current) }

      before_create :auto_activate_trial, if: :should_start_trial?

      def trial?
        status == 'trial'
      end

      def active?
        status == 'active'
      end

      def suspended?
        status == 'suspended'
      end

      def trial_expired?
        trial? && trial_ends_at && trial_ends_at < Time.current
      end

      def days_until_trial_end
        return 0 unless trial? && trial_ends_at

        ((trial_ends_at - Time.current) / 1.day).ceil
      end

      def activate_trial!
        update!(
          status: 'trial',
          trial_ends_at: TRIAL_DURATION_DAYS.days.from_now
        )
      end

      def activate_plan!
        update!(
          status: 'active',
          trial_ends_at: nil
        )
      end

      def suspend!
        update!(status: 'suspended')
        account.suspended! if account.active?
      end

      private

      def should_start_trial?
        plan_key != 'basic' && status.nil?
      end

      def auto_activate_trial
        self.status = 'trial'
        self.trial_ends_at = TRIAL_DURATION_DAYS.days.from_now
      end
    end
  end
end

