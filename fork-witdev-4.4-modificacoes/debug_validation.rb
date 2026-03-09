#!/usr/bin/env ruby

# Carregar ambiente Rails
ENV['RAILS_ENV'] ||= 'development'
require_relative 'config/environment'

puts '🔍 Investigando erro de validação...'

file_path = '/tmp/love.webp'

uploaded_file = ActionDispatch::Http::UploadedFile.new(
  tempfile: File.open(file_path, 'rb'),
  filename: 'love_test.webp', 
  type: 'image/webp'
)

puts '📋 Validação StickerUploader:'
uploader = StickerUploader.new(
  file: uploaded_file,
  pack_name: 'test_pack'
)

if uploader.valid?
  puts '✅ StickerUploader: VÁLIDO'
else
  puts '❌ StickerUploader: INVÁLIDO'
  uploader.errors.full_messages.each { |msg| puts "   • #{msg}" }
end

# Testar Account
account = Account.find(3)
puts "📋 Account #{account.id}: #{account.name}"

# Verificar se StickerService existe
if defined?(StickerService)
  puts '✅ StickerService: Encontrado'
else
  puts '❌ StickerService: NÃO ENCONTRADO'
  
  # Listar services disponíveis
  puts '📂 Services disponíveis:'
  Dir['/app/app/services/*_service.rb'].each do |f|
    service_name = File.basename(f, '.rb').camelize
    puts "   • #{service_name}"
  end
end

puts '🏁 Investigação finalizada!'
