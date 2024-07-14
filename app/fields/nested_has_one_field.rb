# app/fields/nested_has_one_field.rb
require 'administrate/field/base'

class NestedHasOneField < Administrate::Field::Base
  def to_s
    data
  end
end
