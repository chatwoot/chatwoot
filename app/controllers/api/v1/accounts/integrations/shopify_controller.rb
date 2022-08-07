class Api::V1::Accounts::Integrations::ShopifyController < Api::V1::Accounts::BaseController
  before_action :fetch_shopify, only: [:update, :destroy]
  before_action :check_authorization?

  def index
    @shopify = Current.account.shopify_integrations
    render json: @shopify
  end

  def create
    @shopify = Current.account.shopify_integrations.new(shopify_params)
    @shopify.save!
    render json: @shopify
  end

  def update
    @shopify.update!(shopify_params)
  end

  def destroy
    @shopify.destroy!
    head :ok
  end

  def make_refund
    shopify_customer = Integrations::ShopifyCustomer.find_by(contact_id: params[:contact_id])
    shopify_account = Integrations::Shopify.find_by(id: shopify_customer.shopify_account_id)
    error = false
    if !shopify_account.nil?
      begin
        refund = Hash.new
        refund["refund"] = Hash.new
        refund["refund"]["shipping"] = Hash.new
        refund["refund"]["shipping"]["full_refund"] = params[:shipping_refund_status]
        refund["refund"]["shipping"]["amount"] = params[:shipping_refund_amount]
        item = Hash.new
        item["line_item_id"] = params[:item_id]
        item["quantity"] = params[:refund_quantity]
        item["restock_type"] = params[:restock_type]
        refund["refund"]["refund_line_items"] = Array.new(1){
          item
        }
        response = RestClient.post 'https://'+shopify_account.account_name+'/admin/api/2022-04/orders/'+params[:order_id].to_s+'/refunds/calculate.json',
        refund.to_json,
        {
          content_type: :json,
          accept: :json,
          "X-Shopify-Access-Token": shopify_account.access_token
        }
      rescue RestClient::ExceptionWithResponse => err
        response = err.response.body
        error = true
      end
      if error
        return render json: response, :status => :bad_request
      end
      # Calculate refund
      refund = Hash.new
      refund["refund"] = Hash.new
      refund["refund"]["shipping"] = Hash.new
      refund["refund"]["shipping"]["full_refund"] = params[:shipping_refund_status]
      refund["refund"]["shipping"]["amount"] = params[:shipping_refund_amount]
      refund["refund"]["transactions"] = JSON.parse(response, object_class: Hash)["refund"]["transactions"]

      begin
        response = RestClient.post 'https://'+shopify_account.account_name+'/admin/api/2022-04/orders/'+params[:order_id].to_s+'/refunds.json',
        refund.to_json,
        {
          content_type: :json,
          accept: :json,
          "X-Shopify-Access-Token": shopify_account.access_token
        }
      rescue RestClient::ExceptionWithResponse => err
        response = err.response.body
      end

      render json: response
    else
      render json: {"message"=>"Invalid shopify account"}
    end
  end

  private

  def shopify_params
    params.require(:shopify).permit(:api_key, :api_secret, :account_name, :redirect_url)
  end

  def fetch_shopify
    @shopify = Current.account.shopify_integrations.find(params[:id])
  end

  def check_authorization?
    authorize(:shopify)
  end
end
