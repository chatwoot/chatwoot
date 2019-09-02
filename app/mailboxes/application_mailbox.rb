class ApplicationMailbox < ActionMailbox::Base

  routing SupportMailbox::MATCHER => :support

end
