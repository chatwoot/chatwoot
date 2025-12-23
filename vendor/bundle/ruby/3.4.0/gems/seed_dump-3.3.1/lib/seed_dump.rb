require 'ipaddr'
require 'seed_dump/dump_methods/enumeration'
require 'seed_dump/dump_methods'
require 'seed_dump/environment'

class SeedDump
  extend Environment
  extend DumpMethods

  require 'seed_dump/railtie' if defined?(Rails)
end
