import languages from '../../components/widgets/conversation/advancedFilterItems/languages';
import countries from '../../../shared/constants/countries';
import filterQueryGenerator from '../../helper/filterQueryGenerator.js';
import actionQueryGenerator from '../../helper/actionQueryGenerator.js';
import {
  getCustomAttributeInputType,
  isACustomAttribute,
  getCustomAttributeListDropdownValues,
  getCustomAttributeCheckboxDropdownValues,
  isCustomAttributeCheckbox,
  isCustomAttributeList,
  getOperatorTypes,
} from '../../helper/automationHelper.js';

const MESASAGE_CONDITION_VALUES = [
  {
    id: 'incoming',
    name: 'Incoming Message',
  },
  {
    id: 'outgoing',
    name: 'Outgoing Message',
  },
];
export default {
  methods: {
    onEventChange() {
      if (this.automation.event_name === 'message_created') {
        this.automation.conditions = [
          {
            attribute_key: 'message_type',
            filter_operator: 'equal_to',
            values: '',
            query_operator: 'and',
          },
        ];
      } else {
        this.automation.conditions = [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: '',
            query_operator: 'and',
          },
        ];
      }
      this.automation.actions = [
        {
          action_name: 'assign_team',
          action_params: [],
        },
      ];
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
    statusFilterDropdownValues() {
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
    getConditionDropdownValues(type) {
      if (isCustomAttributeCheckbox(this.allCustomAttributes, type))
        return getCustomAttributeCheckboxDropdownValues();

      if (isCustomAttributeList(this.allCustomAttributes, type))
        return getCustomAttributeListDropdownValues(
          this.allCustomAttributes,
          type
        );

      switch (type) {
        case 'status':
          return this.statusFilterDropdownValues();
        case 'assignee_id':
          return this.$store.getters['agents/getAgents'];
        case 'contact':
          return this.$store.getters['contacts/getContacts'];
        case 'inbox_id':
          return this.$store.getters['inboxes/getInboxes'];
        case 'team_id':
          return this.$store.getters['teams/getTeams'];
        case 'campaign_id':
          return this.$store.getters['campaigns/getAllCampaigns'].map(i => {
            return {
              id: i.id,
              name: i.title,
            };
          });
        case 'labels':
          return this.$store.getters['labels/getLabels'].map(i => {
            return {
              id: i.id,
              name: i.title,
            };
          });
        case 'browser_language':
          return languages;
        case 'country_code':
          return countries;
        case 'message_type':
          return MESASAGE_CONDITION_VALUES;
        default:
          return undefined;
      }
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
      switch (this.automation.event_name) {
        case 'message_created':
          this.automation.conditions.push({
            attribute_key: 'message_type',
            filter_operator: 'equal_to',
            values: '',
            query_operator: 'and',
          });
          break;
        default:
          this.automation.conditions.push({
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: '',
            query_operator: 'and',
          });
          break;
      }
    },
    appendNewAction() {
      this.automation.actions.push({
        action_name: 'assign_team',
        action_params: [],
      });
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
      const customAttributes = this.allCustomAttributes.map(attr => {
        return {
          key: attr.attribute_key,
          name: attr.attribute_display_name,
          type: attr.attribute_display_type,
        };
      });
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
    getFileName(id, actionType) {
      if (!id) return '';
      if (actionType === 'send_attachment') {
        const file = this.automation.files.find(item => item.blob_id === id);
        if (file) return file.filename.toString();
      }
      return '';
    },
    getActionDropdownValues(type) {
      switch (type) {
        case 'assign_team':
        case 'send_email_to_team':
          return this.$store.getters['teams/getTeams'];
        case 'add_label':
          return this.$store.getters['labels/getLabels'].map(i => {
            return {
              id: i.title,
              name: i.title,
            };
          });
        default:
          return undefined;
      }
    },
    manifestCustomAttributes() {
      const conversationCustomAttributesRaw = this.$store.getters[
        'attributes/getAttributesByModel'
      ]('conversation_attribute');

      const contactCustomAttributesRaw = this.$store.getters[
        'attributes/getAttributesByModel'
      ]('contact_attribute');

      const conversationCustomAttributeTypes = conversationCustomAttributesRaw.map(
        attr => {
          return {
            key: attr.attribute_key,
            name: attr.attribute_display_name,
            inputType: getCustomAttributeInputType(attr.attribute_display_type),
            filterOperators: getOperatorTypes(attr.attribute_display_type),
          };
        }
      );

      const contactCustomAttributeTypes = contactCustomAttributesRaw.map(
        attr => {
          return {
            key: attr.attribute_key,
            name: attr.attribute_display_name,
            inputType: getCustomAttributeInputType(attr.attribute_display_type),
            filterOperators: getOperatorTypes(attr.attribute_display_type),
          };
        }
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
