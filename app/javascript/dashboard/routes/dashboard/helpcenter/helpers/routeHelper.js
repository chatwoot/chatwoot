import { frontendURL } from 'dashboard/helper/URLHelper';

export const getPortalRoute = (path = '') => {
  const slugToBeAdded = path ? `/${path}` : '';
  return frontendURL(`accounts/:accountId/portals${slugToBeAdded}`);
};
