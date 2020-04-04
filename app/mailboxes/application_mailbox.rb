class ApplicationMailbox < ActionMailbox::Base
  routing(/@chatwoot.com\Z/i => :conversation)
end
