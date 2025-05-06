class Integrations::Shopee::Product < Integrations::Shopee::Base
  DETAIL_LIMIT = 50
  MAX_PAGE_SIZE = 20
  STATUS = 'NORMAL'.freeze

  def all(params = {})
    items = []
    query_params = {
      offset: params[:offset] || 0,
      page_size: params[:page_size] || MAX_PAGE_SIZE,
      item_status: params[:item_status] || STATUS,
      update_time_from: params[:update_time_from] || 7.days.ago.to_i,
      update_time_to: params[:update_time_to] || Time.current.to_i,
    }
    loop do
      response = fetch_page(query_params)
      has_next_page = response['has_next_page']
      next_offset = response['next_offset']
      items += response['item'] || []
      query_params[:offset] = next_offset
      break if !has_next_page
    end
    items
  end

  def detail(ids:)
    items = []
    ids.each_slice(DETAIL_LIMIT) do |ids|
      item_id_list = ids.join(',')
      items += auth_client
        .query(item_id_list: item_id_list)
        .get('/api/v2/product/get_item_base_info')
        .dig('response', 'item_list')
    end
    items
  end

  def models(item_id:)
    auth_client
      .query(item_id: item_id)
      .get('/api/v2/product/get_model_list')
      .dig('response')
  end

  private

  def fetch_page(params)
    auth_client
      .query(params)
      .get('/api/v2/product/get_item_list')
      .dig('response')
  end
end
