export const parseRedirectParams = hash => {
  const params = new URLSearchParams((hash || '').replace(/^#/, ''));
  const token = params.get('cw_redirect');
  if (!token) {
    return null;
  }
  return {
    token,
    autoOpen: params.get('cw_open') === '1',
  };
};

// Strip only the redirect-specific params from the fragment, preserving any
// other hash state the host page may rely on (including bare anchors like
// `#pricing`, which URLSearchParams would otherwise rewrite to `pricing=`).
export const stripRedirectParams = hash => {
  const raw = (hash || '').replace(/^#/, '');
  if (!raw) {
    return '';
  }
  const remaining = raw
    .split('&')
    .filter(segment => {
      const key = segment.split('=')[0];
      return key !== 'cw_redirect' && key !== 'cw_open';
    })
    .join('&');
  return remaining ? `#${remaining}` : '';
};
