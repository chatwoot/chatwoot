
Checkout Integrado
Seus Checkouts
Documentação
Configurações
Documentação interativa
Veja como conectar o seu site com a InfinitePay de um jeito simples

Com essa integração, você pode gerar links de pagamento automaticamente e acompanhar as vendas em tempo real. Crie um checkout de pagamento integrado ao seu site ou sistema de forma incrivelmente simples! Nossa API é direta e descomplicada.

Nesta documentação, você entenderá o funcionamento e aprenderá, na prática, a montar seu payload. Ao lado, no menu interativo, você pode gerar um link de pagamento, testando o payload criado por você.

Antes de começar
Alguns pontos importantes que você precisa saber:

Vendedor:
É você, o dono do site de vendas
Comprador:
A pessoa que vai fazer a compra
Handle:
Sua InfiniteTag, que é seu nome de usuário no App InfinitePay (use ela sem o símbolo $ do início)
order_nsu:
É basicamente o número do pedido no seu sistema
Como funciona a integração?
O processo é bem direto: quando alguém faz um pedido no seu site, você envia os dados para a InfinitePay, recebe um link de pagamento e direciona seu cliente para finalizar a compra.

Criando o link de pagamento
Assim que seu cliente fizer um pedido, você vai enviar uma requisição POST para:

Requisição para POST
POST https://api.checkout.infinitepay.io/links
Siga a documentação, que vamos explicar passo a passo como você monta o payload necessário para geração do seu link de checkout.

Informe sua handle
Sua InfiniteTag (nome do usuário no App InfinitePay) é obrigatória para identificar sua conta. Use ela sem o símbolo $ do início.

Exemplo
"handle": "seu-handle"
Handle (Infinite Tag)
amanda-57944155-29z
Itens do Pedido
Adicione os produtos ou serviços que o cliente está comprando. É obrigatório ter pelo menos 1 item. Você precisa informar os produtos ou serviços que serão exibidos, utilizando uma lista de objetos no seguinte formato:

Exemplo
"itens": [
  {
    "quantity": 1,
    "price": 123,
    "description": "exemplo de descrição"
  }
]
Preste atenção ao valor do produto
O valor do produto deve ser colocado em centavos, então R$ 10,00 = 1000 centavos

Itens do Pedido
Descrição *
Produto de Exemplo
Quantidade *
1
Preço *
R$ 10,00
Subtotal: R$ 10.00
Total: R$ 10.00
Order NSU (Opcional)
Order NSU é um identificador que permite rastrear o link de checkout no seu sistema. Se não for informado, a InfinitePay gerará um valor aleatório automaticamente. Utilize este campo para identificar os pagamentos originados deste link de checkout.

Exemplo
"order_nsu": "order-nsu-123"
Quero definir um Order NSU personalizado
URLs de Redirecionamento (Opcional)
Para integrar o checkout ao seu site, você pode definir uma URL de redirecionamento, que será acessada pelo usuário após a conclusão do pagamento (página de sucesso). Você tem a opção de criar uma URL geral ou uma URL específica para cada link. Usaremos esta URL para redirecionar seu cliente assim que o pagamento for concluído.

Exemplo
"redirect_url": "https://seusite.com/pagamento-concluido"
Quando seu cliente finalizar o pagamento, ele volta automaticamente pro seu site (na redirect_url que você configurou). A URL vai vir com alguns parâmetros importantes:

receipt_url- Link do comprovante de pagamento
order_nsu- O número do pedido no seu sistema
slug- Código da fatura na InfinitePay
capture_method- Como foi pago ("credit_card" ou "pix")
transaction_nsu- ID único da transação
Você pode consultar o status do pagamento fazendo uma requisição:

Requisição para status de pagamento
POST https://api.checkout.infinitepay.io/payment_check
Corpo da requisição:

Exemplo
{
  "handle": "sua_infinite_tag",
  "order_nsu": "123456",
  "transaction_nsu": "UUID-que-recebeu",
  "slug": "codigo-da-fatura"
}
Resposta:

Exemplo
{
  "success": true,
  "paid": true,
  "amount": 1500,
  "paid_amount": 1510,
  "installments": 1,
  "capture_method": "pix"
}
Incluir URL de redirecionamento
Webhook URL (Opcional)
Para uma integração ainda mais robusta, você pode configurar uma webhook_url. Quando o pagamento for aprovado, a InfinitePay enviará automaticamente os dados da venda para o seu sistema por meio dessa URL. Isso garante que você seja notificado em tempo real sobre o status do pagamento, sem precisar consultar manualmente.

Exemplo
"webhook_url": "https://seusite.com/webhook-infinitepay"
Como responder ao webhook
Responda rapidamente (de preferência em menos de 1 segundo) com um desses códigos:

Tudo certo
Status: 200 OK
Algo deu errado
Status: 400 Bad Request
Dica: Se você responder com erro 400, a gente tenta enviar novamente!
O corpo da mensagem que você receberá no webhook, quando o pagamento for aprovado, terá o seguinte formato:

Exemplo
{
  "invoice_slug": "abc123",
  "amount": 1000,
  "paid_amount": 1010,
  "installments": 1,
  "capture_method": "credit_card",
  "transaction_nsu": "UUID",
  "order_nsu": "UUID-do-pedido",
  "receipt_url": "https://comprovante.com/123",
  "items": [...]
}
Incluir URL do webhook
Dados do Cliente (Opcional)
Se você já tiver o nome, e-mail e telefone do comprador, pode enviá-los para agilizar o processo. Isso facilitará o checkout, pois as informações já estarão preenchidas.

Exemplo
"customer": {
  "name": "João Silva",
  "email": "joao@email.com",
  "phone_number": "+5511999887766"
}
Incluir dados do cliente
Endereço de Entrega (Opcional)
Se o seu produto precisa ser entregue em mãos, você pode incluir o endereço.

Exemplo
"address": {
  "cep": "12345678",
  "street": "Rua das Flores",
  "neighborhood": "Centro",
  "number": "123",
  "complement": "Apto 45"
}
Incluir endereço de entrega
Dicas práticas
•
Webhook é mais eficiente que ficar consultando manualmente
•
Sempre valide se o order_nsu corresponde a um pedido real no seu sistema
•
Guarde o transaction_nsu pra futuras consultas
•
Teste bastante no ambiente de desenvolvimento antes de colocar no ar
Payload Gerado
{
  "handle": "amanda-57944155-29z",
  "items": [
    {
      "quantity": 1,
      "price": 1000,
      "description": "Produto de Exemplo"
    }
  ]
}
