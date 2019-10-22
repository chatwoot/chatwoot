Pusher.app_id = ENV['pusher_app_id']
Pusher.key    = ENV['pusher_key']
Pusher.secret = ENV['pusher_secret']
Pusher.encrypted = true
Pusher.logger = Rails.logger
Pusher.cluster = ENV['pusher_cluster']
