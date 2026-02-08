require 'administrate/field/base'

class SerializedField < Administrate::Field::Base
  def to_s
    hash? ? data.as_json : data.to_s
  end

  def hash?
    data.is_a? Hash
  end

  def array?
    data.is_a? Array
  end
end
