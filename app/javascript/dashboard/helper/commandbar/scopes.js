const PATH_SCOPES = { reports: '/reports', settings: '/settings' };

// The dashboard area a path belongs to. Used for the current page and for the
// destination of a navigation command, so both sides agree.
export const pathScopes = path =>
  Object.keys(PATH_SCOPES).filter(scope => path?.includes(PATH_SCOPES[scope]));
