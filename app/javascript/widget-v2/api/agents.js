import { client } from './client';

// Shared with the v1 widget API; returns inbox members with availability_status.
export const fetchInboxMembers = () =>
  client.get('/api/v1/widget/inbox_members').then(response => response.data);
