class Inboxes::FetchImapEmailsJob < ApplicationJob
    queue_as :low
  
    def perform(channel)
      puts "Fetch Imap Emails"
      Mail.defaults do
        retriever_method :imap, :address    => channel.imap_address,
                                :port       => channel.imap_port,
                                :user_name  => channel.imap_email,
                                :password   => channel.imap_password,
                                :enable_ssl => channel.imap_enable_ssl
      end

      Mail.find(:what => :last, :count => 10, :order => :desc).each do |mail|
        Imap::ImapMailbox.new.process(mail) if mail.date >= channel.updated_at
      end

      Channel::Email.update(channel.id, :updated_at => Time.now.utc)
    end
  end
  