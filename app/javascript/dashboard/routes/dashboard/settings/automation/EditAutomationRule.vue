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
              @resetAction="resetAction(i)"
              @removeAction="removeAction(i)"
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
  AUTOMATION_ACTION_TYPES,
  AUTOMATIONS,
} from './constants';

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
  },
  data() {
    return {
      automationTypes: JSON.parse(JSON.stringify(AUTOMATIONS)),
      automationRuleEvent: AUTOMATION_RULE_EVENTS[0].key,
      automationRuleEvents: AUTOMATION_RULE_EVENTS,
      automationMutated: false,
      show: true,
      automation: null,
      showDeleteConfirmationModal: false,
      allCustomAttributes: [],
      mode: 'edit',
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
    this.manifestCustomAttributes();
    this.allCustomAttributes = this.$store.getters['attributes/getAttributes'];
    this.formatAutomation(this.selectedResponse);
  },
  methods: {
    isFeatureEnabled(flag) {
      return this.isFeatureEnabledonAccount(this.accountId, flag);
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
