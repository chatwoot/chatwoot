import { client } from './client';

// Contact identity endpoints are shared with the v1 widget API.
export const setUser = (identifier, user) =>
  client
    .patch('/api/v1/widget/contact/set_user', { identifier, ...user })
    .then(response => response.data);
