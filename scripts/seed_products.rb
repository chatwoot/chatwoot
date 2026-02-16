# frozen_string_literal: true

# Script to create test products for Account ID 1
# Usage: bundle exec rails runner scripts/seed_products.rb

PRODUCTS = [
  {
    title_en: 'Wireless Bluetooth Headphones',
    title_ar: 'سماعات بلوتوث لاسلكية',
    description_en: 'Premium noise-canceling wireless headphones with 30-hour battery life and crystal-clear sound quality.',
    description_ar: 'سماعات لاسلكية فاخرة مع إلغاء الضوضاء وبطارية تدوم 30 ساعة وجودة صوت عالية.',
    price: 79.99
  },
  {
    title_en: 'Premium Coffee Beans',
    title_ar: 'حبوب قهوة فاخرة',
    description_en: 'Single-origin Arabica coffee beans, freshly roasted with rich chocolate and nutty notes.',
    description_ar: 'حبوب قهوة أرابيكا أحادية المصدر، محمصة طازجة بنكهات الشوكولاتة والمكسرات.',
    price: 24.99
  },
  {
    title_en: 'Leather Messenger Bag',
    title_ar: 'حقيبة جلدية',
    description_en: 'Handcrafted genuine leather messenger bag with multiple compartments, perfect for work or travel.',
    description_ar: 'حقيبة جلدية أصلية مصنوعة يدوياً مع عدة جيوب، مثالية للعمل أو السفر.',
    price: 149.99
  },
  {
    title_en: 'Smart Watch Pro',
    title_ar: 'ساعة ذكية برو',
    description_en: 'Advanced fitness tracking, heart rate monitoring, GPS, and 7-day battery life in a sleek design.',
    description_ar: 'تتبع متقدم للياقة البدنية ومراقبة نبضات القلب ونظام GPS وبطارية تدوم 7 أيام بتصميم أنيق.',
    price: 299.99
  },
  {
    title_en: 'Organic Green Tea',
    title_ar: 'شاي أخضر عضوي',
    description_en: 'Premium organic green tea leaves from Japan, known for their delicate flavor and health benefits.',
    description_ar: 'أوراق شاي أخضر عضوي فاخر من اليابان، معروف بنكهته الرقيقة وفوائده الصحية.',
    price: 15.99
  },
  {
    title_en: 'Cotton T-Shirt',
    title_ar: 'قميص قطني',
    description_en: '100% organic cotton t-shirt, soft and breathable with a comfortable fit for everyday wear.',
    description_ar: 'قميص من القطن العضوي 100%، ناعم ومريح للارتداء اليومي.',
    price: 29.99
  },
  {
    title_en: 'Portable Charger',
    title_ar: 'شاحن متنقل',
    description_en: '20000mAh portable power bank with fast charging, dual USB ports, and compact design.',
    description_ar: 'بطارية متنقلة بسعة 20000 مللي أمبير مع شحن سريع ومنفذين USB وتصميم مدمج.',
    price: 45.99
  },
  {
    title_en: 'Running Shoes',
    title_ar: 'أحذية رياضية',
    description_en: 'Lightweight running shoes with responsive cushioning and breathable mesh upper for maximum comfort.',
    description_ar: 'أحذية جري خفيفة الوزن مع توسيد متجاوب وجزء علوي شبكي للراحة القصوى.',
    price: 119.99
  },
  {
    title_en: 'Desk Lamp LED',
    title_ar: 'مصباح مكتب LED',
    description_en: 'Modern LED desk lamp with adjustable brightness, color temperature control, and USB charging port.',
    description_ar: 'مصباح مكتب LED حديث مع سطوع قابل للتعديل والتحكم في درجة حرارة اللون ومنفذ شحن USB.',
    price: 39.99
  },
  {
    title_en: 'Stainless Steel Water Bottle',
    title_ar: 'زجاجة مياه ستانلس ستيل',
    description_en: 'Double-wall insulated water bottle keeps drinks cold for 24 hours or hot for 12 hours.',
    description_ar: 'زجاجة مياه معزولة بجدار مزدوج تحافظ على المشروبات باردة لمدة 24 ساعة أو ساخنة لمدة 12 ساعة.',
    price: 19.99
  }
].freeze

account = Account.find(1)
puts "Creating products for Account: #{account.name} (ID: #{account.id})"
puts '-' * 50

created_count = 0

PRODUCTS.each do |product_data|
  product = account.products.find_or_initialize_by(title_en: product_data[:title_en])

  if product.new_record?
    product.assign_attributes(product_data)
    if product.save
      created_count += 1
      puts "Created: #{product.title_en} - $#{product.price}"
    else
      puts "Failed: #{product.title_en} - #{product.errors.full_messages.join(', ')}"
    end
  else
    puts "Skipped (exists): #{product.title_en}"
  end
end

puts '-' * 50
puts "Done! Created #{created_count} new products."
puts "Total products for account: #{account.products.count}"
