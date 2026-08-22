<script setup>
import { ref, computed, h, useTemplateRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useOperators } from 'dashboard/components-next/filter/operators';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import {
  generateAutomationPayload,
  getActionIcon,
  getAttributes,
} from 'dashboard/helper/automationHelper';
import { getAttributeIcon } from 'dashboard/components-next/filter/helper/filterAttributeIcons';
import { provideDropdownTeleport } from 'dashboard/components-next/dropdown-menu/base/provider';
import { validateAutomation } from 'dashboard/helper/validations';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';
import {
  AUTOMATION_RULE_EVENTS,
  AUTOMATION_ACTION_TYPES,
  DEFAULT_DELAY_MINUTES,
} from './constants';
import AutomationRunTypeSelector from './components/AutomationRunTypeSelector.vue';
import AutomationWaitCondition from './components/AutomationWaitCondition.vue';
import AutomationInstantTrigger from './components/AutomationInstantTrigger.vue';
import AutomationActions from './components/AutomationActions.vue';

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

const DATE_SCHEDULE_ATTRIBUTE_TYPES = new Set(['date', 'datetime']);

const automation = defineModel('automation', { type: Object, default: null });

const INPUT_TYPE_MAP = {
  multi_select: 'multiSelect',
  search_select: 'searchSelect',
  plain_text: 'plainText',
  comma_separated_plain_text: 'plainText',
  date: 'date',
  datetime: 'datetime',
};

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();
const { operators } = useOperators();
const customAttributes = useMapGetter('attributes/getAttributes');

provideDropdownTeleport();

const panelRef = ref(null);
const instantTriggerRef = useTemplateRef('instantTriggerRef');
const errors = ref({});

const isEditMode = computed(() => props.mode === 'edit');

const scheduleDateAttributeOptions = computed(() => {
  const options = (customAttributes.value || [])
    .filter(
      attr =>
        attr.attribute_model === 'conversation_attribute' &&
        DATE_SCHEDULE_ATTRIBUTE_TYPES.has(String(attr.attribute_display_type))
    )
    .map(attr => {
      const base = attr.attribute_display_name || attr.attribute_key;
      const label =
        attr.attribute_display_type === 'datetime'
          ? `${base} (${t('AUTOMATION.ADD.FORM.SCHEDULE.ATTRIBUTE_TYPE_DATETIME')})`
          : base;
      return {
        key: attr.attribute_key,
        label,
        type: attr.attribute_display_type,
      };
    })
    .sort((a, b) => a.label.localeCompare(b.label));

  // Keep orphan keys from saved rules selectable (renamed/deleted CA).
  const currentKey = automation.value?.schedule?.attribute_key;
  if (currentKey && !options.some(option => option.key === currentKey)) {
    options.unshift({
      key: currentKey,
      label: t('AUTOMATION.ADD.FORM.SCHEDULE.ATTRIBUTE_KEY_ORPHAN', {
        key: currentKey,
      }),
      type: 'unknown',
    });
  }

  return options;
});

const allowsDelayedExecution = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.DELAYED_AUTOMATIONS)
);

// The wait lives here rather than in the wait section so that switching between the two run
// types doesn't discard a duration the user already typed in.
const isDelayed = ref(false);
const isSavedWait = ref(false);
const delayMinutes = ref(DEFAULT_DELAY_MINUTES);
const delayUnit = ref(DURATION_UNITS.HOURS);
// Bumped on every open() so the wait section remounts and re-reads the rule it is given.
const waitSectionKey = ref(0);

const executionDelayInvalid = computed(
  () => isDelayed.value && !Number.isFinite(delayMinutes.value)
);

const statusOptions = computed(() =>
  (props.getConditionDropdownValues('status') || [])
    .filter(option => option.id !== 'all')
    .map(option => ({ value: option.id, label: option.name }))
);

const inboxOptions = computed(
  () => props.getConditionDropdownValues('inbox_id') || []
);

// Show the wait in the largest whole unit (240 min → 4 hours). The delay is passed in by open()
// rather than read from `automation`, whose model prop only settles a tick later.
const syncDelayState = executionDelay => {
  isDelayed.value = Boolean(executionDelay);
  isSavedWait.value = isEditMode.value && Boolean(executionDelay);
  const minutes = executionDelay || DEFAULT_DELAY_MINUTES;
  if (minutes % 1440 === 0) delayUnit.value = DURATION_UNITS.DAYS;
  else if (minutes % 60 === 0) delayUnit.value = DURATION_UNITS.HOURS;
  else delayUnit.value = DURATION_UNITS.MINUTES;
  delayMinutes.value = minutes;
  waitSectionKey.value += 1;
};

