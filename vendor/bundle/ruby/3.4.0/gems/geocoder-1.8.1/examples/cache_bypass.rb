# This class allows you to configure how Geocoder should treat errors that occur when
# the cache is not available.
# Configure it like this
# config/initializers/geocoder.rb
# Geocoder.configure(
#  :cache => Geocoder::CacheBypass.new(Redis.new)
# )
#
# Depending on the value of @bypass this will either
# raise the exception (true) or swallow it and pretend the cache did not return a hit (false)
#
class Geocoder::CacheBypass
  def initialize(target, bypass = true)
    @target = target
    @bypass = bypass
  end


  def [](key)
    with_bypass { @target[key] }
  end

  def []=(key, value)
    with_bypass(value) { @target[key] = value }
  end

  def keys
    with_bypass([]) { @target.keys }
  end

  def del(key)
    with_bypass { @target.del(key) }
  end

  private

  def with_bypass(return_value_if_exception = nil, &block)
    begin
      yield
    rescue
      if @bypass
        return_value_if_exception
      else
        raise # reraise original exception
      end
    end
  end
end