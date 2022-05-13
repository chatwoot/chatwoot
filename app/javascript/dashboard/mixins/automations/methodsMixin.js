import filterQueryGenerator from '../../helper/filterQueryGenerator.js';
import actionQueryGenerator from '../../helper/actionQueryGenerator.js';
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
} from '../../helper/automationHelper.js';
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      campaigns: 'campaigns/getAllCampaigns',
      contacts: 'contacts/getContacts',
      inboxes: 'inboxes/getInboxes',
      labels: 'labels/getLabels',
      teams: 'teams/getTeams',
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
      this.automation.conditions = getDefaultConditions(
        this.automation.event_name
      );
      this.automation.actions = getDefaultActions();
    },
    getAttributes(key) {
      return this.automationTypes[key].conditions;
    },
    getInputType(key) {
      const customAttribute = isACustomAttribute(this.allCustomAttributes, key);
      if (customAttribute) {
        return getCustomAttributeInputType(
          customAttribute.attribute_display_type
        );
      }
      const type = this.getAutomationType(key);
      return type.inputType;
    },
    getOperators(key) {
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
      return type.filterOperators;
    },
    getAutomationType(key) {
      return this.automationTypes[this.automation.event_name].conditions.find(
        condition => condition.key === key
      );
    },

    getConditionDropdownValues(type) {
      const {
        agents,
        allCustomAttributes: customAttributes,
        booleanFilterOptions,
        campaigns,
        contacts,
        inboxes,
        labels,
        statusFilterOptions,
        teams,
      } = this;
      return getConditionOptions({
        agents,
        booleanFilterOptions,
        campaigns,
        contacts,
        customAttributes,
        inboxes,
        labels,
        statusFilterOptions,
        teams,
        type,
      });
    },
    appendNewCondition() {
      if (this.mode === 'edit') {
        if (
          !this.automation.conditions[this.automation.conditions.length - 1]
            .query_operator
        ) {
          this.automation.conditions[
            this.automation.conditions.length - 1
          ].query_operator = 'and';
        }
      }
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
      const automation = JSON.parse(JSON.stringify(this.automation));
      automation.conditions[
        automation.conditions.length - 1
      ].query_operator = null;
      automation.conditions = filterQueryGenerator(
        automation.conditions
      ).payload;
      automation.actions = actionQueryGenerator(automation.actions);
      this.$emit(
        'saveAutomation',
        automation,
        this.mode === 'edit' ? 'EDIT' : null
      );
    },
    resetFilter(index, currentCondition) {
      this.automation.conditions[index].filter_operator = this.automationTypes[
        this.automation.event_name
      ].conditions.find(
        condition => condition.key === currentCondition.attribute_key
      ).filterOperators[0].value;
      this.automation.conditions[index].values = '';
    },
    showUserInput(operatorType) {
      if (operatorType === 'is_present' || operatorType === 'is_not_present')
        return false;
      return true;
    },
    showActionInput(actionName) {
      if (actionName === 'send_email_to_team' || actionName === 'send_message')
        return false;
      const type = this.automationActionTypes.find(
        action => action.key === actionName
      ).inputType;
      if (type === null) return false;
      return true;
    },
    resetAction(index) {
      this.automation.actions[index].action_params = [];
    },
    manifestConditions(automation) {
      const customAttributes = filterCustomAttributes(this.allCustomAttributes);
      const conditions = automation.conditions.map(condition => {
        const isCustomAttribute = customAttributes.find(
          attr => attr.key === condition.attribute_key
        );
        let inputType = 'plain_text';
        if (isCustomAttribute) {
          inputType = getCustomAttributeInputType(isCustomAttribute.type);
        } else {
          inputType = this.automationTypes[
            automation.event_name
          ].conditions.find(item => item.key === condition.attribute_key)
            .inputType;
        }
        if (inputType === 'plain_text' || inputType === 'date') {
          return {
            ...condition,
            values: condition.values[0],
          };
        }
        return {
          ...condition,
          values: [
            ...this.getConditionDropdownValues(condition.attribute_key),
          ].filter(item => [...condition.values].includes(item.id)),
        };
      });
      return conditions;
    },
    generateActionsArray(action) {
      let actionParams = [];
      const inputType = this.automationActionTypes.find(
        item => item.key === action.action_name
      ).inputType;
      if (inputType === 'multi_select') {
        actionParams = [
          ...this.getActionDropdownValues(action.action_name),
        ].filter(item => [...action.action_params].includes(item.id));
      } else if (inputType === 'team_message') {
        actionParams = {
          team_ids: [
            ...this.getActionDropdownValues(action.action_name),
          ].filter(item =>
            [...action.action_params[0].team_ids].includes(item.id)
          ),
          message: action.action_params[0].message,
        };
      } else actionParams = [...action.action_params];
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
      this.automation = {
        ...automation,
        conditions: this.manifestConditions(automation),
        actions: this.manifestActions(automation),
      };
    },
    getActionDropdownValues(type) {
      const { labels, teams } = this;
      return getActionOptions({ labels, teams, type });
    },
    manifestCustomAttributes() {
      const conversationCustomAttributesRaw = this.$store.getters[
        'attributes/getAttributesByModel'
      ]('conversation_attribute');

      const contactCustomAttributesRaw = this.$store.getters[
        'attributes/getAttributesByModel'
      ]('contact_attribute');

      const conversationCustomAttributeTypes = generateCustomAttributeTypes(
        conversationCustomAttributesRaw
      );
      const contactCustomAttributeTypes = generateCustomAttributeTypes(
        contactCustomAttributesRaw
      );

      const manifestedCustomAttributes = [
        {
          key: 'conversation_custom_attribute',
          name: this.$t('AUTOMATION.CONDITION.CONVERSATION_CUSTOM_ATTR_LABEL'),
          disabled: true,
        },
        ...conversationCustomAttributeTypes,
        {
          key: 'contact_custom_attribute',
          name: this.$t('AUTOMATION.CONDITION.CONTACT_CUSTOM_ATTR_LABEL'),
          disabled: true,
        },
        ...contactCustomAttributeTypes,
      ];
      this.automationTypes.message_created.conditions.push(
        ...manifestedCustomAttributes
      );
      this.automationTypes.conversation_created.conditions.push(
        ...manifestedCustomAttributes
      );
      this.automationTypes.conversation_updated.conditions.push(
        ...manifestedCustomAttributes
      );
    },
  },
};
