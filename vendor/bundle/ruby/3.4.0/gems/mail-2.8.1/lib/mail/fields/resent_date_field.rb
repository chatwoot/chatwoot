# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/common_date_field'

module Mail
  #
  # resent-date     =       "Resent-Date:" date-time CRLF
  class ResentDateField < CommonDateField #:nodoc:
    NAME = 'Resent-Date'
  end
end
