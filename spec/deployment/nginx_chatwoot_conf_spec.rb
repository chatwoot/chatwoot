## Empty Upgrade must map to an empty Connection so nginx omits the header and
## upstream keepalive can reuse the Puma socket. A real Upgrade still maps to
## "upgrade" for ActionCable at /cable.
require 'rails_helper'

RSpec.context 'with valid nginx_chatwoot.conf' do
  it 'clears Connection on non-upgrade requests so upstream keepalive works' do
    file = Rails.root.join('deployment/nginx_chatwoot.conf')
    conf = File.read(file)

    expect(conf).to include(<<~MAP)
      map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      "";
      }
    MAP
    expect(conf).to include('keepalive 32;')
    expect(conf).to include('proxy_http_version 1.1;')
    expect(conf).to include('proxy_set_header Upgrade $http_upgrade;')
    expect(conf).to include('proxy_set_header Connection $connection_upgrade;')
    expect(conf).not_to match(/proxy_set_header\s+Connection\s+["']?close/)
  end
end
