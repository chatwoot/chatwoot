<template>
  <div class="column">
    <woot-modal-header :header-title="$t('AUTOMATION.EDIT.TITLE')" />
    <div class="row modal-content">
      <div class="medium-12 columns">
        <woot-input
          v-model="automation.name"
          :label="$t('AUTOMATION.ADD.FORM.NAME.LABEL')"
          type="text"
          :class="{ error: $v.automation.name.$error }"
          :error="
            $v.automation.name.$error
              ? $t('AUTOMATION.ADD.FORM.NAME.ERROR')
              : ''
          "
          :placeholder="$t('AUTOMATION.ADD.FORM.NAME.PLACEHOLDER')"
          @blur="$v.automation.name.$touch"
        />
        <woot-input
          v-model="automation.description"
          :label="$t('AUTOMATION.ADD.FORM.DESC.LABEL')"
          type="text"
          :class="{ error: $v.automation.description.$error }"
          :error="
            $v.automation.description.$error
              ? $t('AUTOMATION.ADD.FORM.DESC.ERROR')
              : ''
          "
          :placeholder="$t('AUTOMATION.ADD.FORM.DESC.PLACEHOLDER')"
          @blur="$v.automation.description.$touch"
        />
        <div class="event_wrapper">
          <label :class="{ error: $v.automation.event_name.$error }">
            {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
            <select v-model="automation.event_name" @change="onEventChange()">
              <option
                v-for="event in automationRuleEvents"
                :key="event.key"
                :value="event.key"
              >
                {{ event.value }}
              </option>
            </select>
            <span v-if="$v.automation.event_name.$error" class="message">
              {{ $t('AUTOMATION.ADD.FORM.EVENT.ERROR') }}
            </span>
          </label>
        </div>
        <!-- // Conditions Start -->
        <section>
          <label>
            {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.LABEL') }}
          </label>
          <div class="medium-12 columns filters-wrap">
            <filter-input-box
              v-for="(condition, i) in automation.conditions"
              :key="i"
              v-model="automation.conditions[i]"
              :filter-attributes="getAttributes(automation.event_name)"
              :input-type="getInputType(automation.conditions[i].attribute_key)"
              :operators="getOperators(automation.conditions[i].attribute_key)"
              :dropdown-values="
                getConditionDropdownValues(
                  automation.conditions[i].attribute_key
                )
              "
              :show-query-operator="i !== automation.conditions.length - 1"
              :v="$v.automation.conditions.$each[i]"
              @resetFilter="resetFilter(i, automation.conditions[i])"
              @removeFilter="removeFilter(i)"
            />
            <div class="filter-actions">
              <woot-button
                icon="add"
                color-scheme="success"
                variant="smooth"
                size="small"
                @click="appendNewCondition"
              >
                {{ $t('AUTOMATION.ADD.CONDITION_BUTTON_LABEL') }}
              </woot-button>
            </div>
          </div>
        </section>
        <!-- // Conditions End -->
        <!-- // Actions Start -->
        <section>
          <label>
            {{ $t('AUTOMATION.ADD.FORM.ACTIONS.LABEL') }}
          </label>
          <div class="medium-12 columns filters-wrap">
            <automation-action-input
              v-for="(action, i) in automation.actions"
              :key="i"
              v-model="automation.actions[i]"
              :action-types="automationActionTypes"
              :dropdown-values="
                getActionDropdownValues(automation.actions[i].action_name)
              "
              :show-action-input="
                showActionInput(automation.actions[i].action_name)
              "
              :v="$v.automation.actions.$each[i]"
              :initial-file-name="
                getFileName(
                  automation.actions[i].action_params[0],
                  automation.actions[i].action_name
                )
              "
              @removeAction="removeAction(i)"
            />
            <div class="filter-actions">
              <woot-button
                icon="add"
                color-scheme="success"
                variant="smooth"
                size="small"
                @click="appendNewAction"
              >
                {{ $t('AUTOMATION.ADD.ACTION_BUTTON_LABEL') }}
              </woot-button>
            </div>
          </div>
        </section>
        <!-- // Actions End -->
        <div class="medium-12 columns">
          <div class="modal-footer justify-content-end w-full">
            <woot-button
              class="button"
              variant="clear"
              @click.prevent="onClose"
            >
              {{ $t('AUTOMATION.EDIT.CANCEL_BUTTON_TEXT') }}
            </woot-button>
            <woot-button @click="submitAutomation">
              {{ $t('AUTOMATION.EDIT.SUBMIT') }}
            </woot-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { required, requiredIf } from 'vuelidate/lib/validators';
import filterInputBox from 'dashboard/components/widgets/FilterInput/Index.vue';
import automationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import countries from 'shared/constants/countries.js';
import {
  AUTOMATION_RULE_EVENTS,
  AUTOMATION_ACTION_TYPES,
  AUTOMATIONS,
} from './constants';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator.js';
import actionQueryGenerator from 'dashboard/helper/actionQueryGenerator.js';

export default {
  components: {
    filterInputBox,
    automationActionInput,
  },
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
    selectedResponse: {
      type: Object,
      default: () => {},
    },
  },
  validations: {
    automation: {
      name: {
        required,
      },
      description: {
        required,
      },
      event_name: {
        required,
      },
      conditions: {
        required,
        $each: {
          values: {
            required: requiredIf(prop => {
              return !(
                prop.filter_operator === 'is_present' ||
                prop.filter_operator === 'is_not_present'
              );
            }),
          },
        },
      },
      actions: {
        required,
        $each: {
          action_params: {
            required: requiredIf(prop => {
              return !(
                prop.action_name === 'mute_conversation' ||
                prop.action_name === 'snooze_conversation' ||
                prop.action_name === 'resolve_conversation'
              );
            }),
          },
        },
      },
    },
  },
  data() {
    return {
      automationTypes: AUTOMATIONS,
      automationRuleEvent: AUTOMATION_RULE_EVENTS[0].key,
      automationRuleEvents: AUTOMATION_RULE_EVENTS,
      automationActionTypes: AUTOMATION_ACTION_TYPES,
      automationMutated: false,
      show: true,
      automation: {
        name: null,
        description: null,
        event_name: 'conversation_created',
        conditions: [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: '',
            query_operator: 'and',
          },
        ],
        actions: [
          {
            action_name: 'assign_team',
            action_params: [],
          },
        ],
      },
      showDeleteConfirmationModal: false,
    };
  },
  computed: {
    conditions() {
      return this.automationTypes[this.automation.event_name].conditions;
    },
    actions() {
      return this.automationTypes[this.automation.event_name].actions;
    },
    filterAttributes() {
      return this.filterTypes.map(type => {
        return {
          key: type.attributeKey,
          name: type.attributeName,
          attributeI18nKey: type.attributeI18nKey,
        };
      });
    },
  },
  mounted() {
    this.formatAutomation(this.selectedResponse);
  },
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
      const type = this.automationTypes[
        this.automation.event_name
      ].conditions.find(condition => condition.key === key);
      return type.inputType;
    },
    getOperators(key) {
      const type = this.automationTypes[
        this.automation.event_name
      ].conditions.find(condition => condition.key === key);
      return type.filterOperators;
    },
    getConditionDropdownValues(type) {
      const statusFilters = this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS');
      switch (type) {
        case 'status':
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
          return [
            {
              id: 'incoming',
              name: 'Incoming Message',
            },
            {
              id: 'outgoing',
              name: 'Outgoing Message',
            },
          ];
        default:
          return undefined;
      }
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
    appendNewCondition() {
      if (
        !this.automation.conditions[this.automation.conditions.length - 1]
          .query_operator
      ) {
        this.automation.conditions[
          this.automation.conditions.length - 1
        ].query_operator = 'and';
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
      this.$emit('saveAutomation', automation, 'EDIT');
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
    formatAutomation(automation) {
      const formattedConditions = automation.conditions.map(condition => {
        const inputType = this.automationTypes[
          automation.event_name
        ].conditions.find(item => item.key === condition.attribute_key)
          .inputType;
        if (inputType === 'plain_text') {
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
      const formattedActions = automation.actions.map(action => {
        let actionParams = [];
        if (action.action_params.length) {
          const inputType = AUTOMATION_ACTION_TYPES.find(
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
        }
        return {
          ...action,
          action_params: actionParams,
        };
      });
      this.automation = {
        ...automation,
        conditions: formattedConditions,
        actions: formattedActions,
      };
    },
    showActionInput(actionName) {
      if (actionName === 'send_email_to_team' || actionName === 'send_message')
        return false;
      const type = AUTOMATION_ACTION_TYPES.find(
        action => action.key === actionName
      ).inputType;
      if (type === null) return false;
      return true;
    },
    getFileName(id, actionType) {
      if (!id) return '';
      if (actionType === 'send_attachment') {
        const file = this.automation.files.find(item => item.blob_id === id);
        // replace `blob_id.toString()` with file name once api is fixed.
        if (file) return file.filename.toString();
      }
      return '';
    },
  },
};
</script>
<style lang="scss" scoped>
.filters-wrap {
  padding: var(--space-normal);
  border-radius: var(--border-radius-large);
  border: 1px solid var(--color-border);
  background: var(--color-background-light);
  margin-bottom: var(--space-normal);
}

.filter-actions {
  margin-top: var(--space-normal);
}
.event_wrapper {
  select {
    margin: var(--space-zero);
  }
  .info-message {
    font-size: var(--font-size-mini);
    color: var(--s-500);
    text-align: right;
  }
  margin-bottom: var(--space-medium);
}
</style>
