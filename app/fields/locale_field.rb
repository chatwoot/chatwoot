require 'administrate/field/base'

class LocaleField < Administrate::Field::Base
  def to_s
    language = LANGUAGES_CONFIG.find { |_key, val| val[:iso_639_1_code] == data }
    language ? language[1][:name] : data
  end

  def selectable_options
    LANGUAGES_CONFIG.map { |_key, val| [val[:name], val[:iso_639_1_code]] }
  end
end
