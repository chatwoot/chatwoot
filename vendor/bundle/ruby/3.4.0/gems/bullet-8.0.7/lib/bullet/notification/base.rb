# frozen_string_literal: true

module Bullet
  module Notification
    class Base
      attr_accessor :notifier, :url
      attr_reader :base_class, :associations, :path

      def initialize(base_class, association_or_associations, path = nil)
        @base_class = base_class
        @associations =
          association_or_associations.is_a?(Array) ? association_or_associations : [association_or_associations]
        @path = path
      end

      def title
        raise NoMethodError, 'no method title defined'
      end

      def body
        raise NoMethodError, 'no method body defined'
      end

      def call_stack_messages
        ''
      end

      def whoami
        @user ||=
          ENV['USER'].presence ||
          (
            begin
              `whoami`.chomp
            rescue StandardError
              ''
            end
          )
        @user.present? ? "user: #{@user}" : ''
      end

      def body_with_caller
        "#{body}\n#{call_stack_messages}\n"
      end

      def notify_inline
        notifier.inline_notify(notification_data)
      end

      def notify_out_of_channel
        notifier.out_of_channel_notify(notification_data)
      end

      def short_notice
        parts = []
        parts << whoami.presence unless Bullet.skip_user_in_notification
        parts << url
        parts << title
        parts << body

        parts.compact.join('  ')
      end

      def notification_data
        hash = {}
        hash[:user] = whoami unless Bullet.skip_user_in_notification
        hash[:url] = url
        hash[:title] = title
        hash[:body] = body_with_caller
        hash
      end

      def eql?(other)
        self.class == other.class && klazz_associations_str == other.klazz_associations_str
      end

      def hash
        [self.class, klazz_associations_str].hash
      end

      protected

      def klazz_associations_str
        "  #{@base_class} => [#{@associations.map(&:inspect).join(', ')}]"
      end

      def associations_str
        ".includes(#{@associations.map { |a| a.to_s.to_sym }
.inspect})"
      end
    end
  end
end
