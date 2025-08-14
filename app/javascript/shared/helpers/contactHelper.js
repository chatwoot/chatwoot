export const getContactDisplayName = contact => {
  if (!contact || typeof contact !== 'object') {
    return '';
  }

  const pickNonEmpty = value => {
    if (value === null || value === undefined) return '';
    const str = String(value).trim();
    return str;
  };

  const name = pickNonEmpty(contact.name);
  if (name) return name;

  const email = pickNonEmpty(contact.email);
  if (email) return email;

  const phone = pickNonEmpty(contact.phone_number);
  if (phone) return phone;

  const identifier = pickNonEmpty(contact.identifier);
  if (identifier) return identifier;

  return '—';
};
