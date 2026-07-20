<script setup>
import { ref, computed, h, useTemplateRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useOperators } from 'dashboard/components-next/filter/operators';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import {
  generateAutomationPayload,
  getAttributes,
  getFileName,
  showActionInput,
} from 'dashboard/helper/automationHelper';
import { validateAutomation } from 'dashboard/helper/validations';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { AUTOMATION_RULE_EVENTS, AUTOMATION_ACTION_TYPES } from './constants';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['create', 'edit'].includes(value),
  },
  automationTypes: {
    type: Object,
    required: true,
  },
  getConditionDropdownValues: {
    type: Function,
    required: true,
  },
  getActionDropdownValues: {
    type: Function,
    required: true,
  },
  appendNewCondition: {
    type: Function,
    required: true,
  },
  appendNewAction: {
    type: Function,
    required: true,
  },
  removeFilter: {
    type: Function,
    required: true,
  },
  removeAction: {
    type: Function,
    required: true,
  },
  resetAction: {
    type: Function,
    required: true,
  },
  onEventChange: {
    type: Function,
    required: true,
  },
});

const emit = defineEmits(['save']);
const automation = defineModel('automation', { type: Object, default: null });

const INPUT_TYPE_MAP = {
  multi_select: 'multiSelect',
  search_select: 'searchSelect',
  plain_text: 'plainText',
  comma_separated_plain_text: 'plainText',
  date: 'date',
};

const DELAY_UNITS = [
  { key: 'MINUTES', factor: 1 },
  { key: 'HOURS', factor: 60 },
  { key: 'DAYS', factor: 1440 },
];
const MIN_DELAY_MINUTES = 10;
const MAX_DELAY_MINUTES = 43200; // 30 days
// Conversation-level delayed rules can filter on status plus immutable attributes (inbox).
const DELAYED_CONVERSATION_ATTRS = ['status', 'inbox_id'];

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();
const { operators } = useOperators();

const dialogRef = ref(null);
const conditionsRef = useTemplateRef('conditionsRef');
const errors = ref({});
const isDelayed = ref(false);

const isEditMode = computed(() => props.mode === 'edit');

const titleKey = computed(() =>
  isEditMode.value ? 'AUTOMATION.EDIT.TITLE' : 'AUTOMATION.ADD.TITLE'
);
const cancelKey = computed(() =>
  isEditMode.value
    ? 'AUTOMATION.EDIT.CANCEL_BUTTON_TEXT'
    : 'AUTOMATION.ADD.CANCEL_BUTTON_TEXT'
);
const submitKey = computed(() =>
  isEditMode.value ? 'AUTOMATION.EDIT.SUBMIT' : 'AUTOMATION.ADD.SUBMIT'
);

const getTranslatedAttributes = (type, event) => {
  return getAttributes(type, event).map(attribute => {
    const skipTranslation =
      attribute.customAttributeType ||
      ['contact_custom_attribute', 'conversation_custom_attribute'].includes(
        attribute.key
      );
    return {
      ...attribute,
      name: skipTranslation
        ? attribute.name
        : t(`AUTOMATION.ATTRIBUTES.${attribute.name}`),
    };
  });
};

const eventName = computed(() => automation.value?.event_name);

const filterTypes = computed(() => {
  const event = eventName.value;
  if (!event || !props.automationTypes[event]) return [];

  let attributes = getTranslatedAttributes(props.automationTypes, event);
  // A delayed conversation-level rule can filter only on status and immutable attributes (inbox).
  if (isDelayed.value && event !== 'message_created') {
    attributes = attributes.filter(attr =>
      DELAYED_CONVERSATION_ATTRS.includes(attr.key)
    );
  }

  return attributes.map(attr => {
    if (attr.disabled) {
      return { value: attr.key, label: attr.name, disabled: true };
    }

    const mappedInputType = INPUT_TYPE_MAP[attr.inputType] || 'plainText';
    const options = props.getConditionDropdownValues(attr.key) || [];

    // attribute_changed can't be re-evaluated at fire time, so hide it for delayed rules.
    const availableOperators = (attr.filterOperators || []).filter(
      op => !isDelayed.value || op.value !== 'attribute_changed'
    );
    const filterOperators = availableOperators.map(op => {
      const enriched = operators.value[op.value];
      if (enriched) return enriched;
      return {
        value: op.value,
        label: t(`FILTER.OPERATOR_LABELS.${op.value}`),
        hasInput: true,
        inputOverride: null,
        icon: h('span', { class: 'i-ph-equals-bold !text-n-blue-11' }),
      };
    });

    return {
      attributeKey: attr.key,
      value: attr.key,
      attributeName: attr.name,
      label: attr.name,
      inputType: mappedInputType,
      options,
      filterOperators,
      dataType: 'text',
      attributeModel: attr.customAttributeType || 'standard',
    };
  });
});