watch([isDelayed, delayMinutes], () => {
  // Switching to "run instantly" hands the conditions back to the instant editor.
  if (!isDelayed.value) isSavedWait.value = false;

  if (!automation.value || !allowsDelayedExecution.value) return;
  automation.value.execution_delay = isDelayed.value
    ? delayMinutes.value
    : null;
});

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
const isTimeTriggered = computed(() => eventName.value === 'time_triggered');

const ensureSchedule = () => {
  if (!automation.value.schedule) {
    automation.value.schedule = {
      kind: 'hours_since_last_outgoing',
      hours: 24,
    };
  }
  if (
    automation.value.schedule.kind === 'days_since_attribute' &&
    !automation.value.schedule.relative_to
  ) {
    automation.value.schedule.relative_to = 'after';
  }
};

const scheduleRelativeTo = computed({
  get: () => automation.value?.schedule?.relative_to || 'after',
  set: value => {
    if (!automation.value.schedule) automation.value.schedule = {};
    automation.value.schedule.relative_to = value;
  },
});

const showScheduleDays = computed(
  () =>
    automation.value?.schedule?.kind === 'days_since_attribute' &&
    scheduleRelativeTo.value !== 'on'
);

watch(
  isTimeTriggered,
  enabled => {
    if (enabled) ensureSchedule();
  },
  { immediate: true }
);

watch(
  () => automation.value?.schedule?.kind,
  kind => {
    if (kind === 'days_since_attribute' && automation.value?.schedule) {
      if (!automation.value.schedule.relative_to) {
        automation.value.schedule.relative_to = 'after';
      }
    }
  }
);

