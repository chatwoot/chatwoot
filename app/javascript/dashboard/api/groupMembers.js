/* global axios */
import ApiClient from './ApiClient';

/**
 * Every call here carries the inbox the action is for.
 *
 * A group contact is account-scoped, so one WhatsApp group can belong to two inboxes of
 * the same account. Without the inbox the server resolved the channel by taking whichever
 * contact inbox came first, which could be a different number from the one the agent has
 * open: the panel decided what they may do from one inbox and the server acted as
 * another. The server refuses an inbox the group is not in, and refuses to guess when a
 * group is in two and none is named.
 */
class GroupMembersAPI extends ApiClient {
  constructor() {
    super('contacts', { accountScoped: true });
  }

  getGroupMembers(contactId, inboxId, page = 1) {
    return axios.get(`${this.url}/${contactId}/group_members`, {
      params: { page, inbox_id: inboxId },
    });
  }

  syncGroup(contactId, inboxId) {
    return axios.post(`${this.url}/${contactId}/sync_group`, {
      inbox_id: inboxId,
    });
  }

  createGroup(params) {
    return axios.post(`${this.baseUrl()}/groups`, params);
  }

  // The avatar upload sends FormData, and spreading one copies no entry at all: the
  // request would carry the inbox and nothing else, and the server would answer 200 to
  // an upload with no file in it.
  updateGroupMetadata(contactId, params, inboxId) {
    const url = `${this.url}/${contactId}/group_metadata`;

    if (params instanceof FormData) {
      // A missing inbox is left out rather than appended: FormData stringifies, so it
      // would reach the server as the literal "undefined" and fail the lookup.
      if (inboxId != null) params.append('inbox_id', inboxId);
      return axios.patch(url, params);
    }

    return axios.patch(url, { ...params, inbox_id: inboxId });
  }

  addMembers(contactId, participants, inboxId) {
    return axios.post(`${this.url}/${contactId}/group_members`, {
      participants,
      inbox_id: inboxId,
    });
  }

  removeMembers(contactId, memberId, inboxId) {
    return axios.delete(`${this.url}/${contactId}/group_members/${memberId}`, {
      params: { inbox_id: inboxId },
    });
  }

  updateMemberRole(contactId, memberId, role, inboxId) {
    return axios.patch(`${this.url}/${contactId}/group_members/${memberId}`, {
      role,
      inbox_id: inboxId,
    });
  }

  getInviteLink(contactId, inboxId) {
    return axios.get(`${this.url}/${contactId}/group_invite`, {
      params: { inbox_id: inboxId },
    });
  }

  revokeInviteLink(contactId, inboxId) {
    return axios.post(`${this.url}/${contactId}/group_invite/revoke`, {
      inbox_id: inboxId,
    });
  }

  handleJoinRequest(contactId, params, inboxId) {
    return axios.post(`${this.url}/${contactId}/group_join_requests/handle`, {
      ...params,
      inbox_id: inboxId,
    });
  }

  leaveGroup(contactId, inboxId) {
    return axios.post(`${this.url}/${contactId}/group_admin/leave`, {
      inbox_id: inboxId,
    });
  }

  updateGroupProperty(contactId, params, inboxId) {
    return axios.patch(`${this.url}/${contactId}/group_admin`, {
      ...params,
      inbox_id: inboxId,
    });
  }
}

export default new GroupMembersAPI();
