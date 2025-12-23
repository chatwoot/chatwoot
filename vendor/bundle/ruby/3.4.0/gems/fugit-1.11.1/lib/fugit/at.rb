# frozen_string_literal: true

module Fugit

  module At

    class << self

      def parse(s)

        ::EtOrbi.make_time(s) rescue nil
      end

      def do_parse(s)

        ::EtOrbi.make_time(s)
      end
    end
  end
end