const automationRuleEvents = computed(() =>
  AUTOMATION_RULE_EVENTS.map(event => ({
    ...event,
    value: t(`AUTOMATION.EVENTS.${event.value}`),
  }))
);

const hasAutomationMutated = computed(() => {
  return Boolean(
    automation.value?.conditions[0]?.values ||
      automation.value?.actions[0]?.action_params?.length
  );
});

const automationActionTypes = computed(() => {
  const actionTypes = isCloudFeatureEnabled('sla')
    ? AUTOMATION_ACTION_TYPES
    : AUTOMATION_ACTION_TYPES.filter(({ key }) => key !== 'add_sla');

  return actionTypes.map(action => ({
    ...action,
    label: t(`AUTOMATION.ACTIONS.${action.label}`),
  }));
});

const hasConditionErrors = computed(() =>
  Object.keys(errors.value).some(key => key.startsWith('condition_'))
);

const hasActionErrors = computed(() =>
  Object.keys(errors.value).some(key => key.startsWith('action_'))
);

const allowsDelayedExecution = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.DELAYED_AUTOMATIONS)
);

// Mirrors the backend's execution_delay validations so we never offer an unsupported delay.
const delayRestrictionReason = computed(() => {
  const conditions = automation.value?.conditions || [];
  if (
    conditions.some(
      condition => condition.filter_operator === 'attribute_changed'
    )
  ) {
    return 'ATTRIBUTE_CHANGED';
  }
  if (
    eventName.value !== 'message_created' &&
    conditions.some(
      condition =>
        condition.attribute_key &&
        !DELAYED_CONVERSATION_ATTRS.includes(condition.attribute_key)
    )
  ) {
    return 'CONVERSATION_NON_STATUS';
  }
  return null;
});

const isDelaySupported = computed(() => delayRestrictionReason.value === null);

// What ends the wait, mirroring the backend episode that arms the rule. Shown to the user so
// they can predict when the rule runs. Conversation rules key on status; message rules key on
// the reply that ends the wait (customer reply for outgoing, agent reply for incoming).
const waitEndsKey = computed(() => {
  if (eventName.value !== 'message_created') return 'STATUS';
  const messageType = (automation.value?.conditions || []).find(
    condition => condition.attribute_key === 'message_type'
  );
  const raw = Array.isArray(messageType?.values)
    ? messageType.values[0]
    : messageType?.values;
  // Raw create-mode values are strings ('outgoing'); edit-mode values are option objects.
  const value = raw && typeof raw === 'object' ? raw.id : raw;
  if (value === 'outgoing') return 'CUSTOMER_REPLY';
  if (value === 'incoming') return 'AGENT_REPLY';
  return 'GENERIC';
});

const delayValue = ref(4);
const delayUnit = ref('HOURS');

const delayInMinutes = computed(() => {
  const factor =
    DELAY_UNITS.find(unit => unit.key === delayUnit.value)?.factor || 1;
  return Math.round(Number(delayValue.value) * factor);
});

const executionDelayInvalid = computed(
  () =>
    isDelayed.value &&
    (!Number.isFinite(delayInMinutes.value) ||
      delayInMinutes.value < MIN_DELAY_MINUTES ||
      delayInMinutes.value > MAX_DELAY_MINUTES)
);

// Hydrate the delay controls from a delay (minutes), using the largest clean unit. Passed in
// by open() rather than read from `automation`, whose model prop only settles a tick later.
const syncDelayFromDelay = delay => {
  isDelayed.value = Boolean(delay);
  if (!delay) {
    delayValue.value = 4;
    delayUnit.value = 'HOURS';
    return;
  }
  const unit =
    [...DELAY_UNITS].reverse().find(u => delay % u.factor === 0) ||
    DELAY_UNITS[0];
  delayUnit.value = unit.key;
  delayValue.value = delay / unit.factor;
};

watch([isDelayed, delayInMinutes], () => {
  if (!automation.value || !allowsDelayedExecution.value) return;
  automation.value.execution_delay = isDelayed.value
    ? delayInMinutes.value
    : null;
});

