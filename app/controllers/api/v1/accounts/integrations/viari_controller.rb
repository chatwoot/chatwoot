class Api::V1::Accounts::Integrations::ViariController < Api::V1::Accounts::BaseController
  before_action :fetch_hook
  before_action :fetch_contact, only: %i[customer reservas orcamentos pagamentos]

  def customer
    contact = Current.account.contacts.find_by(id: params[:contact_id])
    return render json: { error: 'Contact not found' }, status: :not_found unless contact

    viari_cliente_id = contact.additional_attributes&.dig('viari_cliente_id')

    return render json: { encontrado: true, clienteId: viari_cliente_id } if viari_cliente_id

    query = {}
    query[:telefone] = contact.phone_number if contact.phone_number.present?
    query[:email] = contact.email if contact.email.present?

    response = viari_get('/api/viari/clientes/buscar', query)

    if response[:encontrado]
      persist_viari_id(contact, response.dig(:cliente, :id))
      return render json: response
    end

    body = { nome: contact.name, telefone: contact.phone_number, email: contact.email }.compact
    created = viari_post('/api/viari/clientes', body)
    persist_viari_id(contact, created.dig(:cliente, :id))
    render json: created
  end

  def reservas
    render json: viari_get("/api/viari/clientes/#{viari_cliente_id}/reservas")
  end

  def orcamentos
    render json: viari_get("/api/viari/clientes/#{viari_cliente_id}/orcamentos")
  end

  def pagamentos
    render json: viari_get("/api/viari/clientes/#{viari_cliente_id}/pagamentos")
  end

  def produtos
    render json: viari_get('/api/viari/produtos')
  end

  def agendas
    render json: viari_get('/api/viari/agendas', {
      produtoId: params[:produtoId],
      dataInicio: params[:dataInicio],
      dataFim: params[:dataFim]
    }.compact)
  end

  def tarifas
    render json: viari_get('/api/viari/tarifas/vigentes', {
      produtoId: params[:produtoId],
      grupoTarifaId: params[:grupoTarifaId],
      data: params[:data]
    }.compact)
  end

  def canais_venda
    render json: viari_get('/api/viari/canais-venda')
  end

  def create_orcamento
    render json: viari_post('/api/viari/orcamentos', params.except(:account_id, :format).permit!.to_h)
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def texto_whatsapp
    render json: viari_get("/api/viari/orcamentos/#{params[:orcamento_id]}/texto-whatsapp")
  end

  def destroy
    @hook.destroy!
    head :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'viari')
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Viari not configured' }, status: :not_found
  end

  def fetch_contact
    return if params[:contact_id].blank?

    @contact = Current.account.contacts.find_by(id: params[:contact_id])
    render json: { error: 'Contact not found' }, status: :not_found unless @contact
  end

  def viari_cliente_id
    @contact&.additional_attributes&.dig('viari_cliente_id') ||
      (render(json: { error: 'Contact not linked to Viari' }, status: :unprocessable_entity) && nil)
  end

  def persist_viari_id(contact, id)
    return unless id.present?

    attrs = (contact.additional_attributes || {}).merge('viari_cliente_id' => id)
    contact.update_columns(additional_attributes: attrs)
  end

  def api_url
    @hook.settings['api_url'].to_s.chomp('/')
  end

  def api_key
    @hook.settings['api_key'].to_s
  end

  def viari_headers
    {
      'Content-Type' => 'application/json',
      'X-Viari-Api-Key' => api_key
    }
  end

  def viari_get(path, query = {})
    uri = URI("#{api_url}#{path}")
    uri.query = URI.encode_www_form(query.reject { |_, v| v.nil? }) if query.any?
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    request = Net::HTTP::Get.new(uri.request_uri, viari_headers)
    response = http.request(request)
    JSON.parse(response.body, symbolize_names: true)
  rescue StandardError => e
    raise "Viari API error: #{e.message}"
  end

  def viari_post(path, body = {})
    uri = URI("#{api_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    request = Net::HTTP::Post.new(uri.path, viari_headers)
    request.body = body.to_json
    response = http.request(request)
    JSON.parse(response.body, symbolize_names: true)
  rescue StandardError => e
    raise "Viari API error: #{e.message}"
  end
end
