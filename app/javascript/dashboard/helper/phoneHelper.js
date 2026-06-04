/**
 * Compare phone numbers flexibly to handle format differences
 * (e.g. Brazilian 9th digit: +5587988465072 vs +558788465072)
 */
export const phonesMatch = (phoneA, phoneB) => {
  const a = phoneA?.replace(/\D/g, '');
  const b = phoneB?.replace(/\D/g, '');
  if (!a || !b) return false;
  if (a === b) return true;
  return a.length >= 8 && b.length >= 8 && a.slice(-8) === b.slice(-8);
};

/**
 * Check if a given inbox phone number is admin in a group.
 * @param {string} inboxPhone - The inbox phone number
 * @param {Array} members - Array of group members with contact.phone_number and role
 * @returns {boolean}
 */
export const isInboxAdminInGroup = (inboxPhone, members) => {
  if (!inboxPhone) return false;
  return members.some(
    m => phonesMatch(inboxPhone, m.contact?.phone_number) && m.role === 'admin'
  );
};
