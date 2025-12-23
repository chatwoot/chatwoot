# frozen_string_literal: true

class SchemaInfo < ActiveRecord::Base
  if respond_to?(:table_name=)
    self.table_name = 'schema_info'
  else
    # this is becoming deprecated in ActiveRecord but not all adapters supported it
    # at this time
    set_table_name 'schema_info'
  end
  VERSION = 12
end
