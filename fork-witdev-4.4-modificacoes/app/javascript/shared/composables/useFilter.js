import wootConstants from 'dashboard/constants/globals';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { filterAttributeGroups as conversationFilterAttributeGroups } from 'dashboard/components/widgets/conversation/advancedFilterItems';
import { filterAttributeGroups as contactFilterAttributeGroups } from 'dashboard/routes/dashboard/contacts/contactFilterItems';
import * as OPERATORS from 'dashboard/components/widgets/FilterInput/FilterOperatorTypes.js';

const customAttributeInputType = key => {
  switch (key) {
    case 'date':
      return 'date';
    case 'text':
      return 'plain_text';
    case 'list':
      return 'search_select';
    case 'checkbox':
      return 'search_select';
    default:
      return 'plain_text';
  }
};

const getOperatorTypes = key => {
  switch (key) {
    case 'list':
      return OPERATORS.OPERATOR_TYPES_1;
    case 'text':
      return OPERATORS.OPERATOR_TYPES_3;
    case 'number':
      return OPERATORS.OPERATOR_TYPES_1;
    case 'link':
      return OPERATORS.OPERATOR_TYPES_1;
    case 'date':
      return OPERATORS.OPERATOR_TYPES_4;
    case 'checkbox':
      return OPERATORS.OPERATOR_TYPES_1;
    default:
      return OPERATORS.OPERATOR_TYPES_1;
  }
};

export const useFilter = ({ filteri18nKey, attributeModel }) => {
  const { t: $t } = useI18n();
  const { getters } = useStore();

  const filterAttributeGroups =
    attributeModel === 'contact_attribute'
      ? contactFilterAttributeGroups
      : conversationFilterAttributeGroups;

  const setFilterAttributes = () => {
    const allCustomAttributes =
      getters['attributes/getAttributesByModel'](attributeModel);

    const customAttributesFormatted = {
      name: $t(`${filteri18nKey}.GROUPS.CUSTOM_ATTRIBUTES`),
      attributes: allCustomAttributes.map(attr => {
        return {
          key: attr.attribute_key,
          name: attr.attribute_display_name,
        };
      }),
    };

    const allFilterGroups = filterAttributeGroups.map(group => {
      return {
        name: $t(`${filteri18nKey}.GROUPS.${group.i18nGroup}`),
        attributes: group.attributes.map(attribute => {
          return {
            key: attribute.key,
            name: $t(`${filteri18nKey}.ATTRIBUTES.${attribute.i18nKey}`),
          };
        }),
      };
    });

    const customAttributeTypes = allCustomAttributes.map(attr => {
      return {
        attributeKey: attr.attribute_key,
        attributeI18nKey: `CUSTOM_ATTRIBUTE_${attr.attribute_display_type.toUpperCase()}`,
        inputType: customAttributeInputType(attr.attribute_display_type),
        filterOperators: getOperatorTypes(attr.attribute_display_type),
        attributeModel: 'custom_attributes',
      };
    });

    return {
      filterGroups: [...allFilterGroups, customAttributesFormatted],
      filterTypes: [...customAttributeTypes],
    };
  };

  const initializeStatusAndAssigneeFilterToModal = (
    activeStatus,
    currentUserDetails,
    activeAssigneeTab
  ) => {
    if (activeStatus !== '') {
      return {
        attribute_key: 'status',
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        values: [
          {
            id: activeStatus,
            name: $t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${activeStatus}.TEXT`),
          },
        ],
        query_operator: 'and',
        custom_attribute_type: '',
      };
    }
    if (activeAssigneeTab === wootConstants.ASSIGNEE_TYPE.ME) {
      return {
        attribute_key: 'assignee_id',
        filter_operator: 'equal_to',
        values: currentUserDetails,
        query_operator: 'and',
        custom_attribute_type: '',
      };
    }
    return null;
  };

  const initializeInboxTeamAndLabelFilterToModal = (
    conversationInbox,
    inbox,
    teamId,
    activeTeam,
    label
  ) => {
    const filters = [];
    if (conversationInbox) {
      filters.push({
        attribute_key: 'inbox_id',
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        values: [
          {
            id: conversationInbox,
            name: inbox.name,
          },
        ],
        query_operator: 'and',
        custom_attribute_type: '',
      });
    }
    if (teamId) {
      filters.push({
        attribute_key: 'team_id',
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        values: activeTeam,
        query_operator: 'and',
        custom_attribute_type: '',
      });
    }
    if (label) {
      filters.push({
        attribute_key: 'labels',
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        values: [
          {
            id: label,
            name: label,
          },
        ],
        query_operator: 'and',
        custom_attribute_type: '',
      });
    }
    return filters;
  };

  return {
    setFilterAttributes,
    initializeStatusAndAssigneeFilterToModal,
    initializeInboxTeamAndLabelFilterToModal,
  };
};
