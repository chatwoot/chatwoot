import { computed, h } from 'vue';
import { useI18n } from 'vue-i18n';
import { useOperators } from './operators';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useChannelIcon } from 'next/icon/provider';
import countries from 'shared/constants/countries.js';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages.js';

/**
 * @typedef {Object} FilterOption
 * @property {string|number} id
 * @property {string} name
 * @property {import('vue').VNode} [icon]
 */

/**
 * @typedef {Object} FilterOperator
 * @property {string} value
 * @property {string} label
 * @property {string} icon
 * @property {boolean} hasInput
 */

/**
 * @typedef {Object} FilterType
 * @property {string} attribute_key - The attribute key
 * @property {string} value - This is a proxy for the attribute key used in FilterSelect
 * @property {string} attribute_name - The attribute name used to display on the UI
 * @property {string} label - This is a proxy for the attribute name used in FilterSelect
 * @property {'multiSelect'|'searchSelect'|'plainText'|'date'|'booleanSelect'} input_type - The input type for the attribute
 * @property {FilterOption[]} [options] - The options available for the attribute if it is a multiSelect or singleSelect type
 * @property {'text'|'number'} data_type
 * @property {FilterOperator[]} filter_operators - The operators available for the attribute
 * @property {'standard'|'additional'|'customAttributes'} attribute_model
 */

/**
 * @typedef {Object} FilterGroup
 * @property {string} name
 * @property {FilterType[]} attributes
 */

/**
 * Determines the input type for a custom attribute based on its key
 * @param {string} key - The attribute display type key
 * @returns {'date'|'plainText'|'searchSelect'|'booleanSelect'} The corresponding input type
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
      return 'booleanSelect';
    default:
      return 'plainText';
  }
};

/**
 * Composable that provides conversation filtering context
 * @returns {{ filterTypes: import('vue').ComputedRef<FilterType[]>, filterGroups: import('vue').ComputedRef<FilterGroup[]> }}
 */
