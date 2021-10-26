class Inboxes::FetchImapEmailsJob < ApplicationJob
    queue_as :low
  
    def perform(channel)
      puts "Fetch Imap Emails"
      Mail.defaults do
        retriever_method :imap, :address    => channel.host,
                                :port       => channel.port,
                                :user_name  => channel.user_email,
                                :password   => channel.user_password,
                                :enable_ssl => true
      end

      Mail.find(:what => :last, :count => 5, :order => :asc).each do |mail|
        Imap::ImapMailbox.new.process(mail) if mail.date >= channel.updated_at
      end

      Channel::Email.update(channel.id, :updated_at => Time.now.utc)
    end
  end
  