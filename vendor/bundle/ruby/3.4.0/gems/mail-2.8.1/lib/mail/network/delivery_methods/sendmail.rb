# frozen_string_literal: true
require 'mail/smtp_envelope'

module Mail
  # A delivery method implementation which sends via sendmail.
  #
  # To use this, first find out where the sendmail binary is on your computer,
  # if you are on a mac or unix box, it is usually in /usr/sbin/sendmail, this will
  # be your sendmail location.
  #
  #   Mail.defaults do
  #     delivery_method :sendmail
  #   end
  #
  # Or if your sendmail binary is not at '/usr/sbin/sendmail'
  #
  #   Mail.defaults do
  #     delivery_method :sendmail, :location => '/absolute/path/to/your/sendmail'
  #   end
  #
  # Then just deliver the email as normal:
  #
  #   Mail.deliver do
  #     to 'mikel@test.lindsaar.net'
  #     from 'ada@test.lindsaar.net'
  #     subject 'testing sendmail'
  #     body 'testing sendmail'
  #   end
  #
  # Or by calling deliver on a Mail message
  #
  #   mail = Mail.new do
  #     to 'mikel@test.lindsaar.net'
  #     from 'ada@test.lindsaar.net'
  #     subject 'testing sendmail'
  #     body 'testing sendmail'
  #   end
  #
  #   mail.deliver!
  class Sendmail
    DEFAULTS = {
      :location   => '/usr/sbin/sendmail',
      :arguments  => %w[ -i ]
    }

    attr_accessor :settings

    class DeliveryError < StandardError
    end

    def initialize(values)
      if values[:arguments].is_a?(String)
        deprecation_warn.call \
          'Initializing Mail::Sendmail with :arguments of type String is deprecated.' \
          ' Instead ensure :arguments is an array of strings, e.g. ["-i", "-t"]'
      end
      self.settings = self.class::DEFAULTS.merge(values)
    end

    def destinations_for(envelope)
      envelope.to
    end

    def deliver!(mail)
      envelope = Mail::SmtpEnvelope.new(mail)

      arguments = settings[:arguments]
      if arguments.is_a? String
        return old_deliver(envelope)
      end

      command = [settings[:location]]
      command.concat Array(arguments)
      command.concat [ '-f', envelope.from ] if envelope.from

      if destinations = destinations_for(envelope)
        command.push '--'
        command.concat destinations
      end

      popen(command) do |io|
        io.puts ::Mail::Utilities.binary_unsafe_to_lf(envelope.message)
        io.flush
      end
    end

    private
      def popen(command, &block)
        IO.popen(command, 'w+', :err => :out, &block).tap do
          if $?.exitstatus != 0
            raise DeliveryError, "Delivery failed with exitstatus #{$?.exitstatus}: #{command.inspect}"
          end
        end
      end

    #+ support for delivery using string arguments (deprecated)
    def old_deliver(envelope)
      smtp_from = envelope.from
      smtp_to = destinations_for(envelope)

      from = "-f #{shellquote(smtp_from)}" if smtp_from
      destination = smtp_to.map { |to| shellquote(to) }.join(' ')

      arguments = "#{settings[:arguments]} #{from} --"
      command = "#{settings[:location]} #{arguments} #{destination}"
      popen command do |io|
        io.puts ::Mail::Utilities.binary_unsafe_to_lf(envelope.message)
        io.flush
      end
    end

    # The following is an adaptation of ruby 1.9.2's shellwords.rb file,
    # with the following modifications:
    #
    # - Wraps in double quotes
    # - Allows '+' to accept email addresses with them
    # - Allows '~' as it is not unescaped in double quotes
    def shellquote(address)
      # Process as a single byte sequence because not all shell
      # implementations are multibyte aware.
      #
      # A LF cannot be escaped with a backslash because a backslash + LF
      # combo is regarded as line continuation and simply ignored. Strip it.
      escaped = address.gsub(/([^A-Za-z0-9_\s\+\-.,:\/@~])/n, "\\\\\\1").gsub("\n", '')
      %("#{escaped}")
    end
    #- support for delivery using string arguments

    def deprecation_warn
      defined?(ActiveSupport::Deprecation.warn) ? ActiveSupport::Deprecation.method(:warn) : Kernel.method(:warn)
    end
  end
end
