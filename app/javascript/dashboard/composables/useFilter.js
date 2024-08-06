// File: app/javascript/dashboard/composables/useFilter.js
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import wootConstants from 'dashboard/constants/globals';

/**
 * Composable for handling filter-related functionalities.
 * @returns {Object} An object containing methods for filter management.
 */
export function useFilter(
  attributeModel,
  filtersFori18n,
  filterAttributeGroups,
  customAttributeInputType,
  getOperatorTypes
) {
  const store = useStore();
  const filterTypes = ref([]);
  const filterGroups = ref([]);
  const appliedFilter = ref([]);
  const activeStatus = ref('');
  const activeAssigneeTab = ref('');
  const conversationInbox = ref('');
  const teamId = ref('');
  const label = ref('');
  const currentUserDetails = ref([]);
  const inbox = ref({});
  const activeTeam = ref({});

  const setFilterAttributes = () => {
    const allCustomAttributes = store.getters[
      'attributes/getAttributesByModel'
    ](attributeModel.value);
    const customAttributesFormatted = {
      name: store.$t(`${filtersFori18n.value}.GROUPS.CUSTOM_ATTRIBUTES`),
      attributes: allCustomAttributes.map(attr => ({
        key: attr.attribute_key,
        name: store.$t(`${filtersFori18n.value}.ATTRIBUTES.${attr.i18nKey}`),
      })),
    };
    const allFilterGroups = filterAttributeGroups.value.map(group => ({
      name: store.$t(`${filtersFori18n.value}.GROUPS.${group.i18nGroup}`),
      attributes: group.attributes.map(attribute => ({
        key: attribute.key,
        name: store.$t(
          `${filtersFori18n.value}.ATTRIBUTES.${attribute.i18nKey}`
        ),
      })),
    }));
    const customAttributeTypes = allCustomAttributes.map(attr => ({
      attributeKey: attr.attribute_key,
      attributeI18nKey: `CUSTOM_ATTRIBUTE_${attr.attribute_display_type.toUpperCase()}`,
      inputType: customAttributeInputType(attr.attribute_display_type),
      filterOperators: getOperatorTypes(attr.attribute_display_type),
      attributeModel: 'custom_attributes',
    }));
    filterTypes.value = [...filterTypes.value, ...customAttributeTypes];
    filterGroups.value = [...allFilterGroups, customAttributesFormatted];
  };

  const initializeExistingFilterToModal = () => {
    initializeStatusAndAssigneeFilterToModal();
    initializeInboxTeamAndLabelFilterToModal();
  };

  const initializeStatusAndAssigneeFilterToModal = () => {
    if (activeStatus.value !== '') {
      appliedFilter.value.push({
        attribute_key: 'status',
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        values: [
          {
            id: activeStatus.value,
            name: store.$t(
              `CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${activeStatus.value}.TEXT`
            ),
          },
        ],
        query_operator: 'and',
        custom_attribute_type: '',
      });
    }
    if (activeAssigneeTab.value === wootConstants.ASSIGNEE_TYPE.ME) {
      appliedFilter.value.push({
        attribute_key: 'assignee_id',
        filter_operator: 'equal_to',
        values: currentUserDetails.value,
        query_operator: 'and',
        custom_attribute_type: '',
      });
    }
  };

  const initializeInboxTeamAndLabelFilterToModal = () => {
    if (conversationInbox.value) {
      appliedFilter.value.push({
        attribute_key: 'inbox_id',
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        values: [
          {
            id: conversationInbox.value,
            name: inbox.value.name,
          },
        ],
        query_operator: 'and',
        custom_attribute_type: '',
      });
    }
    if (teamId.value) {
      appliedFilter.value.push({
        attribute_key: 'team_id',
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        values: activeTeam.value,
        query_operator: 'and',
        custom_attribute_type: '',
      });
    }
    if (label.value) {
      appliedFilter.value.push({
        attribute_key: 'labels',
        attribute_model: 'standard',
        filter_operator: 'equal_to',
        values: [
          {
            id: label.value,
            name: label.value,
          },
        ],
        query_operator: 'and',
        custom_attribute_type: '',
      });
    }
  };

  return {
    setFilterAttributes,
    initializeExistingFilterToModal,
    initializeStatusAndAssigneeFilterToModal,
    initializeInboxTeamAndLabelFilterToModal,
    filterTypes,
    filterGroups,
    appliedFilter,
    activeStatus,
    activeAssigneeTab,
    conversationInbox,
    teamId,
    label,
    currentUserDetails,
    inbox,
    activeTeam,
  };
}
