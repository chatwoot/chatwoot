<template>
  <div class="column">
    <woot-modal-header :header-title="$t('AUTOMATION.ADD.TITLE')" />
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
          <p v-if="hasAutomationMutated" class="info-message">
            {{ $t('AUTOMATION.FORM.RESET_MESSAGE') }}
          </p>
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
              :custom-attribute-type="
                getCustomAttributeType(automation.conditions[i].attribute_key)
              "
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
              @resetAction="resetAction(i)"
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
import alertMixin from 'shared/mixins/alertMixin';
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
  mixins: [alertMixin, automationMethodsMixin, automationValidationsMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },

  data() {
    return {
      automationTypes: JSON.parse(JSON.stringify(AUTOMATIONS)),
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
            custom_attribute_type: '',
          },
        ],
        actions: [
          {
            action_name: 'assign_agent',
            action_params: [],
          },
        ],
      },
      showDeleteConfirmationModal: false,
      allCustomAttributes: [],
      mode: 'create',
    };
  },
  computed: {
    hasAutomationMutated() {
      if (
        this.automation.conditions[0].values ||
        this.automation.actions[0].action_params.length
      )
        return true;
      return false;
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
