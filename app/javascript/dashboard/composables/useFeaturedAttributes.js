import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { normalizeDisplayType } from 'dashboard/helper/contactTableColumns';

export function formatAttributeValue(value, displayType) {
  if (value === undefined || value === null || value === '') return '';
  if (Array.isArray(value)) return value.join(', ');

  const type = normalizeDisplayType(displayType);

  if (type === 'currency') {
    const num = Number(value);
    if (Number.isNaN(num)) return String(value);
    const formatted = new Intl.NumberFormat(undefined, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(num);
    return `$${formatted}`;
  }

  if (type === 'percent') {
    const num = Number(value);
    if (Number.isNaN(num)) return String(value);
    return `${num}%`;
  }

  if (type === 'number') {
    const num = Number(value);
    if (Number.isNaN(num)) return String(value);
    return new Intl.NumberFormat(undefined, {
      maximumFractionDigits: 2,
    }).format(num);
  }

  return String(value);
}

/**
 * Featured custom attributes for conversation or contact records.
 * @param {'conversation_attribute'|'contact_attribute'} attributeModel
 * @param {import('vue').Ref|import('vue').ComputedRef} recordRef - record with custom_attributes
 */
export function useFeaturedAttributes(attributeModel, recordRef) {
  const getAttributesByModel = useMapGetter('attributes/getAttributesByModel');

  const featuredDefinitions = computed(() => {
    const defs = getAttributesByModel.value(attributeModel) || [];
    return defs.filter(def => def.featured === true || def.featured === 1);
  });

  const featuredBadges = computed(() => {
    const attrs =
      recordRef.value?.custom_attributes ||
      recordRef.value?.customAttributes ||
      {};
    return featuredDefinitions.value
      .map(def => {
        const raw = attrs[def.attribute_key];
        const empty =
          raw === undefined ||
          raw === null ||
          raw === '' ||
          (Array.isArray(raw) && raw.length === 0) ||
          (typeof raw === 'string' && raw.trim() === '');
        if (empty) return null;

        const type = normalizeDisplayType(def.attribute_display_type);
        if (
          ['number', 'currency', 'percent'].includes(type) &&
          Number(raw) === 0
        ) {
          return null;
        }

        return {
          key: def.attribute_key,
          label: def.attribute_display_name,
          displayType: def.attribute_display_type,
          value: raw,
          formatted: formatAttributeValue(raw, def.attribute_display_type),
        };
      })
      .filter(Boolean);
  });

  return { featuredDefinitions, featuredBadges };
}
