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

export const domPurifyConfig = {
  hooks: {
    afterSanitizeAttributes,
  },
};
