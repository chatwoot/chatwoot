import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useOperators } from './operators';
import { useMapGetter } from 'dashboard/composables/store.js';

/**
 * Determines the input type for a custom attribute based on its key
 * @param {string} key - The attribute display type key
 * @returns {'date'|'plainText'|'searchSelect'} The corresponding input type
 */
const customAttributeInputType = key => {
  switch (key) {
    case 'date':
      return 'date';
    case 'text':
      return 'plainText';
    case 'list':
      return 'searchSelect';
    case 'checkbox':
      return 'searchSelect';
    default:
      return 'plainText';
  }
};

/**
 * Composable that provides conversation filtering context
 * @returns {{ filterTypes: import('vue').ComputedRef<Array<{
 *   attributeKey: string,
 *   attributeName: string,
 *   inputType: 'multiSelect'|'searchSelect'|'plainText'|'date',
 *   dataType: 'text'|'number',
 *   filterOperators: Array<string>,
 *   attributeModel: 'standard'|'additional'|'customAttributes'
 * }>> }} Object containing filter types configuration
 */
export function useConversationFilterContext() {
  const { t } = useI18n();

  const conversationAttributes = useMapGetter(
    'attributes/getConversationAttributes'
  );

  const {
    equalityOperators,
    presenceOperators,
    containmentOperators,
    dateOperators,
    getOperatorTypes,
  } = useOperators();

  /**
   * Computed property that generates custom filter types based on conversation attributes
   * @type {import('vue').ComputedRef<Array<{
   *   attributeKey: string,
   *   attributeName: string,
   *   inputType: ReturnType<typeof customAttributeInputType>,
   *   filterOperators: Array<string>,
   *   attributeModel: 'customAttributes'
   * }>>}
   */
  const customFilterTypes = computed(() => {
    return conversationAttributes.value.map(attr => {
      return {
        attributeKey: attr.attributeKey,
        attributeName: t(
          `CUSTOM_ATTRIBUTE_${attr.attributeDisplayType.toUpperCase()}`
        ),
        inputType: customAttributeInputType(attr.attributeDisplayType),
        filterOperators: getOperatorTypes(attr.attributeDisplayType),
        attributeModel: 'customAttributes',
      };
    });
  });

  /**
   * Computed property that combines standard and custom filter types
   * @type {import('vue').ComputedRef<Array<{
   *   attributeKey: string,
   *   attributeName: string,
   *   inputType: 'multiSelect'|'searchSelect'|'plainText'|'date',
   *   dataType: 'text'|'number',
   *   filterOperators: Array<string>,
   *   attributeModel: 'standard'|'additional'|'customAttributes'
   * }>>}
   */
  const filterTypes = computed(() => [
    {
      attributeKey: 'status',
      attributeName: t('FILTER.ATTRIBUTES.STATUS'),
      inputType: 'multiSelect',
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'assignee_id',
      attributeName: t('FILTER.ATTRIBUTES.ASSIGNEE_NAME'),
      inputType: 'searchSelect',
      dataType: 'text',
      filterOperators: presenceOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'inbox_id',
      attributeName: t('FILTER.ATTRIBUTES.INBOX_NAME'),
      inputType: 'searchSelect',
      dataType: 'text',
      filterOperators: presenceOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'team_id',
      attributeName: t('FILTER.ATTRIBUTES.TEAM_NAME'),
      inputType: 'searchSelect',
      dataType: 'number',
      filterOperators: presenceOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'display_id',
      attributeName: t('FILTER.ATTRIBUTES.CONVERSATION_IDENTIFIER'),
      inputType: 'plainText',
      dataType: 'Number',
      filterOperators: containmentOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'campaign_id',
      attributeName: t('FILTER.ATTRIBUTES.CAMPAIGN_NAME'),
      inputType: 'searchSelect',
      dataType: 'Number',
      filterOperators: presenceOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'labels',
      attributeName: t('FILTER.ATTRIBUTES.LABELS'),
      inputType: 'multiSelect',
      dataType: 'text',
      filterOperators: presenceOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'browser_language',
      attributeName: t('FILTER.ATTRIBUTES.BROWSER_LANGUAGE'),
      inputType: 'searchSelect',
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'additional',
    },
    {
      attributeKey: 'country_code',
      attributeName: t('FILTER.ATTRIBUTES.COUNTRY_NAME'),
      inputType: 'searchSelect',
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'additional',
    },
    {
      attributeKey: 'referer',
      attributeName: t('FILTER.ATTRIBUTES.REFERER_LINK'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: containmentOperators.value,
      attributeModel: 'additional',
    },
    {
      attributeKey: 'created_at',
      attributeName: t('FILTER.ATTRIBUTES.CREATED_AT'),
      inputType: 'date',
      dataType: 'text',
      filterOperators: dateOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: 'last_activity_at',
      attributeName: t('FILTER.ATTRIBUTES.LAST_ACTIVITY'),
      inputType: 'date',
      dataType: 'text',
      filterOperators: dateOperators.value,
      attributeModel: 'standard',
    },
    ...customFilterTypes.value,
  ]);

  return { filterTypes };
}
