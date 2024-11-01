// This file contains the mixin methods which we use for the following
//  1. Automation Rule Add Form Modal (app/javascript/dashboard/routes/dashboard/settings/automation/AddAutomationRule.vue)
//  2. Automation Rule Edit Form Modal (app/javascript/dashboard/routes/dashboard/settings/automation/EditAutomationRule.vue)

import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import countries from 'shared/constants/countries';
import {
  generateCustomAttributeTypes,
  getActionOptions,
  getConditionOptions,
  getCustomAttributeInputType,
  getOperatorTypes,
  isACustomAttribute,
  getFileName,
  getDefaultConditions,
  getDefaultActions,
  filterCustomAttributes,
  generateAutomationPayload,
  getStandardAttributeInputType,
  isCustomAttribute,
  generateCustomAttributes,
} from 'dashboard/helper/automationHelper';
import { mapGetters } from 'vuex';
import {
  AUTOMATIONS,
  AUTOMATION_CONTACT_EVENTS,
} from 'dashboard/routes/dashboard/settings/automation/constants';

export default {
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      campaigns: 'campaigns/getAllCampaigns',
      contacts: 'contacts/getContacts',
      inboxes: 'inboxes/getInboxes',
      labels: 'labels/getLabels',
      teams: 'teams/getTeams',
      slaPolicies: 'sla/getSLA',
      stages: 'stages/getEnabledStages',
      products: 'products/getProducts',
    }),
    booleanFilterOptions() {
      return [
        {
          id: true,
          name: this.$t('FILTER.ATTRIBUTE_LABELS.TRUE'),
        },
        {
          id: false,
          name: this.$t('FILTER.ATTRIBUTE_LABELS.FALSE'),
        },
      ];
    },

    statusFilterOptions() {
      const statusFilters = this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS');
      return [
        ...Object.keys(statusFilters).map(status => {
          return {
            id: status,
            name: statusFilters[status].TEXT,
          };
        }),
        {
          id: 'all',
          name: this.$t('CHAT_LIST.FILTER_ALL'),
        },
      ];
    },
  },
  methods: {
    getFileName,
    onEventChange() {
      // This method will be called if the 'event' dropdown is changed
      this.automation.conditions = getDefaultConditions(
        this.automation.event_name
      );
      this.automation.actions = getDefaultActions();
      // Update filterGroups (data instance) for the condition dropdowns
      this.conditionGroups = this.getAttributeGroups(
        this.automation.event_name
      );
      // Conditions would be shown by groups instead of single items
      this.isGroupedConditionAttributes = AUTOMATION_CONTACT_EVENTS.includes(
        this.automation.event_name
      );
    },
    getAttributes(key) {
      // This method is to get conditions (options for condition dropdown) by event key
      if (AUTOMATION_CONTACT_EVENTS.includes(key))
        // They would be shown by groups instead of single items
        return [];

      return this.automationTypes[key].conditions;
    },
    getAttributeGroups(key) {
      // This method is to get conditions (options for grouped condition dropdown) by event key
      // Format
      // - []
      //  - Object
      //    - name (group_name):
      //      i18n translation of "CONTACTS_FILTER.GROUPS.[...]" : supported ["STANDARD_FILTERS", "CUSTOM_ATTRIBUTES", "PRODUCT_CUSTOM_ATTRIBUTES (only for contact events)"]
      //    - attributes (group children items): []
      //      - Object
      //        - key (condition attribute_key)
      //        - name (condition attribute_name)
      if (!AUTOMATION_CONTACT_EVENTS.includes(key))
        // They would be shown by groups instead of single items
        return [];

      // Get standard attributes of this event from constants
      const initialAutomationTypes = JSON.parse(JSON.stringify(AUTOMATIONS));
      const standardAttributes = initialAutomationTypes[key].conditions;
      const standardAttributeGroup = {
        name: this.$t('CONTACTS_FILTER.GROUPS.STANDARD_FILTERS'),
        attributes: standardAttributes.map(attr => {
          return {
            key: attr.key,
            name: this.$t(
              `CONTACTS_FILTER.ATTRIBUTES.${attr.attributeI18nKey}`
            ),
          };
        }),
      };

      // Get all custom attributes of 'Contact' model
      const allContactCustomAttributes =
        this.$store.getters['attributes/getAttributesByModel'](
          'contact_attribute'
        );

      // Format to adapt for dropdown's property
      const contactCustomAttributesFormatted = {
        name: this.$t('CONTACTS_FILTER.GROUPS.CUSTOM_ATTRIBUTES'),
        attributes: allContactCustomAttributes.map(attr => {
          return {
            key: attr.attribute_key,
            name: attr.attribute_display_name,
          };
        }),
      };

      // Get all custom attributes of 'Product' model
      const allProductCustomAttributes =
        this.$store.getters['attributes/getAttributesByModel'](
          'product_attribute'
        );

      // Format to adapt for dropdown's property
      const productCustomAttributesFormatted = {
        name: this.$t('CONTACTS_FILTER.GROUPS.PRODUCT_CUSTOM_ATTRIBUTES'),
        attributes: allProductCustomAttributes.map(attr => {
          return {
            key: attr.attribute_key,
            name: attr.attribute_display_name,
          };
        }),
      };

      // Update automationTypes
      this.populateToAutomationType(
        allContactCustomAttributes,
        'contact_attribute'
      );
      this.populateToAutomationType(
        allProductCustomAttributes,
        'product_attribute'
      );

      return [
        standardAttributeGroup,
        contactCustomAttributesFormatted,
        productCustomAttributesFormatted,
      ];
    },
    populateToAutomationType(
      rawExtraAttributes = [],
      type = 'contact_attribute'
    ) {
      // Append additional data to automationTypes (with initial data was parsed from 'AUTOMATION' constant)
      // This is needed for resetFilter() method, submitting payload, ...
      if (rawExtraAttributes.length) {
        let conditions = generateCustomAttributeTypes(rawExtraAttributes, type);
        this.automationTypes.contact_created.conditions.push(...conditions);
        this.automationTypes.contact_updated.conditions.push(...conditions);
      }
    },
    getInputType(key) {
      // This method helps get type of user input into 'condition' section
      // Supported: date | multi_select | search_select | plain_text(default)
      const customAttribute = isACustomAttribute(this.allCustomAttributes, key);

      if (customAttribute) {
        return getCustomAttributeInputType(
          customAttribute.attribute_display_type
        );
      }
      const type = this.getAutomationType(key);
      return type?.inputType;
    },
    getOperators(key) {
      // This method helps get type of operation dropdown into 'condition' section
      // It has been used for <filter-input-box/> component
      if (this.mode === 'edit') {
        const customAttribute = isACustomAttribute(
          this.allCustomAttributes,
          key
        );
        if (customAttribute) {
          return getOperatorTypes(customAttribute.attribute_display_type);
        }
      }
      const type = this.getAutomationType(key);
      return type?.filterOperators;
    },
    getAutomationType(key) {
      return this.automationTypes[this.automation.event_name].conditions.find(
        condition => condition.key === key
      );
    },
    getCustomAttributeType(key) {
      // It has been used for <filter-input-box/> component
      const type = this.automationTypes[
        this.automation.event_name
      ].conditions.find(i => i.key === key)?.customAttributeType;
      return type;
    },
    getConditionDropdownValues(type) {
      // This method helps get options for the dropdown of user input (into 'condition' section)
      const {
        agents,
        allCustomAttributes: customAttributes,
        booleanFilterOptions,
        campaigns,
        contacts,
        inboxes,
        statusFilterOptions,
        teams,
        stages,
        products,
      } = this;
      return getConditionOptions({
        agents,
        booleanFilterOptions,
        campaigns,
        contacts,
        customAttributes,
        inboxes,
        statusFilterOptions,
        teams,
        stages,
        products,
        languages,
        countries,
        type,
      });
    },
    appendNewCondition() {
      this.automation.conditions.push(
        ...getDefaultConditions(this.automation.event_name)
      );
    },
    appendNewAction() {
      this.automation.actions.push(...getDefaultActions());
    },
    removeFilter(index) {
      if (this.automation.conditions.length <= 1) {
        this.showAlert(this.$t('AUTOMATION.CONDITION.DELETE_MESSAGE'));
      } else {
        this.automation.conditions.splice(index, 1);
      }
    },
    removeAction(index) {
      if (this.automation.actions.length <= 1) {
        this.showAlert(this.$t('AUTOMATION.ACTION.DELETE_MESSAGE'));
      } else {
        this.automation.actions.splice(index, 1);
      }
    },
    submitAutomation() {
      this.$v.$touch();
      if (this.$v.$invalid) return;
      const automation = generateAutomationPayload(this.automation);
      this.$emit('saveAutomation', automation, this.mode);
    },
    resetFilter(index, currentCondition) {
      this.automation.conditions[index].filter_operator = this.automationTypes[
        this.automation.event_name
      ].conditions.find(
        condition => condition.key === currentCondition.attribute_key
      ).filterOperators[0].value;
      this.automation.conditions[index].values = '';
    },
    showUserInput(type) {
      return !(type === 'is_present' || type === 'is_not_present');
    },
    showActionInput(action) {
      // This method helps decide whether the user input component
      // into the 'action' section should be shown.
      // It has been used for <automation-action-input/> component
      if (
        action === 'send_email_to_team' ||
        action === 'send_message' ||
        action === 'send_private_note'
      )
        return false;
      const type = this.automationActionTypes.find(
        i => i.key === action
      ).inputType;
      return !!type;
    },
    resetAction(index) {
      this.automation.actions[index].action_params = [];
    },
    manifestConditions(automation) {
      const customAttributes = filterCustomAttributes(this.allCustomAttributes);
      const conditions = automation.conditions.map(condition => {
        const customAttr = isCustomAttribute(
          customAttributes,
          condition.attribute_key
        );
        let inputType = 'plain_text';
        if (customAttr) {
          inputType = getCustomAttributeInputType(customAttr.type);
        } else {
          inputType = getStandardAttributeInputType(
            this.automationTypes,
            automation.event_name,
            condition.attribute_key
          );
        }
        if (
          inputType === 'plain_text' ||
          inputType === 'date' ||
          inputType === 'number'
        ) {
          return {
            ...condition,
            values: condition.values[0],
          };
        }
        if (inputType === 'comma_separated_plain_text') {
          return {
            ...condition,
            values: condition.values.join(','),
          };
        }
        return {
          ...condition,
          query_operator: condition.query_operator || 'and',
          values: [
            ...this.getConditionDropdownValues(condition.attribute_key),
          ].filter(item => [...condition.values].includes(item.id)),
        };
      });
      return conditions;
    },
    generateActionsArray(action) {
      const params = action.action_params;
      let actionParams = [];
      const inputType = this.automationActionTypes.find(
        item => item.key === action.action_name
      ).inputType;
      if (inputType === 'multi_select' || inputType === 'search_select') {
        actionParams = [
          ...this.getActionDropdownValues(action.action_name),
        ].filter(item => [...params].includes(item.id));
      } else if (inputType === 'team_message') {
        actionParams = {
          team_ids: [
            ...this.getActionDropdownValues(action.action_name),
          ].filter(item => [...params[0].team_ids].includes(item.id)),
          message: params[0].message,
        };
      } else actionParams = [...params];
      return actionParams;
    },
    manifestActions(automation) {
      let actionParams = [];
      const actions = automation.actions.map(action => {
        if (action.action_params.length) {
          actionParams = this.generateActionsArray(action);
        }
        return {
          ...action,
          action_params: actionParams,
        };
      });
      return actions;
    },
    formatAutomation(automation) {
      // This method helps format the automation object for <edit-automation-rule/> component
      this.automation = {
        ...automation,
        conditions: this.manifestConditions(automation),
        actions: this.manifestActions(automation),
      };
    },
    getActionDropdownValues(type) {
      // This method helps get options for the dropdown of user input (into 'action' section)
      // It has been used for <automation-action-input/> component
      const { agents, labels, teams, slaPolicies, stages } = this;
      return getActionOptions({
        agents,
        labels,
        teams,
        slaPolicies,
        stages,
        languages,
        type,
      });
    },
    manifestCustomAttributes() {
      // TODO: This should be grouped
      const conversationCustomAttributesRaw = this.$store.getters[
        'attributes/getAttributesByModel'
      ]('conversation_attribute');

      const contactCustomAttributesRaw =
        this.$store.getters['attributes/getAttributesByModel'](
          'contact_attribute'
        );

      const conversationCustomAttributeTypes = generateCustomAttributeTypes(
        conversationCustomAttributesRaw,
        'conversation_attribute'
      );

      const contactCustomAttributeTypes = generateCustomAttributeTypes(
        contactCustomAttributesRaw,
        'contact_attribute'
      );

      let manifestedCustomAttributes = generateCustomAttributes(
        conversationCustomAttributeTypes,
        contactCustomAttributeTypes,
        this.$t('AUTOMATION.CONDITION.CONVERSATION_CUSTOM_ATTR_LABEL'),
        this.$t('AUTOMATION.CONDITION.CONTACT_CUSTOM_ATTR_LABEL')
      );

      this.automationTypes.message_created.conditions.push(
        ...manifestedCustomAttributes
      );
      this.automationTypes.conversation_created.conditions.push(
        ...manifestedCustomAttributes
      );
      this.automationTypes.conversation_updated.conditions.push(
        ...manifestedCustomAttributes
      );
      this.automationTypes.conversation_opened.conditions.push(
        ...manifestedCustomAttributes
      );
    },
  },
};
