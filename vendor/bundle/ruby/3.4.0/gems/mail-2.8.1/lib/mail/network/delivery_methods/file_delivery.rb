# frozen_string_literal: true
require 'mail/smtp_envelope'

module Mail
  # FileDelivery class delivers emails into multiple files based on the destination
  # address.  Each file is appended to if it already exists.
  # 
  # So if you have an email going to fred@test, bob@test, joe@anothertest, and you
  # set your location path to /path/to/mails then FileDelivery will create the directory
  # if it does not exist, and put one copy of the email in three files, called
  # by their message id
  # 
  # Make sure the path you specify with :location is writable by the Ruby process
  # running Mail.
  class FileDelivery
    require 'fileutils'

    attr_accessor :settings

    def initialize(values)
      self.settings = { :location => './mails', :extension => '' }.merge!(values)
    end

    def deliver!(mail)
      envelope = Mail::SmtpEnvelope.new(mail)

      if ::File.respond_to?(:makedirs)
        ::File.makedirs settings[:location]
      else
        ::FileUtils.mkdir_p settings[:location]
      end

      envelope.to.uniq.each do |to|
        path = ::File.join(settings[:location], File.basename(to.to_s+settings[:extension]))

        ::File.open(path, 'a') do |f|
          f.write envelope.message
          f.write "\r\n\r\n"
        end
      end
    end
  end
end
