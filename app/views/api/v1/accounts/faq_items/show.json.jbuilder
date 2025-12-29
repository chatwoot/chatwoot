json.id @faq_item.id
json.faq_category_id @faq_item.faq_category_id
json.position @faq_item.position
json.is_visible @faq_item.is_visible
json.translations @faq_item.translations
json.primary_question @faq_item.question('es')
json.primary_answer @faq_item.answer('es')
json.created_at @faq_item.created_at
json.updated_at @faq_item.updated_at

if @faq_item.faq_category.present?
  json.category do
    json.id @faq_item.faq_category.id
    json.name @faq_item.faq_category.name
  end
end
