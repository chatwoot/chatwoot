require 'httparty'
require 'json'
require 'digest'

class Duitku::DuitkuService
  include HTTParty
  base_uri 'https://sandbox.duitku.com/webapi'

  def initialize(amount, payment_method, customer_name, customer_email, customer_phone)
    @merchant_code = ENV['DUITKU_MERCHANT_CODE']
    @merchant_key = ENV['DUITKU_MERCHANT_KEY']
    @amount = amount
    @payment_method = payment_method
    @customer_name = customer_name
    @customer_email = customer_email
    @customer_phone = customer_phone
  end

  def create_transaction
    endpoint = '/api/merchant/v2/inquiry'
    reference = "INV-#{SecureRandom.hex(5)}"
    signature = generate_signature(reference, @amount)

    payload = {
      merchantCode: @merchant_code,
      paymentAmount: @amount,
      paymentMethod: @payment_method,
      merchantOrderId: reference,
      productDetails: "Chatwoot Subscription",
      customerVaName: @customer_name,
      email: @customer_email,
      phoneNumber: @customer_phone,
      callbackUrl: "#{ENV['CHATWOOT_BASE_URL']}/duitku/callback",
      returnUrl: "#{ENV['CHATWOOT_BASE_URL']}/duitku/success",
      signature: signature,
      expiryPeriod: 60
    }

    response = self.class.post(endpoint, body: payload.to_json, headers: headers)
    JSON.parse(response.body)
  end

  private

  def generate_signature(reference, amount)
    Digest::MD5.hexdigest(@merchant_code + reference + amount.to_s + @merchant_key)
  end

  def headers
    { 'Content-Type' => 'application/json' }
  end
end