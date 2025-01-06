class Enterprise::Webhooks::FirecrawlController < ActionController::API
  def process_payload
    if crawl_page_event?
      Captain::Tools::FirecrawlParserJob.perform_later(
        assistant_id: params[:assistant_id], payload: params[:data]
      )
    end
    head :ok
  end

  private

  def crawl_page_event?
    params[:type] == 'crawl.page'
  end
end
