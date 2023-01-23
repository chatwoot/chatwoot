import wootConstants from 'dashboard/constants';

export default {
  methods: {
    setFilterAttributes() {
      const allCustomAttributes = this.$store.getters[
        'attributes/getAttributesByModel'
      ](this.attributeModel);
      const customAttributesFormatted = {
        name: this.$t(`${this.filtersFori18n}.GROUPS.CUSTOM_ATTRIBUTES`),
        attributes: allCustomAttributes.map(attr => {
          return {
            key: attr.attribute_key,
            name: attr.attribute_display_name,
          };
        }),
      };
      const allFilterGroups = this.filterAttributeGroups.map(group => {
        return {
          name: this.$t(`${this.filtersFori18n}.GROUPS.${group.i18nGroup}`),
          attributes: group.attributes.map(attribute => {
            return {
              key: attribute.key,
              name: this.$t(
                `${this.filtersFori18n}.ATTRIBUTES.${attribute.i18nKey}`
              ),
            };
          }),
        };
      });
      const customAttributeTypes = allCustomAttributes.map(attr => {
        return {
          attributeKey: attr.attribute_key,
          attributeI18nKey: `CUSTOM_ATTRIBUTE_${attr.attribute_display_type.toUpperCase()}`,
          inputType: this.customAttributeInputType(attr.attribute_display_type),
          filterOperators: this.getOperatorTypes(attr.attribute_display_type),
          attributeModel: 'custom_attributes',
        };
      });
      this.filterTypes = [...this.filterTypes, ...customAttributeTypes];
      this.filterGroups = [...allFilterGroups, customAttributesFormatted];
    },

    initializeExistingFilterToModal() {
      this.initializeStatusAndAssigneeFilterToModal();
      this.initializeInboxTeamAndLabelFilterToModal();
    },
    initializeStatusAndAssigneeFilterToModal() {
      if (this.activeStatus !== '') {
        this.appliedFilter.push({
          attribute_key: 'status',
          attribute_model: 'standard',
          filter_operator: 'equal_to',
          values: [
            {
              id: this.activeStatus,
              name: this.$t(
                `CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${this.activeStatus}.TEXT`
              ),
            },
          ],
          query_operator: 'and',
          custom_attribute_type: '',
        });
      }
      if (this.activeAssigneeTab === wootConstants.ASSIGNEE_TYPE.ME) {
        this.appliedFilter.push({
          attribute_key: 'assignee_id',
          filter_operator: 'equal_to',
          values: this.currentUserDetails,
          query_operator: 'and',
          custom_attribute_type: '',
        });
      }
    },
    initializeInboxTeamAndLabelFilterToModal() {
      if (this.conversationInbox) {
        this.appliedFilter.push({
          attribute_key: 'inbox_id',
          attribute_model: 'standard',
          filter_operator: 'equal_to',
          values: [
            {
              id: this.conversationInbox,
              name: this.inbox.name,
            },
          ],
          query_operator: 'and',
          custom_attribute_type: '',
        });
      }
      if (this.teamId) {
        this.appliedFilter.push({
          attribute_key: 'team_id',
          attribute_model: 'standard',
          filter_operator: 'equal_to',
          values: this.activeTeam,
          query_operator: 'and',
          custom_attribute_type: '',
        });
      }
      if (this.label) {
        this.appliedFilter.push({
          attribute_key: 'labels',
          attribute_model: 'standard',
          filter_operator: 'equal_to',
          values: [
            {
              id: this.label,
              name: this.label,
            },
          ],
          query_operator: 'and',
          custom_attribute_type: '',
        });
      }
    },
  },
};
