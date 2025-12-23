Jbuilder = Class.new(begin
  require 'active_support/proxy_object'
  ActiveSupport::ProxyObject
rescue LoadError
  require 'active_support/basic_object'
  ActiveSupport::BasicObject
end)
