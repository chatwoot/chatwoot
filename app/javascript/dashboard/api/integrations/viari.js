/* global axios */
import ApiClient from '../ApiClient';

class ViariAPI extends ApiClient {
  constructor() {
    super('integrations/viari', { accountScoped: true });
  }

  getCustomer(contactId) {
    return axios.get(`${this.url}/customer`, {
      params: { contact_id: contactId },
    });
  }

  getReservas(contactId) {
    return axios.get(`${this.url}/reservas`, {
      params: { contact_id: contactId },
    });
  }

  getOrcamentos(contactId) {
    return axios.get(`${this.url}/orcamentos`, {
      params: { contact_id: contactId },
    });
  }

  getPagamentos(contactId) {
    return axios.get(`${this.url}/pagamentos`, {
      params: { contact_id: contactId },
    });
  }

  getProdutos() {
    return axios.get(`${this.url}/produtos`);
  }

  getAgendas(produtoId, dataInicio, dataFim) {
    return axios.get(`${this.url}/agendas`, {
      params: { produtoId, dataInicio, dataFim },
    });
  }

  getTarifas(produtoId, grupoTarifaId, data) {
    return axios.get(`${this.url}/tarifas`, {
      params: { produtoId, grupoTarifaId, data },
    });
  }

  getCanaisVenda() {
    return axios.get(`${this.url}/canais_venda`);
  }

  criarOrcamento(payload) {
    return axios.post(`${this.url}/create_orcamento`, payload);
  }

  getTextoWhatsapp(orcamentoId) {
    return axios.get(`${this.url}/texto_whatsapp/${orcamentoId}`);
  }
}

export default new ViariAPI();
