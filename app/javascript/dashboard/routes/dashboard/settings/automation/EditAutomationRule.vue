<template>
  <div>
    <woot-modal-header :header-title="$t('AUTOMATION.EDIT.TITLE')" />
    <div class="flex flex-col modal-content">
      <div v-if="automation" class="w-full">
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
              :custom-attribute-type="
                getCustomAttributeType(automation.conditions[i].attribute_key)
              "
              :show-query-operator="i !== automation.conditions.length - 1"
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
              :dropdown-values="getActionDropdownValues(action.action_name)"
              :show-action-input="showActionInput(action.action_name)"
              :v="$v.automation.actions.$each[i]"
              :initial-file-name="getFileName(action, automation.files)"
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
import { mapGetters } from 'vuex';
import automationMethodsMixin from 'dashboard/mixins/automations/methodsMixin';
import automationValidationsMixin from 'dashboard/mixins/automations/validationsMixin';
import filterInputBox from 'dashboard/components/widgets/FilterInput/Index.vue';
import automationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';

import {
  AUTOMATION_RULE_EVENTS,
  AUTOMATION_RULE_INTEGRATION_EVENTS,
  AUTOMATIONS,
  INTERVAL_TYPES,
  AUTOMATION_ACTION_TYPES,
} from './constants';

import { EVENT_VARIABLES } from './eventVariables';

export default {
  components: {
    filterInputBox,
    automationActionInput,
  },
  mixins: [automationMethodsMixin, automationValidationsMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
    selectedResponse: {
      type: Object,
      default: () => {},
    },
    timerValues: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      automationTypes: JSON.parse(JSON.stringify(AUTOMATIONS)),
      intervalTypes: JSON.parse(JSON.stringify(INTERVAL_TYPES)),
      automationRuleEvent: AUTOMATION_RULE_EVENTS[0].key,
      automationMutated: false,
      show: true,
      automation: null,
      showDeleteConfirmationModal: false,
      allCustomAttributes: [],
      mode: 'edit',
      selectedTimerValue: {
        name: this.$t('AUTOMATION.ADD.INTERVALS.CUSTOM'),
        type: 'none',
        value: 'custom',
      },
      customInterval: {
        type: {
          value: this.selectedResponse.delay_type,
          label: this.selectedResponse.delay_type,
        },
        amount: this.secondsToAmount(
          this.selectedResponse.delay_type,
          this.selectedResponse.delay
        ),
      },
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
    automationActionTypes() {
      const isSLAEnabled = this.isFeatureEnabled('sla');

      const eventName = this.automation?.event_name ?? this.automationRuleEvent;

      const actions = this.automationTypes[eventName]?.actions;

      return isSLAEnabled
        ? actions
        : actions?.filter(action => action.key !== 'add_sla');
    },

    eventOptions() {
      return EVENT_VARIABLES[this.automation.event_name];
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
    this.manifestCustomAttributes();
    this.allCustomAttributes = this.$store.getters['attributes/getAttributes'];
    this.formatAutomation(this.selectedResponse);
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

    filterSendTemplateOption(actionTypes) {
      if (this.automation) {
        const hasWhatsappChannel = this.automation.conditions.some(
          condition => {
            if (Array.isArray(condition.values)) {
              return condition.values.some(
                value => value.channel_type === 'Channel::Whatsapp'
              );
            }
            return false;
          }
        );

        if (!hasWhatsappChannel) {
          return actionTypes.filter(action => action.key !== 'send_template');
        }
      }

      return actionTypes;
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

    secondsToAmount(type, amount) {
      switch (type) {
        case 'minutes':
          return amount / 60;
        case 'hours':
          return amount / 3600;
        case 'days':
          return amount / 86400;
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
