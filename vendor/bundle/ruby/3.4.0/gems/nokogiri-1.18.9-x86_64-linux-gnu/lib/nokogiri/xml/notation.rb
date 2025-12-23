# frozen_string_literal: true

module Nokogiri
  module XML
    # Struct representing an {XML Schema Notation}[https://www.w3.org/TR/xml/#Notations]
    class Notation < Struct.new(:name, :public_id, :system_id)
      # dead comment to ensure rdoc processing

      # :attr: name (String)
      # The name for the element.

      # :attr: public_id (String)
      # The URI corresponding to the public identifier

      # :attr: system_id (String,nil)
      # The URI corresponding to the system identifier
    end
  end
end
