namespace :vapid_keys do
  desc 'task to generate vapid keys, store in db and cache them'
  task generate: :environment do
    keys = Webpush.generate_key
    record = PushKey.where({ provider: 'vapid' })
    if record.blank?
      PushKey.create({ provider: 'vapid', public_key: keys.public_key, private_key: keys.private_key })
      puts 'created vapid keys'
    else
      record.update({ public_key: keys.public_key, private_key: keys.private_key })
      puts 'updated vapid keys'
    end
  end
end
