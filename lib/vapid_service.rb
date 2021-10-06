class VapidService
  def self.public_key
    cached_public || ENV['VAPID_PUBLIC_KEY']
  end

  def self.private_key
    cached_private || ENV['VAPID_PRIVATE_KEY']
  end

  def self.cache(key, value)
    ::Redis::Alfred.set(key, value)
  end

  def self.keys
    @keys || InstallationConfig.find_by(name: 'VAPID_KEYS')&.value
  end

  def self.cached_public
    key =  ::Redis::Alfred.get(::Redis::Alfred::PUSH_PUBLIC_KEY)

    return key if key&.present?

    key = keys&.dig('public_key')
    cache(::Redis::Alfred::PUSH_PUBLIC_KEY, key)
    key
  end

  def self.cached_private
    key = ::Redis::Alfred.get(::Redis::Alfred::PUSH_PRIVATE_KEY)
    return key if key.present?

    key = keys&.dig('private_key')
    cache(::Redis::Alfred::PUSH_PRIVATE_KEY, key)
    key
  end

  private_class_method :keys, :cached_private, :cached_public
end
