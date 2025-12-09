json.id product.id
json.title_en product.title_en
json.title_ar product.title_ar
json.description_en product.description_en
json.description_ar product.description_ar
json.price product.price.to_f
json.currency product.currency
json.image_url product.image_url if product.image.attached?
json.created_at product.created_at
json.updated_at product.updated_at
