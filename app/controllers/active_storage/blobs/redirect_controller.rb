class ActiveStorage::Blobs::RedirectController < ActiveStorage::BaseController
  include ActiveStorage::SetBlob

  def show
    response.set_header('Cache-Control', 'no-store')
    redirect_to @blob.url(disposition: params[:disposition]), allow_other_host: true
  end
end