// Reset to the first attribute the narrowed dropdown still offers for this event, so the
// attribute and its operators are guaranteed to exist (events differ: e.g. conversation_opened
// has no status attribute, only inbox).
const resetToSupportedCondition = () => {
  const [firstType] = filterTypes.value;
  if (!firstType) return;
  automation.value.conditions = [
    {
      attribute_key: firstType.value,
      filter_operator: firstType.filterOperators?.[0]?.value ?? 'equal_to',
      values: '',
      query_operator: 'and',
      custom_attribute_type: '',
    },
  ];
};

// A delay narrows the condition options, so whenever the rule becomes unsupported while the
// wait is on — toggling it on, or switching to an event whose default condition isn't allowed
// (e.g. conversation_opened defaults to browser_language) — reset to a supported default.
// Actions are kept. Resetting makes the rule supported again, so this can't loop.
watch([isDelayed, isDelaySupported], () => {
  if (!isDelayed.value || !automation.value) return;
  if (!isDelaySupported.value) resetToSupportedCondition();
});

watch(
  () => automation.value,
  () => {
    if (Object.keys(errors.value).length) {
      errors.value = {};
    }
  },
  { deep: true }
);

const isConditionsValid = () => {
  if (!conditionsRef.value) return true;
  return conditionsRef.value.every(condition => condition.validate());
};

const resetValidation = () => {
  errors.value = {};
  conditionsRef.value?.forEach(c => c.resetValidation());
};

const syncCustomAttributeTypes = () => {
  automation.value.conditions.forEach(condition => {
    const filterType = filterTypes.value.find(
      ft => ft.attributeKey === condition.attribute_key
    );
    condition.custom_attribute_type =
      filterType?.attributeModel === 'standard'
        ? ''
        : filterType?.attributeModel || '';
  });
};

const open = (executionDelay = null) => {
  resetValidation();
  syncDelayFromDelay(executionDelay);
  dialogRef.value?.open();
};

const close = () => {
  resetValidation();
  dialogRef.value?.close();
};

