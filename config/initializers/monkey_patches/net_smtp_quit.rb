# A resposta do QUIT nao pode decidir o destino de uma mensagem que o servidor ja aceitou.
#
# Em net-smtp 0.3.4, `quit` e `getok('QUIT')` sem rescue, e `getok` levanta
# Net::SMTPServerBusy em qualquer 4xx. Quem chama `quit` e o `do_finish`, que roda no
# `ensure` do `Net::SMTP.start` com bloco -- ou seja, DEPOIS do 250 que confirmou o DATA.
# Um servidor sobrecarregado respondendo `421 Try again later` ao QUIT levanta, entao, a
# mesma excecao de um 451 no envio, mas com a mensagem ja na fila dele.
#
# Isso quebra de dois jeitos. Sem retry, um e-mail entregue e marcado como falha. Com o
# retry de Email::SendOnEmailService, que trata o 4xx como "o servidor nao ficou com a
# mensagem", a tentativa seguinte manda uma segunda copia para o cliente -- e e justamente
# essa a garantia que o retry precisa preservar para existir.
#
# A RFC 5321 (secao 4.1.1.10) e clara: a mensagem esta comprometida no 250 do fim do DATA;
# o QUIT so encerra a sessao. Engolir o erro aqui nao perde nada, porque o retorno do
# `quit` ja e descartado (`quit if ...`) e o socket e fechado no `ensure` de qualquer jeito.
require 'net/smtp'

# Timeout::Error is in the list on purpose and is easy to leave out: Net::ReadTimeout and
# Net::WriteTimeout descend from Timeout::Error -> RuntimeError, so they are caught by
# none of the other four entries. A server that takes the DATA and then stalls on QUIT is
# an ordinary way to hit exactly the case this patch exists for.
module NetSmtpQuitNeverFails
  def quit
    super
  rescue Net::SMTPError, IOError, SystemCallError, OpenSSL::SSL::SSLError, Timeout::Error => e
    Rails.logger.warn("Ignoring SMTP error on QUIT, message was already accepted: #{e.class}: #{e.message}")
    nil
  end
end

Net::SMTP.prepend(NetSmtpQuitNeverFails)
