json.payload do
  json.array! @transactions do |transaction|
    json.id transaction.id
    json.product transaction.product
    json.po_date transaction.po_date
    json.po_value transaction.po_value
    json.po_note transaction.po_note
    json.custom_attributes transaction.custom_attributes
    json.created_at transaction.created_at
    json.updated_at transaction.updated_at
  end
end
