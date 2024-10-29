<script>
import { mapGetters } from 'vuex';
import FilterInputBox from 'dashboard/components/widgets/FilterInput/Index.vue';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import { useAutomation } from 'dashboard/composables/useAutomation';
import { validateAutomation } from 'dashboard/helper/validations';
import {
  generateAutomationPayload,
  getAttributes,
  getInputType,
  getOperators,
  getCustomAttributeType,
  showActionInput,
} from 'dashboard/helper/automationHelper';
import { AUTOMATION_RULE_EVENTS, AUTOMATION_ACTION_TYPES } from './constants';

const start_value = {
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
      action_name: 'assign_agent',
      action_params: [],
    },
  ],
};

export default {
  components: {
    FilterInputBox,
    AutomationActionInput,
  },
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  emits: ['saveAutomation'],
  setup() {
    const {
      automation,
      automationTypes,
      onEventChange,
      getConditionDropdownValues,
      appendNewCondition,
      appendNewAction,
      removeFilter,
      removeAction,
      resetFilter,
      resetAction,
      getActionDropdownValues,
      manifestCustomAttributes,
    } = useAutomation(start_value);
    return {
      automation,
      automationTypes,
      onEventChange,
      getConditionDropdownValues,
      appendNewCondition,
      appendNewAction,
      removeFilter,
      removeAction,
      resetFilter,
      resetAction,
      getActionDropdownValues,
      manifestCustomAttributes,
    };
  },
  data() {
    return {
      automationRuleEvent: AUTOMATION_RULE_EVENTS[0].key,
      automationRuleEvents: AUTOMATION_RULE_EVENTS,
      automationMutated: false,
      show: true,
      showDeleteConfirmationModal: false,
      allCustomAttributes: [],
      mode: 'create',
      errors: {},
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
      return isSLAEnabled
        ? AUTOMATION_ACTION_TYPES
        : AUTOMATION_ACTION_TYPES.filter(action => action.key !== 'add_sla');
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
  methods: {
    getAttributes,
    getInputType,
    getOperators,
    getCustomAttributeType,
    showActionInput,
    isFeatureEnabled(flag) {
      return this.isFeatureEnabledonAccount(this.accountId, flag);
    },
    emitSaveAutomation() {
      this.errors = validateAutomation(this.automation);
      if (Object.keys(this.errors).length === 0) {
        const automation = generateAutomationPayload(this.automation);
        this.$emit('saveAutomation', automation, this.mode);
      }
    },
  },
};
</script>

<template>
  <div>
    <woot-modal-header :header-title="$t('AUTOMATION.ADD.TITLE')" />
    <div class="flex flex-col modal-content">
      <div class="w-full">
        <woot-input
          v-model="automation.name"
          :label="$t('AUTOMATION.ADD.FORM.NAME.LABEL')"
          type="text"
          :class="{ error: errors.name }"
          :error="errors.name ? $t('AUTOMATION.ADD.FORM.NAME.ERROR') : ''"
          :placeholder="$t('AUTOMATION.ADD.FORM.NAME.PLACEHOLDER')"
        />
        <woot-input
          v-model="automation.description"
          :label="$t('AUTOMATION.ADD.FORM.DESC.LABEL')"
          type="text"
          :class="{ error: errors.description }"
          :error="
            errors.description ? $t('AUTOMATION.ADD.FORM.DESC.ERROR') : ''
          "
          :placeholder="$t('AUTOMATION.ADD.FORM.DESC.PLACEHOLDER')"
        />
        <div class="mb-6">
          <label :class="{ error: errors.event_name }">
            {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
            <select
              v-model="automation.event_name"
              class="m-0"
              @change="onEventChange(automation)"
            >
              <option
                v-for="event in automationRuleEvents"
                :key="event.key"
                :value="event.key"
              >
                {{ event.value }}
              </option>
            </select>
            <span v-if="errors.event_name" class="message">
              {{ $t('AUTOMATION.ADD.FORM.EVENT.ERROR') }}
            </span>
          </label>
          <p
            v-if="hasAutomationMutated"
            class="text-xs text-right text-green-500 dark:text-green-500"
          >
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
            <FilterInputBox
              v-for="(condition, i) in automation.conditions"
              :key="i"
              v-model="automation.conditions[i]"
              :filter-attributes="
                getAttributes(automationTypes, automation.event_name)
              "
              :input-type="
                getInputType(
                  allCustomAttributes,
                  automationTypes,
                  automation,
                  automation.conditions[i].attribute_key
                )
              "
              :operators="
                getOperators(
                  allCustomAttributes,
                  automationTypes,
                  automation,
                  mode,
                  automation.conditions[i].attribute_key
                )
              "
              :dropdown-values="
                getConditionDropdownValues(
                  automation.conditions[i].attribute_key
                )
              "
              :show-query-operator="i !== automation.conditions.length - 1"
              :custom-attribute-type="
                getCustomAttributeType(
                  automationTypes,
                  automation,
                  automation.conditions[i].attribute_key
                )
              "
              :error-message="
                errors[`condition_${i}`]
                  ? $t(`AUTOMATION.ERRORS.${errors[`condition_${i}`]}`)
                  : ''
              "
              @reset-filter="resetFilter(i, automation.conditions[i])"
              @remove-filter="removeFilter(i)"
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
            <AutomationActionInput
              v-for="(action, i) in automation.actions"
              :key="i"
              v-model="automation.actions[i]"
              :action-types="automationActionTypes"
              :dropdown-values="
                getActionDropdownValues(automation.actions[i].action_name)
              "
              :show-action-input="
                showActionInput(
                  automationActionTypes,
                  automation.actions[i].action_name
                )
              "
              :error-message="
                errors[`action_${i}`]
                  ? $t(`AUTOMATION.ERRORS.${errors[`action_${i}`]}`)
                  : ''
              "
              @reset-action="resetAction(i)"
              @remove-action="removeAction(i)"
            />
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
          </div>
        </section>
        <!-- // Actions End -->
        <div class="w-full">
          <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
            <woot-button class="button clear" @click.prevent="onClose">
              {{ $t('AUTOMATION.ADD.CANCEL_BUTTON_TEXT') }}
            </woot-button>
            <woot-button @click="emitSaveAutomation">
              {{ $t('AUTOMATION.ADD.SUBMIT') }}
            </woot-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
