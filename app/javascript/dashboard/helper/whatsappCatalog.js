export const CATALOG_KINDS = {
  CAROUSEL: 'carousel',
  PRODUCT: 'product',
  PRODUCT_LIST: 'product_list',
};

export const CATALOG_ITEM_LIMITS = {
  [CATALOG_KINDS.CAROUSEL]: { min: 2, max: 10 },
  [CATALOG_KINDS.PRODUCT]: { min: 1, max: 1 },
  [CATALOG_KINDS.PRODUCT_LIST]: { min: 1, max: 30 },
};

export const CATALOG_TEXT_LIMITS = {
  body: 1024,
  header: 60,
  footer: 60,
  section: 24,
};

export const CATALOG_ERRORS = {
  MIN_ITEMS: 'MIN_ITEMS',
  MAX_ITEMS: 'MAX_ITEMS',
  REQUIRED: 'REQUIRED',
  TOO_LONG: 'TOO_LONG',
};

const REQUIRED_FIELDS = {
  [CATALOG_KINDS.CAROUSEL]: ['body'],
  [CATALOG_KINDS.PRODUCT]: [],
  [CATALOG_KINDS.PRODUCT_LIST]: ['body', 'header'],
};

const textLength = value => (value || '').trim().length;

export const validateCatalogForm = ({
  kind,
  items = [],
  body = '',
  header = '',
  footer = '',
}) => {
  const errors = {};
  const { min, max } = CATALOG_ITEM_LIMITS[kind];

  if (items.length < min) errors.items = CATALOG_ERRORS.MIN_ITEMS;
  else if (items.length > max) errors.items = CATALOG_ERRORS.MAX_ITEMS;

  const fields = { body, header, footer };
  Object.entries(fields).forEach(([field, value]) => {
    if (textLength(value) > CATALOG_TEXT_LIMITS[field]) {
      errors[field] = CATALOG_ERRORS.TOO_LONG;
    } else if (
      REQUIRED_FIELDS[kind].includes(field) &&
      textLength(value) === 0
    ) {
      errors[field] = CATALOG_ERRORS.REQUIRED;
    }
  });

  return errors;
};

// Groups products by their `section`, keeping first-seen order. Section
// titles are cut to the WhatsApp limit.
export const groupProductsBySection = (products = []) => {
  const sections = new Map();
  products.forEach(product => {
    const title = (product.section || '')
      .trim()
      .slice(0, CATALOG_TEXT_LIMITS.section);
    if (!sections.has(title)) sections.set(title, []);
    sections.get(title).push(product);
  });
  return [...sections].map(([title, items]) => ({ title, products: items }));
};

export const CATALOG_MAX_SELECTION = 30;

// For each format tells whether the current selection size fits it and,
// if not, the i18n reason.
export const getAvailableFormats = count =>
  Object.values(CATALOG_KINDS).map(kind => {
    const { min, max } = CATALOG_ITEM_LIMITS[kind];
    if (count < min) {
      return {
        kind,
        available: false,
        reason: { key: CATALOG_ERRORS.MIN_ITEMS, params: { min } },
      };
    }
    if (count > max) {
      return {
        kind,
        available: false,
        reason: { key: CATALOG_ERRORS.MAX_ITEMS, params: { max } },
      };
    }
    return { kind, available: true };
  });
