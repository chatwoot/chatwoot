export const escapeHtml = (unsafe = '') => {
  return unsafe
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
};

export const afterSanitizeAttributes = currentNode => {
  if ('target' in currentNode) {
    currentNode.setAttribute('target', '_blank');
  }
};

// Mirrors DOMPurify's URI allowlist while adding the internal tool protocol.
const DOMPURIFY_SAFE_URI_PATTERN =
  '(?:(?:(?:f|ht)tps?|mailto|tel|callto|sms|cid|xmpp|matrix):|' +
  '[^a-z]|[a-z+.-]+(?:[^a-z+.:-]|$))';
const TOOL_LINK_URI_PATTERN = new RegExp(
  `^(?:tool://|${DOMPURIFY_SAFE_URI_PATTERN})`,
  'i'
);

export const domPurifyConfig = {
  namedConfigurations: {
    toolLinks: {
      ALLOWED_URI_REGEXP: TOOL_LINK_URI_PATTERN,
    },
  },
  hooks: {
    afterSanitizeAttributes,
  },
};
