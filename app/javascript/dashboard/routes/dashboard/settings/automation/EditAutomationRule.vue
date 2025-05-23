<script>
import { mapGetters } from 'vuex';
import { useAutomation } from 'dashboard/composables/useAutomation';
import { useEditableAutomation } from 'dashboard/composables/useEditableAutomation';
import FilterInputBox from 'dashboard/components/widgets/FilterInput/Index.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import {
  getFileName,
  generateAutomationPayload,
  getAttributes,
  getInputType,
  getOperators,
  getCustomAttributeType,
  showActionInput,
} from 'dashboard/helper/automationHelper';
import { validateAutomation } from 'dashboard/helper/validations';

import { AUTOMATION_RULE_EVENTS, AUTOMATION_ACTION_TYPES } from './constants';

export default {
  components: {
    FilterInputBox,
    NextButton,
    AutomationActionInput,
  },
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
    } = useAutomation();
    const { formatAutomation } = useEditableAutomation();
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
      formatAutomation,
      manifestCustomAttributes,
    };
  },
  data() {
    return {
      automationRuleEvent: AUTOMATION_RULE_EVENTS[0].key,
      automationMutated: false,
      show: true,
      showDeleteConfirmationModal: false,
      allCustomAttributes: [],
      mode: 'edit',
      errors: {},
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    automationRuleEvents() {
      return AUTOMATION_RULE_EVENTS.map(event => ({
        ...event,
        value: this.$t(`AUTOMATION.EVENTS.${event.value}`),
      }));
    },
    hasAutomationMutated() {
      if (
        this.automation.conditions[0].values ||
        this.automation.actions[0].action_params.length
      )
        return true;
      return false;
    },
    automationActionTypes() {
      const actionTypes = this.isFeatureEnabled('sla')
        ? AUTOMATION_ACTION_TYPES
        : AUTOMATION_ACTION_TYPES.filter(({ key }) => key !== 'add_sla');

      return actionTypes.map(action => ({
        ...action,
        label: this.$t(`AUTOMATION.ACTIONS.${action.label}`),
      }));
    },
  },
  mounted() {
    this.manifestCustomAttributes();
    this.allCustomAttributes = this.$store.getters['attributes/getAttributes'];

    this.automation = this.formatAutomation(
      this.selectedResponse,
      this.allCustomAttributes,
      this.automationTypes,
      this.automationActionTypes
    );
  },
  methods: {
    getFileName,
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
    getTranslatedAttributes(type, event) {
      return getAttributes(type, event).map(attribute => {
        // Skip translation
        // 1. If customAttributeType key is present then its rendering attributes from API
        // 2. If contact_custom_attribute or conversation_custom_attribute is present then its rendering section title
        const skipTranslation =
          attribute.customAttributeType ||
          [
            'contact_custom_attribute',
            'conversation_custom_attribute',
          ].includes(attribute.key);

        return {
          ...attribute,
          name: skipTranslation
            ? attribute.name
            : this.$t(`AUTOMATION.ATTRIBUTES.${attribute.name}`),
        };
      });
    },
  },
};
</script>

<template>
  <div>
    <woot-modal-header :header-title="$t('AUTOMATION.EDIT.TITLE')" />
    <div class="flex flex-col modal-content">
      <div v-if="automation" class="w-full">
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
        <div class="event_wrapper">
          <label :class="{ error: errors.event_name }">
            {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
            <select
              v-model="automation.event_name"
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
        </div>
        <!-- // Conditions Start -->
        <section>
          <label>
            {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.LABEL') }}
          </label>
          <div
            class="w-full p-4 mb-4 border border-solid rounded-lg bg-n-slate-2 dark:bg-n-solid-2 border-n-strong"
          >
            <FilterInputBox
              v-for="(condition, i) in automation.conditions"
              :key="i"
              v-model="automation.conditions[i]"
              :filter-attributes="
                getTranslatedAttributes(automationTypes, automation.event_name)
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
              :custom-attribute-type="
                getCustomAttributeType(
                  automationTypes,
                  automation,
                  automation.conditions[i].attribute_key
                )
              "
              :show-query-operator="i !== automation.conditions.length - 1"
              :error-message="
                errors[`condition_${i}`]
                  ? $t(`AUTOMATION.ERRORS.${errors[`condition_${i}`]}`)
                  : ''
              "
              @reset-filter="resetFilter(i, automation.conditions[i])"
              @remove-filter="removeFilter(i)"
            />
            <div class="mt-4">
              <NextButton
                icon="i-lucide-plus"
                blue
                faded
                sm
                :label="$t('AUTOMATION.ADD.CONDITION_BUTTON_LABEL')"
                @click="appendNewCondition"
              />
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
            class="w-full p-4 mb-4 border border-solid rounded-lg bg-n-slate-2 dark:bg-n-solid-2 border-n-strong"
          >
            <AutomationActionInput
              v-for="(action, i) in automation.actions"
              :key="i"
              v-model="automation.actions[i]"
              :action-types="automationActionTypes"
              :dropdown-values="getActionDropdownValues(action.action_name)"
              :show-action-input="
                showActionInput(automationActionTypes, action.action_name)
              "
              :error-message="
                errors[`action_${i}`]
                  ? $t(`AUTOMATION.ERRORS.${errors[`action_${i}`]}`)
                  : ''
              "
              :initial-file-name="getFileName(action, automation.files)"
              @reset-action="resetAction(i)"
              @remove-action="removeAction(i)"
            />
            <div class="mt-4">
              <NextButton
                icon="i-lucide-plus"
                blue
                faded
                sm
                :label="$t('AUTOMATION.ADD.ACTION_BUTTON_LABEL')"
                @click="appendNewAction"
              />
            </div>
          </div>
        </section>
        <!-- // Actions End -->
        <div class="w-full">
          <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
            <NextButton
              faded
              slate
              type="reset"
              :label="$t('AUTOMATION.EDIT.CANCEL_BUTTON_TEXT')"
              @click.prevent="onClose"
            />
            <NextButton
              solid
              blue
              type="submit"
              :label="$t('AUTOMATION.EDIT.SUBMIT')"
              @click="emitSaveAutomation"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

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