const emitSaveAutomation = () => {
  syncCustomAttributeTypes();
  const conditionsValid = isConditionsValid();
  errors.value = validateAutomation(automation.value);
  if (allowsDelayedExecution.value && executionDelayInvalid.value) {
    errors.value.execution_delay = true;
  }
  if (Object.keys(errors.value).length === 0 && conditionsValid) {
    const payload = generateAutomationPayload(automation.value);
    // The API rejects the param when the feature is off; existing values are kept server-side.
    if (!allowsDelayedExecution.value) delete payload.execution_delay;
    emit('save', payload, props.mode);
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="3xl"
    position="top"
    :title="$t(titleKey)"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
  >
    <div v-if="automation" class="flex flex-col w-full">
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
        :error="errors.description ? $t('AUTOMATION.ADD.FORM.DESC.ERROR') : ''"
        :placeholder="$t('AUTOMATION.ADD.FORM.DESC.PLACEHOLDER')"
      />
      <div class="mb-6">
        <label :class="{ error: errors.event_name }">
          {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
          <select
            v-model="automation.event_name"
            class="m-0"
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
          <span v-if="errors.event_name" class="message">
            {{ $t('AUTOMATION.ADD.FORM.EVENT.ERROR') }}
          </span>
        </label>
        <p
          v-if="!isEditMode && hasAutomationMutated"
          class="text-xs text-right text-n-teal-10 pt-1"
        >
          {{ $t('AUTOMATION.FORM.RESET_MESSAGE') }}
        </p>
      </div>
      <!-- Conditions Start -->
      <section class="mb-5">
        <label>
          {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.LABEL') }}
        </label>
        <ul
          class="grid gap-4 list-none p-3 mb-4 outline outline-1 rounded-xl -outline-offset-1"
          :class="
            hasConditionErrors
              ? 'outline-n-ruby-5 bg-n-ruby-2/50'
              : 'outline-n-weak dark:outline-n-strong'
          "
        >
          <template v-for="(condition, i) in automation.conditions" :key="i">
            <ConditionRow
              v-if="i === 0"
              ref="conditionsRef"
              v-model:attribute-key="automation.conditions[i].attribute_key"
              v-model:filter-operator="automation.conditions[i].filter_operator"
              v-model:values="automation.conditions[i].values"
              :filter-types="filterTypes"
              :show-query-operator="false"
              @remove="removeFilter(i)"
            />
            <ConditionRow
              v-else
              ref="conditionsRef"
              v-model:attribute-key="automation.conditions[i].attribute_key"
              v-model:filter-operator="automation.conditions[i].filter_operator"
              v-model:query-operator="
                automation.conditions[i - 1].query_operator
              "
              v-model:values="automation.conditions[i].values"
              :filter-types="filterTypes"
              show-query-operator
              @remove="removeFilter(i)"
            />
          </template>
          <div>
            <NextButton
              icon="i-lucide-plus"
              blue
              faded
              sm
              :label="$t('AUTOMATION.ADD.CONDITION_BUTTON_LABEL')"
              @click="appendNewCondition"
            />
          </div>
        </ul>
      </section>
      <!-- Conditions End -->
      <!-- Wait Start -->
      <div v-if="allowsDelayedExecution" class="mb-6">
        <div class="flex items-center justify-between gap-4">
          <label class="mb-0" :class="{ error: errors.execution_delay }">
            {{ $t('AUTOMATION.ADD.FORM.EXECUTE.LABEL') }}
          </label>
          <ToggleSwitch v-model="isDelayed" />
        </div>
        <div v-if="isDelayed" class="flex flex-wrap items-center gap-2 mt-2">
          <span class="text-sm text-n-slate-11">
            {{ $t('AUTOMATION.ADD.FORM.EXECUTE.AFTER_DELAY') }}
          </span>
          <input
            v-model.number="delayValue"
            type="number"
            min="1"
            class="!m-0 !w-24"
          />
          <select v-model="delayUnit" class="!m-0 !w-32">
            <option
              v-for="unit in DELAY_UNITS"
              :key="unit.key"
              :value="unit.key"
            >
              {{ $t(`AUTOMATION.ADD.FORM.EXECUTE.UNITS.${unit.key}`) }}
            </option>
          </select>
        </div>
        <span
          v-if="isDelayed && executionDelayInvalid"
          class="text-xs text-n-ruby-9"
        >
          {{ $t('AUTOMATION.ADD.FORM.EXECUTE.ERROR') }}
        </span>
        <template v-else-if="isDelayed">
          <p class="text-xs text-n-slate-11 pt-2 mb-0">
            <span class="text-n-slate-12 font-medium">
              {{ $t('AUTOMATION.ADD.FORM.EXECUTE.ENDS_IF_LABEL') }}
            </span>
            {{ $t(`AUTOMATION.ADD.FORM.EXECUTE.ENDS_IF.${waitEndsKey}`) }}
          </p>
          <p class="text-xs text-n-slate-11 pt-1 mb-0">
            {{ $t('AUTOMATION.ADD.FORM.EXECUTE.HELP_TEXT') }}
          </p>
        </template>
      </div>
      <!-- Wait End -->
      <!-- Actions Start -->
      <section>
        <label>
          {{ $t('AUTOMATION.ADD.FORM.ACTIONS.LABEL') }}
        </label>
        <ul
          class="grid list-none p-3 mb-4 outline outline-1 rounded-xl -outline-offset-1 border-solid"
          :class="
            hasActionErrors
              ? 'outline-n-ruby-5 bg-n-ruby-2/50'
              : 'outline-n-weak dark:outline-n-strong'
          "
        >
          <AutomationActionInput
            v-for="(action, i) in automation.actions"
            :key="i"
            v-model="automation.actions[i]"
            :action-types="automationActionTypes"
            dropdown-max-height="max-h-[7.5rem]"
            :dropdown-values="getActionDropdownValues(action.action_name)"
            :show-action-input="
              showActionInput(automationActionTypes, action.action_name)
            "
            :error-message="
              errors[`action_${i}`]
                ? $t(`AUTOMATION.ERRORS.${errors[`action_${i}`]}`)
                : ''
            "
            :initial-file-name="
              isEditMode ? getFileName(action, automation.files) : ''
            "
            @reset-action="resetAction(i)"
            @remove-action="removeAction(i)"
          />
          <div class="pt-2">
            <NextButton
              icon="i-lucide-plus"
              blue
              faded
              sm
              :label="$t('AUTOMATION.ADD.ACTION_BUTTON_LABEL')"
              @click="appendNewAction"
            />
          </div>
        </ul>
      </section>
      <!-- Actions End -->
      <div class="w-full mt-8">
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-4">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t(cancelKey)"
            @click.prevent="close"
          />
          <NextButton
            solid
            blue
            type="submit"
            :label="$t(submitKey)"
            @click="emitSaveAutomation"
          />
        </div>
      </div>
    </div>
  </Dialog>
</template>
