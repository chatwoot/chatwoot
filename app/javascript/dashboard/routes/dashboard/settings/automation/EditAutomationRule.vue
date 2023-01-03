<template>
  <div class="column">
    <woot-loading-state
      v-if="uiFlags.isFetching && !automation"
      :message="$t('AUTOMATION.EDIT.LOADING')"
    />
    <div v-if="automation" class="row">
      <div class="small-8 columns with-right-space canvas content-box">
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
      </div>
      <div class="small-4 columns">
        <div class="automation__properties-panel">
          <div class="automation-form">
            <woot-input
              v-model="automation.name"
              :label="$t('AUTOMATION.ADD.FORM.NAME.LABEL')"
              type="text"
              class="automation-form_input"
              :class="{ error: $v.automation.name.$error }"
              :error="
                $v.automation.name.$error
                  ? $t('AUTOMATION.ADD.FORM.NAME.ERROR')
                  : ''
              "
              :placeholder="$t('AUTOMATION.ADD.FORM.NAME.PLACEHOLDER')"
              @blur="$v.automation.name.$touch"
            />
            <label>
              <span>{{ $t('AUTOMATION.ADD.FORM.DESC.LABEL') }}</span>
              <textarea
                v-model="automation.description"
                class="automation-form_input"
                :class="{ error: $v.automation.description.$error }"
                :placeholder="$t('AUTOMATION.ADD.FORM.DESC.PLACEHOLDER')"
                rows="4"
                @blur="$v.automation.description.$touch"
              />
              <p v-if="$v.automation.description.$error" class="message error">
                {{ $t('AUTOMATION.ADD.FORM.DESC.ERROR') }}
              </p>
            </label>
            <div class="event_wrapper">
              <label :class="{ error: $v.automation.event_name.$error }">
                {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
                <select
                  v-model="automation.event_name"
                  @change="onEventChange()"
                >
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
          </div>
          <div>
            <woot-button
              class="automation_form-submit"
              @click="submitAutomation"
            >
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
import automationMethodsMixin from 'dashboard/mixins/automations/methodsMixin';
import automationValidationsMixin from 'dashboard/mixins/automations/validationsMixin';
import filterInputBox from 'dashboard/components/widgets/FilterInput/Index.vue';
import automationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';

import {
  AUTOMATION_RULE_EVENTS,
  AUTOMATION_ACTION_TYPES,
  AUTOMATIONS,
} from './constants';
import { mapGetters } from 'vuex';

export default {
  components: {
    filterInputBox,
    automationActionInput,
  },
  mixins: [alertMixin, automationMethodsMixin, automationValidationsMixin],
  data() {
    return {
      automationTypes: JSON.parse(JSON.stringify(AUTOMATIONS)),
      automationRuleEvent: AUTOMATION_RULE_EVENTS[0].key,
      automationRuleEvents: AUTOMATION_RULE_EVENTS,
      automationActionTypes: AUTOMATION_ACTION_TYPES,
      automationMutated: false,
      show: true,
      automation: null,
      showDeleteConfirmationModal: false,
      allCustomAttributes: [],
      mode: 'edit',
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
    ...mapGetters({
      uiFlags: 'automations/getUIFlags',
    }),
  },
  mounted() {
    this.initialize();
  },
  methods: {
    async initialize() {
      await this.$store.dispatch(
        'automations/getSingleAutomation',
        this.$route.params.automationId
      );
      const automation = this.$store.getters['automations/getAutomation'](
        this.$route.params.automationId
      );
      this.manifestCustomAttributes();
      this.allCustomAttributes = this.$store.getters[
        'attributes/getAttributes'
      ];
      this.formatAutomation(automation);
    },
  },
};
</script>
<style lang="scss" scoped>
.automation__properties-panel {
  padding: var(--space-slab);
  background-color: var(--white);
  height: calc(100vh - 5.6rem);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  border-left: 1px solid var(--s-50);
}

.automation_form-submit {
  width: 100%;
}

.filters-wrap {
  padding: var(--space-normal);
  border-radius: var(--border-radius-large);
  border: 1px solid var(--color-border);
  background-color: white;
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
  }
  margin-bottom: var(--space-medium);
}

.row {
  height: 100%;
}
.canvas {
  background-image: radial-gradient(var(--s-75) 1.2px, transparent 0);
  background-size: var(--space-normal) var(--space-normal);
  height: 100%;
  max-height: 100%;
  padding: var(--space-normal) var(--space-larger);
  max-height: 100vh;
  overflow-y: auto;
}

::v-deep .automation-form_input > [type='text'],
.automation-form_input {
  margin: 0;
}

.message.error {
  color: var(--r-400);
  display: block;
  font-size: 1.4rem;
  font-size: var(--font-size-small);
  font-weight: 400;
  margin-bottom: 1rem;
  width: 100%;
}

textarea.error {
  border: 1px solid var(--r-400);
}

.automation-form > :not([hidden]) ~ :not([hidden]) {
  margin-top: var(--space-one);
  margin-bottom: var(--space-one);
}
</style>
