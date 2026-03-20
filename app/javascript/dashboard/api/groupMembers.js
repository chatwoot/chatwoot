/* global axios */
import ApiClient from './ApiClient';

class GroupMembersAPI extends ApiClient {
  constructor() {
    super('contacts', { accountScoped: true });
  }

  getGroupMembers(contactId, page = 1) {
    return axios.get(`${this.url}/${contactId}/group_members`, {
      params: { page },
    });
  }

  syncGroup(contactId) {
    return axios.post(`${this.url}/${contactId}/sync_group`);
  }

  createGroup(params) {
    return axios.post(`${this.baseUrl()}/groups`, params);
  }

  updateGroupMetadata(contactId, params) {
    return axios.patch(`${this.url}/${contactId}/group_metadata`, params);
  }

  addMembers(contactId, participants) {
    return axios.post(`${this.url}/${contactId}/group_members`, {
      participants,
    });
  }

  removeMembers(contactId, memberId) {
    return axios.delete(`${this.url}/${contactId}/group_members/${memberId}`);
  }

  updateMemberRole(contactId, memberId, role) {
    return axios.patch(`${this.url}/${contactId}/group_members/${memberId}`, {
      role,
    });
  }

  getInviteLink(contactId) {
    return axios.get(`${this.url}/${contactId}/group_invite`);
  }

  revokeInviteLink(contactId) {
    return axios.post(`${this.url}/${contactId}/group_invite/revoke`);
  }

  getPendingRequests(contactId) {
    return axios.get(`${this.url}/${contactId}/group_join_requests`);
  }

  handleJoinRequest(contactId, params) {
    return axios.post(
      `${this.url}/${contactId}/group_join_requests/handle`,
      params
    );
  }

  leaveGroup(contactId) {
    return axios.post(`${this.url}/${contactId}/group_admin/leave`);
  }

  updateGroupProperty(contactId, params) {
    return axios.patch(`${this.url}/${contactId}/group_admin`, params);
  }
}

export default new GroupMembersAPI();
