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
        this.automation?.conditions?.[0]?.values ||
        this.automation?.actions?.[0]?.action_params?.length
      ) {
        return true;
      }
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
  <div class="flex h-auto max-h-[min(85vh,48rem)] flex-col overflow-hidden">
    <woot-modal-header :header-title="$t('AUTOMATION.EDIT.TITLE')" />
    <div
      class="modal-content flex min-h-0 flex-1 flex-col overflow-y-auto px-1 pb-1 pt-2"
    >
      <div v-if="automation" class="flex w-full flex-col gap-5">
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
        <div class="mb-0">
          <label class="block" :class="{ error: errors.event_name }">
            <span
              class="mb-2 block text-xs font-semibold uppercase tracking-wider text-on-surface-variant"
            >
              {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
            </span>
            <select
              v-model="automation.event_name"
              class="!m-0"
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
            class="mb-0 pt-2 text-end text-xs text-secondary"
          >
            {{ $t('AUTOMATION.FORM.RESET_MESSAGE') }}
          </p>
        </div>
        <!-- // Conditions Start -->
        <section class="mb-0">
          <span
            class="mb-2 block text-xs font-semibold uppercase tracking-wider text-on-surface-variant"
          >
            {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.LABEL') }}
          </span>
          <div
            class="mb-0 w-full rounded-xl border border-outline-variant/20 bg-surface-container-lowest/50 p-4 shadow-sm"
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
                teal
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
        <section class="mb-0">
          <span
            class="mb-2 block text-xs font-semibold uppercase tracking-wider text-on-surface-variant"
          >
            {{ $t('AUTOMATION.ADD.FORM.ACTIONS.LABEL') }}
          </span>
          <div
            class="mb-0 w-full rounded-xl border border-outline-variant/20 bg-surface-container-lowest/50 p-4 shadow-sm"
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
                teal
                faded
                sm
                :label="$t('AUTOMATION.ADD.ACTION_BUTTON_LABEL')"
                @click="appendNewAction"
              />
            </div>
          </div>
        </section>
        <!-- // Actions End -->
        <div
          class="mt-2 flex w-full flex-row justify-end gap-2 border-t border-outline-variant/15 pt-4"
        >
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('AUTOMATION.EDIT.CANCEL_BUTTON_TEXT')"
            @click.prevent="onClose"
          />
          <NextButton
            solid
            teal
            type="submit"
            :label="$t('AUTOMATION.EDIT.SUBMIT')"
            @click="emitSaveAutomation"
          />
        </div>
      </div>
    </div>
  </div>
</template>
