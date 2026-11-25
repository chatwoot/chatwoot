# Teste de integracao do patch do QUIT contra um SMTP de verdade.
#
# Os specs fazem stub de `getok`, entao provam que o rescue pega -- mas nao provam a
# afirmacao que sustenta a PR inteira: que o `do_finish` roda no `ensure` do
# `Net::SMTP.start` e que a excecao dele SUBSTITUI o retorno bem-sucedido do envio.
# Isso depende do fluxo interno do net-smtp, entao so um servidor real mostra.
#
# O servidor falso ACEITA a mensagem (250 depois do DATA) e so entao maltrata o QUIT.
#
#   bundle exec ruby scripts/net_smtp_quit_integracao.rb          # sem o patch
#   PATCH=1 bundle exec ruby scripts/net_smtp_quit_integracao.rb  # com o patch
#
# Resultado em 07/09/2026, net-smtp 0.3.4. Nos tres casos o servidor ficou com a mensagem:
#
#   cenario                          sem o patch            com o patch
#   QUIT responde 221 (normal)       entregue               entregue
#   QUIT responde 421 (sobrecarga)   Net::SMTPServerBusy    entregue
#   QUIT nao responde (trava)        Net::ReadTimeout       entregue
#
# Rodado tambem contra net-smtp 0.5.1, com resultado IDENTICO: o upstream nao corrigiu o QUIT,
# entao o patch continua necessario depois de um bump do gem. Vale reconferir aqui a cada bump.
#
# Fica fora de spec/ de proposito, e nao so por flake: `rails_helper.rb:34` faz require de
# TODO spec/support/**/*.rb, entao daqui um script executavel rodaria -- abrindo socket e
# dormindo -- a cada execucao da suite. E teste de rodar a mao ao mexer no patch ou ao subir
# a versao do net-smtp.
require 'net/smtp'
require 'socket'
require 'openssl'
require 'timeout'

PORTA = 20_025
CASOS = [
  ['QUIT responde 221 (normal)', '221 Bye'],
  ['QUIT responde 421 (sobrecarga)', '421 4.7.0 Try again later'],
  ['QUIT nao responde (trava)', :silencio]
].freeze

# Devolve :fim quando a conversa acabou, :ok para seguir. `aceitou` vira true quando o
# servidor confirma o DATA com 250 -- e o ponto a partir do qual a mensagem ja e dele.
def responde(conn, comando, resposta_quit, estado)
  case comando
  when /\AEHLO/i then conn.print "250-fake\r\n250 SIZE 10485760\r\n"
  when /\AHELO/i then conn.print "250 fake\r\n"
  when /\ADATA/i then recebe_corpo(conn, estado)
  when /\AQUIT/i then return encerra(conn, resposta_quit)
  else conn.print "250 OK\r\n"
  end
  :ok
end

def recebe_corpo(conn, estado)
  conn.print "354 End data with <CR><LF>.<CR><LF>\r\n"
  loop do
    linha = conn.gets
    break if linha.nil? || linha.chomp == '.'
  end
  estado[:aceitou] = true
  conn.print "250 2.0.0 OK: queued as FAKE123\r\n"
end

def encerra(conn, resposta_quit)
  if resposta_quit == :silencio
    sleep 5 # nao responde: o cliente estoura em Net::ReadTimeout lendo a resposta do QUIT
  else
    conn.print "#{resposta_quit}\r\n"
  end
  :fim
end

def sobe_servidor(porta, resposta_quit)
  pronto = Queue.new
  thread = Thread.new do
    servidor = TCPServer.new('127.0.0.1', porta)
    pronto << :ok
    conn = servidor.accept
    estado = { aceitou: false }
    conn.print "220 fake ESMTP\r\n"
    loop do
      linha = conn.gets
      break if linha.nil?
      break if responde(conn, linha.strip, resposta_quit, estado) == :fim
    end
    fecha(conn, servidor)
    estado[:aceitou]
  end
  pronto.pop # so devolve depois que a porta esta escutando, senao o envio corre antes
  thread
end

def fecha(*ios)
  ios.each do |io|
    io.close
  rescue StandardError
    nil
  end
end

def envia(porta)
  smtp = Net::SMTP.new('127.0.0.1', porta)
  smtp.read_timeout = 2
  smtp.open_timeout = 2
  smtp.start('teste') do |s|
    s.send_message("Subject: teste\r\n\r\ncorpo\r\n", 'de@example.com', 'para@example.com')
  end
  'entregue'
end

def roda(resposta_quit)
  servidor = sobe_servidor(PORTA, resposta_quit)
  visto = begin
    envia(PORTA)
  rescue StandardError => e
    "#{e.class}: #{e.message.to_s.lines.first.to_s.strip}"
  end
  aceitou = begin
    Timeout.timeout(8) { servidor.value }
  rescue StandardError
    :desconhecido
  end
  [aceitou, visto]
end

def carrega_patch
  # O initializer usa Rails.logger, e num script solto nao ha Rails: damos um duble.
  unless defined?(Rails)
    require 'logger'
    Object.const_set(:Rails, Module.new do
      def self.logger
        @logger ||= Logger.new(IO::NULL)
      end
    end)
  end
  load File.expand_path('../config/initializers/monkey_patches/net_smtp_quit.rb', __dir__)
end

com_patch = ENV['PATCH'] == '1'
carrega_patch if com_patch

puts "net-smtp #{Gem.loaded_specs['net-smtp']&.version}  |  patch do QUIT: #{com_patch ? 'CARREGADO' : 'ausente'}"
puts '-' * 92
puts "#{'cenario'.ljust(34)}#{'servidor'.ljust(18)}o que o cliente viu"
puts '-' * 92
CASOS.each do |rotulo, resposta|
  aceitou, visto = roda(resposta)
  situacao = aceitou == true ? 'ACEITOU a msg' : "aceitou=#{aceitou}"
  puts "#{rotulo.ljust(34)}#{situacao.ljust(18)}#{visto}"
end
