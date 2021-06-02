class AndroidAppController < ApplicationController
  def assetlinks
    assetlinks_json = render_to_string action: 'assetlinks', layout: false
    render assetlinks_json, filename: 'assetlinks', type: 'application/json'
  end
end
