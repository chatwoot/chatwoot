// Sources Chatwoot fills a parameter from, instead of the model. They match Captain::ParamSources on the server.
export const VERIFIED_EMAIL_SOURCE = 'verified.email';
const CONTACT_ATTRIBUTE_PREFIX = 'verified.contact.attributes.';

export const contactAttributeSource = key =>
  `${CONTACT_ATTRIBUTE_PREFIX}${key}`;

// The attribute key a source reads, or null when it reads something else
export const contactAttributeKey = source =>
  source?.startsWith(CONTACT_ATTRIBUTE_PREFIX)
    ? source.slice(CONTACT_ATTRIBUTE_PREFIX.length)
    : null;
