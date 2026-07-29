import { attributeCategorySlug } from 'dashboard/composables/useUISettings';

export const attributeCategory = attribute =>
  (attribute?.category || attribute?.Category || '').trim();

/**
 * Group attributes by category label.
 * @param {Array} attributes
 * @param {{ uncategorizedLabel?: string, categoryOrder?: string[] }} options
 * @returns {Array<{ key: string, slug: string, title: string, attributes: Array }>}
 */
export const groupAttributesByCategory = (attributes, options = {}) => {
  const { uncategorizedLabel = 'Uncategorized', categoryOrder = [] } = options;

  if (!attributes?.length) return [];

  const groups = new Map();

  attributes.forEach(attribute => {
    const category = attributeCategory(attribute);
    const key = category || '__uncategorized__';
    const slug = attributeCategorySlug(category);

    if (!groups.has(key)) {
      groups.set(key, {
        key,
        slug,
        title: category || uncategorizedLabel,
        attributes: [],
      });
    }
    groups.get(key).attributes.push(attribute);
  });

  const list = [...groups.values()];

  if (!categoryOrder.length) return list;

  return list.sort((a, b) => {
    const aPos = categoryOrder.indexOf(a.slug);
    const bPos = categoryOrder.indexOf(b.slug);
    if (aPos === -1 && bPos === -1) return 0;
    if (aPos === -1) return 1;
    if (bPos === -1) return -1;
    return aPos - bPos;
  });
};
