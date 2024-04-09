require 'administrate/field/base'

class LtdAttributeField < Administrate::Field::Base
  def to_s
    data.present? ? data.to_json : { ltd_plan_name: nil, ltd_quantity: nil }.to_json
  end
end
