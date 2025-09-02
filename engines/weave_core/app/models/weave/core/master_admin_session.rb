module Weave
  module Core
    class MasterAdminSession < ApplicationRecord
      self.table_name = 'weave_core_master_admin_sessions'
      
      belongs_to :master_admin, class_name: 'Weave::Core::MasterAdmin'
      
      validates :session_token, presence: true, uniqueness: true
      validates :expires_at, presence: true
      
      scope :active, -> { where('expires_at > ?', Time.current) }
      scope :expired, -> { where('expires_at <= ?', Time.current) }
      
      def active?
        expires_at > Time.current
      end
      
      def expired?
        !active?
      end
      
      def expire!
        update!(expires_at: Time.current)
      end
      
      def extend_session!(hours = 8)
        update!(expires_at: hours.hours.from_now)
      end
      
      def time_remaining
        return 0 if expired?
        ((expires_at - Time.current) / 1.hour).round(2)
      end
      
      def self.cleanup_expired!
        expired.delete_all
      end
    end
  end
end