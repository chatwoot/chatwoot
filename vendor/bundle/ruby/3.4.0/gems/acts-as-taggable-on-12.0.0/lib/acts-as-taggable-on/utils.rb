# frozen_string_literal: true

# This module is deprecated and will be removed in the incoming versions

module ActsAsTaggableOn
  module Utils
    class << self
      # Use ActsAsTaggableOn::Tag connection
      def connection
        ActsAsTaggableOn::Tag.connection
      end

      def using_postgresql?
        connection && %w[PostgreSQL PostGIS].include?(connection.adapter_name)
      end

      def using_mysql?
        connection && connection.adapter_name == 'Mysql2'
      end

      def sha_prefix(string)
        Digest::SHA1.hexdigest(string)[0..6]
      end

      def like_operator
        using_postgresql? ? 'ILIKE' : 'LIKE'
      end

      # escape _ and % characters in strings, since these are wildcards in SQL.
      def escape_like(str)
        str.gsub(/[!%_]/) { |x| "!#{x}" }
      end
    end
  end
end
