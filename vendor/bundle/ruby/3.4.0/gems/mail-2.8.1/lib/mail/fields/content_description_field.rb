# encoding: utf-8
# frozen_string_literal: true
require 'mail/fields/named_unstructured_field'

module Mail
  class ContentDescriptionField < NamedUnstructuredField #:nodoc:
    NAME = 'Content-Description'

    def self.singular?
      true
    end
  end
end
