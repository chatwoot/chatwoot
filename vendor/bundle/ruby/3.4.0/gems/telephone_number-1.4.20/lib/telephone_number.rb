require 'telephone_number/version'
require 'active_model/telephone_number_validator' if defined?(ActiveModel)
require 'forwardable'

module TelephoneNumber
  autoload :ClassMethods,            'telephone_number/class_methods'
  autoload :Country,                 'telephone_number/country'
  autoload :Formatter,               'telephone_number/formatter'
  autoload :GeoLocator,              'telephone_number/geo_locator'
  autoload :GeoLocationDataImporter, 'importers/geo_location_data_importer'
  autoload :Number,                  'telephone_number/number'
  autoload :NumberFormat,            'telephone_number/number_format'
  autoload :NumberValidation,        'telephone_number/number_validation'
  autoload :Parser,                  'telephone_number/parser'
  autoload :PhoneDataImporter,       'importers/phone_data_importer'
  autoload :TestDataImporter,        'importers/test_data_importer'
  autoload :TimeZoneDataImporter,    'importers/time_zone_data_importer'
  autoload :TimeZoneDetector,        'telephone_number/time_zone_detector'

  extend ClassMethods
end
