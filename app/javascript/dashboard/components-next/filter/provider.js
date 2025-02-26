import { computed, h } from 'vue';
import { useI18n } from 'vue-i18n';
import { useOperators } from './operators';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useChannelIcon } from 'next/icon/provider';
import {
  buildAttributesFilterTypes,
  CONVERSATION_ATTRIBUTES,
} from './helper/filterHelper';
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
 * @property {string} attributeKey - The attribute key
 * @property {string} value - This is a proxy for the attribute key used in FilterSelect
 * @property {string} attributeName - The attribute name used to display on the UI
 * @property {string} label - This is a proxy for the attribute name used in FilterSelect
 * @property {'multiSelect'|'searchSelect'|'plainText'|'date'|'booleanSelect'} inputType - The input type for the attribute
 * @property {FilterOption[]} [options] - The options available for the attribute if it is a multiSelect or singleSelect type
 * @property {'text'|'number'} dataType
 * @property {FilterOperator[]} filterOperators - The operators available for the attribute
 * @property {'standard'|'additional'|'customAttributes'} attributeModel
 */

/**
 * @typedef {Object} FilterGroup
 * @property {string} name
 * @property {FilterType[]} attributes
 */

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
  const customFilterTypes = computed(() =>
    buildAttributesFilterTypes(
      conversationAttributes.value,
      getOperatorTypes,
      'conversation'
    )
  );

  /**
   * @type {import('vue').ComputedRef<FilterType[]>}
   */
  const filterTypes = computed(() => [
    {
      attributeKey: CONVERSATION_ATTRIBUTES.STATUS,
      value: CONVERSATION_ATTRIBUTES.STATUS,
      attributeName: t('FILTER.ATTRIBUTES.STATUS'),
      label: t('FILTER.ATTRIBUTES.STATUS'),
      inputType: 'multiSelect',
      options: ['open', 'resolved', 'pending', 'snoozed', 'all'].map(id => {
        return {
          id,
          name: t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${id}.TEXT`),
        };
      }),
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.PRIORITY,
      value: CONVERSATION_ATTRIBUTES.PRIORITY,
      attributeName: t('FILTER.ATTRIBUTES.PRIORITY'),
      label: t('FILTER.ATTRIBUTES.PRIORITY'),
      inputType: 'multiSelect',
      options: ['low', 'medium', 'high', 'urgent'].map(id => {
        return {
          id,
          name: t(`CONVERSATION.PRIORITY.OPTIONS.${id.toUpperCase()}`),
        };
      }),
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.ASSIGNEE_ID,
      value: CONVERSATION_ATTRIBUTES.ASSIGNEE_ID,
      attributeName: t('FILTER.ATTRIBUTES.ASSIGNEE_NAME'),
      label: t('FILTER.ATTRIBUTES.ASSIGNEE_NAME'),
      inputType: 'searchSelect',
      options: agents.value.map(agent => {
        return {
          id: agent.id,
          name: agent.name,
        };
      }),
      dataType: 'text',
      filterOperators: presenceOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.INBOX_ID,
      value: CONVERSATION_ATTRIBUTES.INBOX_ID,
      attributeName: t('FILTER.ATTRIBUTES.INBOX_NAME'),
      label: t('FILTER.ATTRIBUTES.INBOX_NAME'),
      inputType: 'searchSelect',
      options: inboxes.value.map(inbox => {
        return {
          ...inbox,
          icon: useChannelIcon(inbox).value,
        };
      }),
      dataType: 'text',
      filterOperators: presenceOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.TEAM_ID,
      value: CONVERSATION_ATTRIBUTES.TEAM_ID,
      attributeName: t('FILTER.ATTRIBUTES.TEAM_NAME'),
      label: t('FILTER.ATTRIBUTES.TEAM_NAME'),
      inputType: 'searchSelect',
      options: teams.value,
      dataType: 'number',
      filterOperators: presenceOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.DISPLAY_ID,
      value: CONVERSATION_ATTRIBUTES.DISPLAY_ID,
      attributeName: t('FILTER.ATTRIBUTES.CONVERSATION_IDENTIFIER'),
      label: t('FILTER.ATTRIBUTES.CONVERSATION_IDENTIFIER'),
      inputType: 'plainText',
      datatype: 'number',
      filterOperators: containmentOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.CAMPAIGN_ID,
      value: CONVERSATION_ATTRIBUTES.CAMPAIGN_ID,
      attributeName: t('FILTER.ATTRIBUTES.CAMPAIGN_NAME'),
      label: t('FILTER.ATTRIBUTES.CAMPAIGN_NAME'),
      inputType: 'searchSelect',
      options: campaigns.value.map(campaign => ({
        id: campaign.id,
        name: campaign.title,
      })),
      datatype: 'number',
      filterOperators: presenceOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.LABELS,
      value: CONVERSATION_ATTRIBUTES.LABELS,
      attributeName: t('FILTER.ATTRIBUTES.LABELS'),
      label: t('FILTER.ATTRIBUTES.LABELS'),
      inputType: 'multiSelect',
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
      dataType: 'text',
      filterOperators: presenceOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.BROWSER_LANGUAGE,
      value: CONVERSATION_ATTRIBUTES.BROWSER_LANGUAGE,
      attributeName: t('FILTER.ATTRIBUTES.BROWSER_LANGUAGE'),
      label: t('FILTER.ATTRIBUTES.BROWSER_LANGUAGE'),
      inputType: 'searchSelect',
      options: languages,
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'additional',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.COUNTRY_CODE,
      value: CONVERSATION_ATTRIBUTES.COUNTRY_CODE,
      attributeName: t('FILTER.ATTRIBUTES.COUNTRY_NAME'),
      label: t('FILTER.ATTRIBUTES.COUNTRY_NAME'),
      inputType: 'searchSelect',
      options: countries,
      dataType: 'text',
      filterOperators: equalityOperators.value,
      attributeModel: 'additional',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.REFERER,
      value: CONVERSATION_ATTRIBUTES.REFERER,
      attributeName: t('FILTER.ATTRIBUTES.REFERER_LINK'),
      label: t('FILTER.ATTRIBUTES.REFERER_LINK'),
      inputType: 'plainText',
      dataType: 'text',
      filterOperators: containmentOperators.value,
      attributeModel: 'additional',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.CREATED_AT,
      value: CONVERSATION_ATTRIBUTES.CREATED_AT,
      attributeName: t('FILTER.ATTRIBUTES.CREATED_AT'),
      label: t('FILTER.ATTRIBUTES.CREATED_AT'),
      inputType: 'date',
      dataType: 'text',
      filterOperators: dateOperators.value,
      attributeModel: 'standard',
    },
    {
      attributeKey: CONVERSATION_ATTRIBUTES.LAST_ACTIVITY_AT,
      value: CONVERSATION_ATTRIBUTES.LAST_ACTIVITY_AT,
      attributeName: t('FILTER.ATTRIBUTES.LAST_ACTIVITY'),
      label: t('FILTER.ATTRIBUTES.LAST_ACTIVITY'),
      inputType: 'date',
      dataType: 'text',
      filterOperators: dateOperators.value,
      attributeModel: 'standard',
    },
    ...customFilterTypes.value,
  ]);

  return { filterTypes };
}
