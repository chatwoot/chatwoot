# scripts/create_whatsapp_template.rb
#
# Crea una plantilla de WhatsApp usando las credenciales del inbox indicado.
#
# Uso:
#   rails runner scripts/create_whatsapp_template.rb -- \
#     --inbox_id=<ID> \
#     --name=<nombre_plantilla> \
#     --language=<codigo_idioma> \
#     --body="Hola {{1}}, tu turno es el {{2}}" \
#     [--category=MARKETING|UTILITY|AUTHENTICATION] \
#     [--header="Texto del encabezado"] \
#     [--footer="Texto del pie"]
#
# Ejemplos de variables: {{1}}, {{2}} (numeradas, como exige Meta)
# Ejemplos de idioma:    es, en, pt_BR, fr, de
# Categoría por defecto: UTILITY
#
# Nota: el nombre de la plantilla debe ser en minúsculas y guiones bajos.

require 'httparty'
require 'optparse'

# ---------------------------------------------------------------------------
# Parseo de argumentos
# ---------------------------------------------------------------------------
options = {}

OptionParser.new do |opts|
  opts.banner = 'Uso: rails runner scripts/create_whatsapp_template.rb -- [opciones]'

  opts.on('--inbox_id=ID', Integer, 'ID del inbox de WhatsApp (requerido)') { |v| options[:inbox_id] = v }
  opts.on('--name=NAME', String, 'Nombre de la plantilla (requerido, solo letras minúsculas y guiones bajos)') { |v| options[:name] = v }
  opts.on('--language=LANG', String, 'Código de idioma (default: es_MX, ej: en, pt_BR)') { |v| options[:language] = v }
  opts.on('--body=TEXT', String, 'Texto del cuerpo con variables {{1}}, {{2}}... (requerido)') { |v| options[:body] = v }
  opts.on('--category=CAT', String, 'Categoría: MARKETING, UTILITY o AUTHENTICATION (default: UTILITY)') { |v| options[:category] = v }
  opts.on('--header=TEXT', String, 'Texto del encabezado (opcional)') { |v| options[:header] = v }
  opts.on('--footer=TEXT', String, 'Texto del pie de página (opcional)') { |v| options[:footer] = v }
  opts.on('-h', '--help', 'Muestra esta ayuda') { puts opts; exit }
end.parse!(ARGV.dup.tap { |a| a.shift while a.first && !a.first.start_with?('--') })

# ---------------------------------------------------------------------------
# Validaciones
# ---------------------------------------------------------------------------
options[:language] ||= 'es_MX'

missing = %i[inbox_id name body].reject { |k| options[k] }
if missing.any?
  puts "Error: faltan parámetros requeridos: #{missing.map { |k| "--#{k}" }.join(', ')}"
  exit 1
end

unless options[:name].match?(/\A[a-z0-9_]+\z/)
  puts "Error: el nombre de la plantilla solo puede contener letras minúsculas, números y guiones bajos."
  exit 1
end

valid_categories = %w[MARKETING UTILITY AUTHENTICATION]
category = (options[:category] || 'UTILITY').upcase
unless valid_categories.include?(category)
  puts "Error: categoría inválida '#{options[:category]}'. Usa: #{valid_categories.join(', ')}"
  exit 1
end

# ---------------------------------------------------------------------------
# Búsqueda del inbox y credenciales
# ---------------------------------------------------------------------------
inbox = Inbox.find_by(id: options[:inbox_id])

unless inbox
  puts "Error: no se encontró el inbox con id=#{options[:inbox_id]}"
  exit 1
end

unless inbox.channel_type == 'Channel::Whatsapp'
  puts "Error: el inbox ##{inbox.id} ('#{inbox.name}') no es de tipo WhatsApp (es #{inbox.channel_type})"
  exit 1
end

channel = inbox.channel

unless %w[whatsapp_cloud whatsapp_light].include?(channel.provider)
  puts "Error: el proveedor '#{channel.provider}' no soporta la API de plantillas de Meta (solo whatsapp_cloud / whatsapp_light)."
  exit 1
end

api_key             = channel.provider_config['api_key']
business_account_id = channel.provider_config['business_account_id']
phone_number_id     = channel.provider_config['phone_number_id']

if api_key.blank? || business_account_id.blank?
  puts "Error: el inbox no tiene credenciales completas (api_key o business_account_id vacíos)."
  exit 1
end

puts ""
puts "=== Inbox encontrado ==="
puts "  ID:             #{inbox.id}"
puts "  Nombre:         #{inbox.name}"
puts "  Teléfono:       #{channel.phone_number}"
puts "  Proveedor:      #{channel.provider}"
puts "  WABA ID:        #{business_account_id}"
puts "  Phone Number ID:#{phone_number_id}"
puts ""

# ---------------------------------------------------------------------------
# Construcción del payload
# ---------------------------------------------------------------------------
api_version  = 'v20.0'
base_url     = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
endpoint     = "#{base_url}/#{api_version}/#{business_account_id}/message_templates"

components = []

components << { type: 'HEADER', format: 'TEXT', text: options[:header] } if options[:header].present?

# Detecta variables en el body para construir los ejemplos requeridos por Meta
body_text    = options[:body]
variable_matches = body_text.scan(/\{\{(\d+)\}\}/).flatten.uniq.map(&:to_i).sort
body_component   = { type: 'BODY', text: body_text }

if variable_matches.any?
  body_component[:example] = {
    body_text: [variable_matches.map { |i| "ejemplo_#{i}" }]
  }
end

components << body_component
components << { type: 'FOOTER', text: options[:footer] } if options[:footer].present?

payload = {
  name:       options[:name],
  language:   options[:language],
  category:   category,
  components: components
}

headers = {
  'Authorization' => "Bearer #{api_key}",
  'Content-Type'  => 'application/json'
}

# ---------------------------------------------------------------------------
# Envío de la solicitud
# ---------------------------------------------------------------------------
puts "=== Enviando solicitud a WhatsApp Cloud API ==="
puts "  Endpoint:   #{endpoint}"
puts "  Plantilla:  #{options[:name]}"
puts "  Idioma:     #{options[:language]}"
puts "  Categoría:  #{category}"
puts "  Cuerpo:     #{body_text}"
puts "  Componentes: #{components.size}"
puts ""

response = HTTParty.post(endpoint, headers: headers, body: payload.to_json)
parsed   = response.parsed_response

puts "=== Respuesta (HTTP #{response.code}) ==="

if response.success?
  puts "  Estado:      CREADA EXITOSAMENTE"
  puts "  Template ID: #{parsed['id']}"
  puts "  Nombre:      #{parsed['name'] || options[:name]}"
  puts "  Categoría:   #{parsed['category'] || category}"
  puts "  Estado Meta: #{parsed['status'] || 'PENDING'}"
  puts ""
  puts "La plantilla fue enviada a Meta para revisión."
  puts "Puede tardar hasta 24 h en ser aprobada (estado: PENDING → APPROVED)."
else
  puts "  ERROR al crear la plantilla:"
  if parsed['error']
    puts "  Código:   #{parsed['error']['code']}"
    puts "  Mensaje:  #{parsed['error']['message']}"
    puts "  Subtipo:  #{parsed['error']['error_subcode']}" if parsed['error']['error_subcode']
    puts "  FbTrace:  #{parsed['error']['fbtrace_id']}"
  else
    puts "  Body:     #{response.body}"
  end
  exit 1
end
