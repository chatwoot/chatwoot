class VapidService
  def self.public_key
    vapid_keys['public_key']
  end

  def self.private_key
    vapid_keys['private_key']
  end

  def self.vapid_keys
    config = GlobalConfig.get('VAPID_KEYS')
    return config['VAPID_KEYS'] if config['VAPID_KEYS'].present?

    # keys don't exist in the database. so let's generate and save them
    keys = Webpush.generate_key
    # TODO: remove the logic on environment variables when we completely deprecate
    public_key = ENV['VAPID_PUBLIC_KEY'] || keys.public_key
    private_key = ENV['VAPID_PRIVATE_KEY'] || keys.private_key

    i = InstallationConfig.where(name: 'VAPID_KEYS').first_or_create(value: { public_key: public_key, private_key: private_key })
    i.value
  end

  private_class_method :vapid_keys
end
