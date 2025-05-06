json.payload do
  json.array! @vouchers do |voucher|
    json.partial! 'api/v1/models/shopee/voucher', voucher: voucher
  end
end
