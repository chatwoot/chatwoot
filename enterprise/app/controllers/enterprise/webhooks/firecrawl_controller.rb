class Enterprise::Webhooks::FirecrawlController < ActionController::API
  def process_payload
    if crawl_page_event?
      Captain::Tools::FirecrawlParserJob.perform_later(
        assistant_id: permitted_params[:assistant_id],
        payload: permitted_params[:data]
      )
    end
    head :ok
  end

  private

  def crawl_page_event?
    permitted_params[:type] == 'crawl.page'
  end

  def permitted_params
    params.permit(
      :type,
      :assistant_id,
      :success,
      :id,
      :metadata,
      :format,
      :firecrawl,
      { data: {} }
    )
  end
end
