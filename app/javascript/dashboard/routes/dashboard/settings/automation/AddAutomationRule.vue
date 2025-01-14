<template>
  <div>
    <woot-modal-header :header-title="$t('AUTOMATION.ADD.TITLE')" />
    <div class="flex flex-col modal-content">
      <div class="w-full">
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
          <p v-if="hasAutomationMutated" class="info-message">
            {{ $t('AUTOMATION.FORM.RESET_MESSAGE') }}
          </p>
        </div>
        <!-- // Conditions Start -->
        <section>
          <label>
            {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.LABEL') }}
          </label>
          <div
            class="w-full p-4 mb-4 border border-solid rounded-lg bg-slate-25 dark:bg-slate-700 border-slate-50 dark:border-slate-700"
          >
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
              :custom-attribute-type="
                getCustomAttributeType(automation.conditions[i].attribute_key)
              "
              :v="$v.automation.conditions.$each[i]"
              @resetFilter="resetFilter(i, automation.conditions[i])"
              @removeFilter="removeFilter(i)"
            />
            <div class="mt-4">
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
          <div
            class="w-full p-4 mb-4 border border-solid rounded-lg bg-slate-25 dark:bg-slate-700 border-slate-50 dark:border-slate-700"
          >
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
              :event-options="eventOptions"
              @resetAction="resetAction(i)"
              @removeAction="removeAction(i)"
            />
            <div class="flex justify-between items-end">
              <div class="mt-4">
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

              <div class="multiselect-wrap--small min-w-[200px]">
                <label class="typo__label">{{
                  $t('AUTOMATION.ADD.INTERVAL')
                }}</label>
                <multiselect
                  class="no-margin"
                  v-model="selectedTimerValue"
                  track-by="value"
                  label="name"
                  selected-label
                  :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
                  deselect-label=""
                  :max-height="160"
                  :options="timerValues"
                  :allow-empty="false"
                  :searchable="false"
                  :option-height="104"
                  @input="onTimerValueChange"
                />
              </div>
              <div
                v-if="selectedTimerValue.value === 'custom'"
                class="flex space-x-2 mt-4 items-end"
              >
                <div class="multiselect-wrap--small min-w-[120px] flex-1">
                  <label class="typo__label">Tipo</label>
                  <multiselect
                    class="no-margin"
                    v-model="customInterval.type"
                    track-by="value"
                    label="label"
                    :max-height="160"
                    :options="intervalTypes"
                    :allow-empty="false"
                    :searchable="false"
                    :option-height="104"
                  />
                </div>
                <div class="flex-1">
                  <label class="typo__label">Valor</label>
                  <input
                    class="!mb-0"
                    v-model="customInterval.amount"
                    type="number"
                    :max="getMaxValue(customInterval.type)"
                    :min="0"
                    :placeholder="$t('Digite a quantidade')"
                  />
                </div>
              </div>
            </div>
          </div>
        </section>
        <!-- // Actions End -->
        <div class="w-full">
          <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
            <woot-button class="button clear" @click.prevent="onClose">
              {{ $t('AUTOMATION.ADD.CANCEL_BUTTON_TEXT') }}
            </woot-button>
            <woot-button @click="submitAutomation">
              {{ $t('AUTOMATION.ADD.SUBMIT') }}
            </woot-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import automationMethodsMixin from 'dashboard/mixins/automations/methodsMixin';
import automationValidationsMixin from 'dashboard/mixins/automations/validationsMixin';
import filterInputBox from 'dashboard/components/widgets/FilterInput/Index.vue';
import automationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import Multiselect from 'vue-multiselect';

import { EVENT_VARIABLES } from './eventVariables';

import {
  AUTOMATION_RULE_EVENTS,
  AUTOMATION_RULE_INTEGRATION_EVENTS,
  AUTOMATIONS,
  INTERVAL_TYPES,
} from './constants';

export default {
  components: {
    filterInputBox,
    automationActionInput,
    Multiselect,
  },
  mixins: [automationMethodsMixin, automationValidationsMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },

  data() {
    return {
      automationTypes: JSON.parse(JSON.stringify(AUTOMATIONS)),
      intervalTypes: JSON.parse(JSON.stringify(INTERVAL_TYPES)),
      automationMutated: false,
      showTimerAction: false,
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
            custom_attribute_type: '',
          },
        ],
        actions: [
          {
            action_name: 'add_contact_label',
            action_params: [],
          },
        ],
        delay: null,
        delay_type: null,
      },
      showDeleteConfirmationModal: false,
      allCustomAttributes: [],
      mode: 'create',
      selectedTimerValue: {
        type: 'none',
        name: this.$t('AUTOMATION.ADD.INTERVALS.NONE'),
        value: null,
      },
      customInterval: {
        type: { value: 'minutes', label: 'minutes' },
        amount: 0,
      },
      timerParams: '',
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    hasAutomationMutated() {
      if (
        this.automation.conditions[0].values ||
        this.automation.actions[0].action_params.length
      )
        return true;
      return false;
    },

    timerValues() {
      return [
        {
          name: this.$t('AUTOMATION.ADD.INTERVALS.NONE'),
          type: 'none',
          value: null,
        },
        {
          name: this.$t('AUTOMATION.ADD.INTERVALS.1HOUR'),
          type: 'hours',
          value: 3600,
        },
        {
          name: this.$t('AUTOMATION.ADD.INTERVALS.1DAY'),
          type: 'days',
          value: 86400,
        },
        {
          name: this.$t('AUTOMATION.ADD.INTERVALS.3DAY'),
          type: 'days',
          value: 259200,
        },
        {
          name: this.$t('AUTOMATION.ADD.INTERVALS.7DAY'),
          type: 'days',
          value: 604800,
        },
        {
          name: this.$t('AUTOMATION.ADD.INTERVALS.CUSTOM'),
          type: 'none',
          value: 'custom',
        },
      ];
    },

    eventOptions() {
      return EVENT_VARIABLES[this.automation.event_name];
    },
    automationActionTypes() {
      const isSLAEnabled = this.isFeatureEnabled('sla');
      const actions = this.automationTypes[this.automation.event_name]?.actions;
      return isSLAEnabled
        ? actions
        : actions.filter(action => action.key !== 'add_sla');
    },

    computedDelay() {
      const { type, amount } = this.customInterval;
      if (this.timerValues[0].value !== 'custom') {
        return this.timerValues[0].value;
      }
      switch (type.value) {
        case 'minutes':
          return amount * 60;
        case 'hours':
          return amount * 3600;
        case 'days':
          return amount * 86400;
        default:
          return 0;
      }
    },

    automationRuleEvents() {
      const isIntegrationEnabled = this.isFeatureEnabled('integrations_view');
      return isIntegrationEnabled
        ? AUTOMATION_RULE_EVENTS.concat(AUTOMATION_RULE_INTEGRATION_EVENTS)
        : AUTOMATION_RULE_EVENTS;
    },
  },
  mounted() {
    this.$store.dispatch('inboxes/get');
    this.$store.dispatch('agents/get');
    this.$store.dispatch('contacts/get');
    this.$store.dispatch('teams/get');
    this.$store.dispatch('labels/get');
    this.$store.dispatch('campaigns/get');
    this.allCustomAttributes = this.$store.getters['attributes/getAttributes'];
    this.manifestCustomAttributes();
  },

  watch: {
    customInterval: {
      handler(value) {
        if (this.selectedTimerValue.value === 'custom') {
          this.setCustomTime(value);
        }
      },
      deep: true,
    },  

    'customInterval.type'(type) {
      this.customInterval.amount = 1;
    },
    'customInterval.amount'(amount) {
      if (amount > this.getMaxValue(this.customInterval.type)) {
        this.customInterval.amount = 0;
      }
    },
    'automation.event_name'(name) {
      if (name === 'cart_recovery') {
        this.automation.conditions = [
          {
            key: 'none',
            name: 'None',
            attributeI18nKey: 'NONE',
            inputType: 'plain_text',
            filterOperators: OPERATOR_TYPES_1,
          },
        ];
      }
    },
  },
  methods: {
    isFeatureEnabled(flag) {
      return this.isFeatureEnabledonAccount(this.accountId, flag);
    },

    onTimerValueChange(interval) {
      this.selectedTimerValue = interval;

      if (interval.value === 'custom') {
        this.setCustomTime(this.customInterval);
      } else {
        this.setDefaultTime(interval);
      }
    },

    setCustomTime(interval) {
      const { type, amount } = interval;
      const amountInSeconds = this.amountToSeconds(
        type.value,
        parseInt(amount)
      );
      (this.automation.delay_type = type.value),
        (this.automation.delay = amountInSeconds || 0);
    },

    setDefaultTime(interval) {
      (this.automation.delay_type = interval.type),
        (this.automation.delay = interval.value);
    },

    amountToSeconds(type, amount) {
      switch (type) {
        case 'minutes':
          return amount * 60;
        case 'hours':
          return amount * 3600;
        case 'days':
          return amount * 86400;
        default:
          return 0;
      }
    },
    getMaxValue(type) {
      switch (type.value) {
        case 'days':
          return 7;
        case 'hours':
          return 23;
        case 'minutes':
          return 59;
        default:
          return 0;
      }
    },

  },
};
</script>
<style lang="scss" scoped>
.event_wrapper {
  select {
    @apply m-0;
  }
  .info-message {
    @apply text-xs text-green-500 dark:text-green-500 text-right;
  }

  @apply mb-6;
}
</style>
