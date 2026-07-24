# Hosting mail.mysecondhomedubai.com presents a wildcard cert for *.domain.com,
# which fails hostname verification. Skip verify for IMAP fetch only.
# Remove once the mailbox cert matches the IMAP hostname (or after Gmail cutover).
Rails.application.config.to_prepare do
  Imap::BaseFetchEmailService.class_eval do
    def build_imap_client
      imap = Net::IMAP.new(
        channel.imap_address,
        port: channel.imap_port,
        ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
      )
      Imap::Authentication.authenticate!(
        imap,
        authentication_type,
        channel.imap_login,
        imap_password
      )
      imap.select("INBOX")
      imap
    end
  end
end
