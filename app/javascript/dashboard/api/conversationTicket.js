/* global axios */
import ApiClient from './ApiClient';

// A conversation carries at most one ticket, so the case endpoints hang off the
// conversation as a singular resource rather than off /tickets.
class ConversationTicketAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  ticketUrl(conversationId) {
    return `${this.url}/${conversationId}/ticket`;
  }

  getTicket(conversationId) {
    return axios.get(this.ticketUrl(conversationId));
  }

  createTicket(conversationId, ticket) {
    return axios.post(this.ticketUrl(conversationId), ticket);
  }

  updateTicket(conversationId, ticket) {
    return axios.patch(this.ticketUrl(conversationId), ticket);
  }

  createTask(conversationId, task) {
    return axios.post(`${this.ticketUrl(conversationId)}/tasks`, task);
  }

  updateTask(conversationId, taskId, task) {
    return axios.patch(
      `${this.ticketUrl(conversationId)}/tasks/${taskId}`,
      task
    );
  }

  deleteTask(conversationId, taskId) {
    return axios.delete(`${this.ticketUrl(conversationId)}/tasks/${taskId}`);
  }
}

export default new ConversationTicketAPI();
