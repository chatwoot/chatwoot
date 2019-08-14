require 'carrierwave/storage/fog'

CarrierWave.configure do |config|
    config.storage = :fog
    config.fog_provider = 'fog/aws' # required

    config.fog_credentials = {
        provider: 'AWS',
        aws_access_key_id: 'IAHIHAUVZKNOVTFZGWVT', # required
        aws_secret_access_key: 'TNah2bj4p7o5pKbFIqeVAma32pnnXER1r5m7LZvXXFM', # required
        region: 'sfo2', # required
        endpoint: 'https://sfo2.digitaloceanspaces.com' # required
    }

    config.storage = :fog
    config.fog_directory = 'chatwoot' # required
    # config.fog_public = false # optional, defaults to true
    config.asset_host = "https://chatwoot.sfo2.digitaloceanspaces.com"
    config.fog_attributes = { 'Cache-Control' => 'max-age=315576000' } # optional, defaults to {}
end