const filterTypes = computed(() => {
  const event = eventName.value;
  if (!event || !props.automationTypes[event]) return [];

  const attributes = getTranslatedAttributes(props.automationTypes, event);

  return attributes.map(attr => {
    if (attr.disabled) {
      return { value: attr.key, label: attr.name, disabled: true };
    }

    const mappedInputType = INPUT_TYPE_MAP[attr.inputType] || 'plainText';
    const options = props.getConditionDropdownValues(attr.key) || [];

    const filterOperators = (attr.filterOperators || []).map(op => {
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
      icon: getAttributeIcon({
        attributeKey: attr.key,
        attributeDisplayType: attr.attributeDisplayType,
      }),
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
  const firstActionParams = automation.value?.actions[0]?.action_params;
  const hasActionParams = Array.isArray(firstActionParams)
    ? firstActionParams.length > 0
    : Boolean(
        firstActionParams &&
          typeof firstActionParams === 'object' &&
          Object.keys(firstActionParams).length
      );

  return Boolean(automation.value?.conditions[0]?.values || hasActionParams);
});

const automationActionTypes = computed(() => {
  const actionTypes = isCloudFeatureEnabled('sla')
    ? AUTOMATION_ACTION_TYPES
    : AUTOMATION_ACTION_TYPES.filter(({ key }) => key !== 'add_sla');

  return actionTypes.map(action => ({
    ...action,
    label: t(`AUTOMATION.ACTIONS.${action.label}`),
    icon: getActionIcon(action.key),
  }));
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

const isConditionsValid = () => instantTriggerRef.value?.validate() ?? true;

const resetValidation = () => {
  errors.value = {};
  instantTriggerRef.value?.resetValidation();
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
  syncDelayState(executionDelay);
  panelRef.value?.open();
};

const close = () => {
  resetValidation();
  panelRef.value?.close();
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
<SidePanel ref="panelRef" width="3xl" :title="$t(titleKey)">
    <div v-if="automation" class="flex flex-col w-full gap-6">
      <div class="flex flex-col">
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
      </div>
      <section v-if="isTimeTriggered" class="flex flex-col gap-3">
        <label>{{ $t('AUTOMATION.ADD.FORM.SCHEDULE.LABEL') }}</label>
        <div
          class="grid gap-3 p-3 outline outline-1 rounded-xl -outline-offset-1 outline-n-weak dark:outline-n-strong"
        >
          <label class="text-sm text-n-slate-11">
            {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.KIND') }}
            <select v-model="automation.schedule.kind" class="mt-1 w-full m-0">
              <option value="days_since_attribute">
                {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.KINDS.DAYS_SINCE') }}
              </option>
              <option value="hours_since_last_outgoing">
                {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.KINDS.HOURS_OUTGOING') }}
              </option>
              <option value="hours_since_last_incoming">
                {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.KINDS.HOURS_INCOMING') }}
              </option>
            </select>
          </label>
          <label
            v-if="automation.schedule.kind === 'days_since_attribute'"
            class="text-sm text-n-slate-11"
          >
            {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.ATTRIBUTE_KEY') }}
            <select
              v-model="automation.schedule.attribute_key"
              class="mt-1 w-full m-0"
            >
              <option value="">
                {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.ATTRIBUTE_KEY_EMPTY') }}
              </option>
              <option
                v-for="attr in scheduleDateAttributeOptions"
                :key="attr.key"
                :value="attr.key"
              >
                {{ attr.label }}
              </option>
            </select>
            <p
              v-if="!scheduleDateAttributeOptions.length"
              class="m-0 mt-1 text-xs text-n-slate-10"
            >
              {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.ATTRIBUTE_KEY_NONE') }}
            </p>
          </label>
          <label
            v-if="automation.schedule.kind === 'days_since_attribute'"
            class="text-sm text-n-slate-11"
          >
            {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.RELATIVE_TO') }}
            <select v-model="scheduleRelativeTo" class="mt-1 w-full m-0">
              <option value="after">
                {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.RELATIVE_TO_AFTER') }}
              </option>
              <option value="on">
                {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.RELATIVE_TO_ON') }}
              </option>
              <option value="before">
                {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.RELATIVE_TO_BEFORE') }}
              </option>
            </select>
          </label>
          <label v-if="showScheduleDays" class="text-sm text-n-slate-11">
            {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.DAYS') }}
            <input
              v-model.number="automation.schedule.days"
              type="number"
              min="1"
              class="mt-1 w-full"
            />
          </label>
          <p
            v-if="automation.schedule.kind === 'days_since_attribute'"
            class="m-0 text-xs text-n-slate-11"
          >
            {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.RELATIVE_HINT') }}
          </p>
          <label
            v-if="
              automation.schedule.kind === 'hours_since_last_outgoing' ||
              automation.schedule.kind === 'hours_since_last_incoming'
            "
            class="text-sm text-n-slate-11"
          >
            {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.HOURS') }}
            <input
              v-model.number="automation.schedule.hours"
              type="number"
              min="1"
              class="mt-1 w-full"
            />
          </label>
          <p v-if="errors.schedule" class="m-0 text-sm text-n-ruby-11">
            {{
              $t(
                `AUTOMATION.ADD.FORM.SCHEDULE.ERRORS.${errors.schedule}`,
                errors.schedule
              )
            }}
          </p>
        </div>
        <p class="text-xs text-n-slate-11 m-0">
          {{ $t('AUTOMATION.ADD.FORM.SCHEDULE.HELP') }}
        </p>
      </section>
      <AutomationRunTypeSelector
        v-if="allowsDelayedExecution && !isTimeTriggered"
        v-model="isDelayed"
      />
      <AutomationWaitCondition
        v-if="isDelayed && !isTimeTriggered"
        :key="waitSectionKey"
        v-model:event-name="automation.event_name"
        v-model:conditions="automation.conditions"
        v-model:delay="delayMinutes"
        v-model:unit="delayUnit"
        :status-options="statusOptions"
        :inbox-options="inboxOptions"
        :is-saved-wait="isSavedWait"
        :has-error="Boolean(errors.execution_delay)"
      />
      <AutomationInstantTrigger
        v-else
        ref="instantTriggerRef"
        v-model:event-name="automation.event_name"
        v-model:conditions="automation.conditions"
        :events="automationRuleEvents"
        :filter-types="filterTypes"
        :errors="errors"
        :show-reset-message="!isEditMode && hasAutomationMutated"
        :append-new-condition="appendNewCondition"
        :remove-filter="removeFilter"
        :on-event-change="onEventChange"
      />
      <AutomationActions
        v-model="automation.actions"
        :action-types="automationActionTypes"
        :get-action-dropdown-values="getActionDropdownValues"
        :files="automation.files"
        :show-file-name="isEditMode"
        :errors="errors"
        :append-new-action="appendNewAction"
        :remove-action="removeAction"
        :reset-action="resetAction"
      />
    </div>
    <template #footer>
      <div class="flex flex-row justify-end w-full gap-2">
        <NextButton
          faded
          slate
          type="button"
          :label="$t(cancelKey)"
          @click="close"
        />
        <NextButton
          solid
          blue
          type="button"
          :label="$t(submitKey)"
          @click="emitSaveAutomation"
        />
      </div>
    </template>
  </SidePanel>
</template>
