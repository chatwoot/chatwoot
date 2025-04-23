FactoryBot.define do
  factory :shopee_order_item, class: 'Shopee::OrderItem' do
    order_id { 1 }
    item_id { "" }
    item_name { "MyString" }
    item_sku { "MyString" }
    main_item { false }
    model_quantity_purchased { 1 }
    model_original_price { 1.5 }
    model_discounted_price { 1.5 }
    meta_data { "MyText" }
  end
end
