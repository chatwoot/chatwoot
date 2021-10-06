namespace :vapid_keys do
  desc 'task to generate vapid keys'
  task generate: :environment do
    keys = Webpush.generate_key
    record = InstallationConfig.find_by(name: 'VAPID_KEYS')
    if record.blank?
      InstallationConfig.create({ name: 'VAPID_KEYS', locked: false, value: { public_key: keys.public_key, private_key: keys.private_key } })
      VapidService.cache(::Redis::Alfred::PUSH_PUBLIC_KEY, keys.public_key)
      VapidService.cache(::Redis::Alfred::PUSH_PRIVATE_KEY, keys.private_key)
      puts 'created and cached vapid keys'
    else
      record.update({ value: { public_key: keys.public_key, private_key: keys.private_key } })

      VapidService.cache(::Redis::Alfred::PUSH_PUBLIC_KEY, keys.public_key)
      VapidService.cache(::Redis::Alfred::PUSH_PRIVATE_KEY, keys.private_key)
      puts 'updated and cached vapid keys'
    end
  end
end
