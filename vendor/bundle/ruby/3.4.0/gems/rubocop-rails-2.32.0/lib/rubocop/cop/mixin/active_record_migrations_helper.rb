# frozen_string_literal: true

module RuboCop
  module Cop
    # A mixin to extend cops for Active Record features
    module ActiveRecordMigrationsHelper
      extend NodePattern::Macros

      RAILS_ABSTRACT_SCHEMA_DEFINITIONS = %i[
        bigint binary boolean date datetime decimal float integer json string
        text time timestamp virtual
      ].freeze
      RAILS_ABSTRACT_SCHEMA_DEFINITIONS_HELPERS = %i[column references belongs_to primary_key numeric].freeze
      POSTGRES_SCHEMA_DEFINITIONS = %i[
        bigserial bit bit_varying cidr citext daterange hstore inet interval
        int4range int8range jsonb ltree macaddr money numrange oid point line
        lseg box path polygon circle serial tsrange tstzrange tsvector uuid xml
      ].freeze
      MYSQL_SCHEMA_DEFINITIONS = %i[
        blob tinyblob mediumblob longblob tinytext mediumtext longtext
        unsigned_integer unsigned_bigint unsigned_float unsigned_decimal
      ].freeze

      def_node_matcher :create_table_with_block?, <<~PATTERN
        (any_block
          (send nil? :create_table ...)
          { _ | (args (arg _var)) }
          _)
      PATTERN
    end
  end
end