export function useConversationFilterContext() {
  const { t } = useI18n();

  const conversationAttributes = useMapGetter(
    'attributes/getConversationAttributes'
  );

  const labels = useMapGetter('labels/getLabels');
  const agents = useMapGetter('agents/getAgents');
  const inboxes = useMapGetter('inboxes/getInboxes');
  const teams = useMapGetter('teams/getTeams');
  const campaigns = useMapGetter('campaigns/getAllCampaigns');

  const {
    equalityOperators,
    presenceOperators,
    containmentOperators,
    dateOperators,
    getOperatorTypes,
  } = useOperators();

  /**
   * @type {import('vue').ComputedRef<FilterType[]>}
   */
  const customFilterTypes = computed(() => {
    return conversationAttributes.value.map(attr => {
      return {
        attribute_key: attr.attributeKey,
        value: attr.attributeKey,
        attribute_name: attr.attributeDisplayName,
        label: attr.attributeDisplayName,
        input_type: customAttributeInputType(attr.attributeDisplayType),
        filter_operators: getOperatorTypes(attr.attributeDisplayType),
        options:
          attr.attributeDisplayType === 'list'
            ? attr.attributeValues.map(item => ({ id: item, name: item }))
            : [],
        attribute_model: 'customAttributes',
      };
    });
  });

  /**
   * @type {import('vue').ComputedRef<FilterType[]>}
   */
  const filterTypes = computed(() => [
    {
      attribute_key: 'status',
      value: 'status',
      attribute_name: t('FILTER.ATTRIBUTES.STATUS'),
      label: t('FILTER.ATTRIBUTES.STATUS'),
      input_type: 'multiSelect',
      options: ['open', 'resolved', 'pending', 'snoozed', 'all'].map(id => {
        return {
          id,
          name: t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${id}.TEXT`),
        };
      }),
      data_type: 'text',
      filter_operators: equalityOperators.value,
      attribute_model: 'standard',
    },
    {
      attribute_key: 'assignee_id',
      value: 'assignee_id',
      attribute_name: t('FILTER.ATTRIBUTES.ASSIGNEE_NAME'),
      label: t('FILTER.ATTRIBUTES.ASSIGNEE_NAME'),
      input_type: 'searchSelect',
      options: agents.value.map(agent => {
        return {
          id: agent.id,
          name: agent.name,
        };
      }),
      data_type: 'text',
      filter_operators: presenceOperators.value,
      attribute_model: 'standard',
    },
    {
      attribute_key: 'inbox_id',
      value: 'inbox_id',
      attribute_name: t('FILTER.ATTRIBUTES.INBOX_NAME'),
      label: t('FILTER.ATTRIBUTES.INBOX_NAME'),
      input_type: 'searchSelect',
      options: inboxes.value.map(inbox => {
        return {
          ...inbox,
          icon: useChannelIcon(inbox).value,
        };
      }),
      data_type: 'text',
      filter_operators: presenceOperators.value,
      attribute_model: 'standard',
    },
    {
      attribute_key: 'team_id',
      value: 'team_id',
      attribute_name: t('FILTER.ATTRIBUTES.TEAM_NAME'),
      label: t('FILTER.ATTRIBUTES.TEAM_NAME'),
      input_type: 'searchSelect',
      options: teams.value,
      data_type: 'number',
      filter_operators: presenceOperators.value,
      attribute_model: 'standard',
    },
    {
      attribute_key: 'display_id',
      value: 'display_id',
      attribute_name: t('FILTER.ATTRIBUTES.CONVERSATION_IDENTIFIER'),
      label: t('FILTER.ATTRIBUTES.CONVERSATION_IDENTIFIER'),
      input_type: 'plainText',
      datatype: 'number',
      filter_operators: containmentOperators.value,
      attribute_model: 'standard',
    },
    {
      attribute_key: 'campaign_id',
      value: 'campaign_id',
      attribute_name: t('FILTER.ATTRIBUTES.CAMPAIGN_NAME'),
      label: t('FILTER.ATTRIBUTES.CAMPAIGN_NAME'),
      input_type: 'searchSelect',
      options: campaigns.value.map(campaign => ({
        id: campaign.id,
        name: campaign.title,
      })),
      datatype: 'number',
      filter_operators: presenceOperators.value,
      attribute_model: 'standard',
    },
    {
      attribute_key: 'labels',
      value: 'labels',
      attribute_name: t('FILTER.ATTRIBUTES.LABELS'),
      label: t('FILTER.ATTRIBUTES.LABELS'),
      input_type: 'multiSelect',
      options: labels.value.map(label => {
        return {
          id: label.title,
          name: label.title,
          icon: h('span', {
            class: `rounded-full`,
            style: {
              backgroundColor: label.color,
              height: '6px',
              width: '6px',
            },
          }),
        };
      }),
      data_type: 'text',
      filter_operators: presenceOperators.value,
      attribute_model: 'standard',
    },
    {
      attribute_key: 'browser_language',
      value: 'browser_language',
      attribute_name: t('FILTER.ATTRIBUTES.BROWSER_LANGUAGE'),
      label: t('FILTER.ATTRIBUTES.BROWSER_LANGUAGE'),
      input_type: 'searchSelect',
      options: languages,
      data_type: 'text',
      filter_operators: equalityOperators.value,
      attribute_model: 'additional',
    },
    {
      attribute_key: 'country_code',
      value: 'country_code',
      attribute_name: t('FILTER.ATTRIBUTES.COUNTRY_NAME'),
      label: t('FILTER.ATTRIBUTES.COUNTRY_NAME'),
      input_type: 'searchSelect',
      options: countries,
      data_type: 'text',
      filter_operators: equalityOperators.value,
      attribute_model: 'additional',
    },
    {
      attribute_key: 'referer',
      value: 'referer',
      attribute_name: t('FILTER.ATTRIBUTES.REFERER_LINK'),
      label: t('FILTER.ATTRIBUTES.REFERER_LINK'),
      input_type: 'plainText',
      data_type: 'text',
      filter_operators: containmentOperators.value,
      attribute_model: 'additional',
    },
    {
      attribute_key: 'created_at',
      value: 'created_at',
      attribute_name: t('FILTER.ATTRIBUTES.CREATED_AT'),
      label: t('FILTER.ATTRIBUTES.CREATED_AT'),
      input_type: 'date',
      data_type: 'text',
      filter_operators: dateOperators.value,
      attribute_model: 'standard',
    },
    {
      attribute_key: 'last_activity_at',
      value: 'last_activity_at',
      attribute_name: t('FILTER.ATTRIBUTES.LAST_ACTIVITY'),
      label: t('FILTER.ATTRIBUTES.LAST_ACTIVITY'),
      input_type: 'date',
      data_type: 'text',
      filter_operators: dateOperators.value,
      attribute_model: 'standard',
    },
    ...customFilterTypes.value,
  ]);

  const filterGroups = computed(() => {
    return [
      {
        name: t(`FILTER.GROUPS.STANDARD_FILTERS`),
        attributes: filterTypes.value.filter(
          filter => filter.attribute_model === 'standard'
        ),
      },
      {
        name: t(`FILTER.GROUPS.ADDITIONAL_FILTERS`),
        attributes: filterTypes.value.filter(
          filter => filter.attribute_model === 'additional'
        ),
      },
      {
        name: t(`FILTER.GROUPS.CUSTOM_ATTRIBUTES`),
        attributes: filterTypes.value.filter(
          filter => filter.attribute_model === 'customAttributes'
        ),
      },
    ];
  });

  return { filterTypes, filterGroups };
}
