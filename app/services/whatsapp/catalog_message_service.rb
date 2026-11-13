class Whatsapp::CatalogMessageService
  pattr_initialize [:conversation!, :sender!, :params!]

  def perform
    Whatsapp::CatalogMessagePayloadBuilder.new(body: params[:content], catalog: catalog).perform

    Messages::MessageBuilder.new(sender, conversation, content: params[:content], content_attributes: { whatsapp_catalog: catalog }).perform
  end

  private

  def catalog
    @catalog ||= {
      'kind' => params[:kind],
      'catalog_id' => params[:catalog_id],
      'header' => params[:header],
      'footer' => params[:footer],
      'items' => Array(params[:products])
    }
  end
end
