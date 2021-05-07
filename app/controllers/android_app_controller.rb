class AndroidAppController < ApplicationController
    def assetlinks
      assetlinks_json = render_to_string action: 'assetlinks', layout: false
      send_data assetlinks_json, filename: 'assetlinks', type: 'application/json'
    end
  end
