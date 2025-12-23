# frozen_string_literal: true

module Net::IMAP::SASL

  # Alias for Net::IMAP::StringPrep::SASLprep.
  SASLprep            = Net::IMAP::StringPrep::SASLprep
  StringPrep          = Net::IMAP::StringPrep                      # :nodoc:
  BidiStringError     = Net::IMAP::StringPrep::BidiStringError     # :nodoc:
  ProhibitedCodepoint = Net::IMAP::StringPrep::ProhibitedCodepoint # :nodoc:
  StringPrepError     = Net::IMAP::StringPrep::StringPrepError     # :nodoc:

end
