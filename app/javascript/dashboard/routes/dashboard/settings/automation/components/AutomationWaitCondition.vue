<script setup>
import { computed, onMounted, ref, useTemplateRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';
import DurationInput from 'dashboard/components-next/input/DurationInput.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';
import {
  DELAYED_TRIGGERS,
  DEFAULT_TRIGGER,
  DEFAULT_TRIGGER_STATUS,
  MIN_DELAY_MINUTES,
  MAX_DELAY_MINUTES,
} from '../constants';

const props = defineProps({
  statusOptions: {
    type: Array,
    required: true,
  },
  inboxOptions: {
    type: Array,
    required: true,
  },
  filterTypes: {
    type: Array,
    required: true,
  },
  removeFilter: {
    type: Function,
    required: true,
  },
  hasError: {
    type: Boolean,
    default: false,
  },
  isSavedWait: {
    type: Boolean,
    default: false,
  },
});

const eventName = defineModel('eventName', { type: String, required: true });
const conditions = defineModel('conditions', { type: Array, required: true });
const delay = defineModel('delay', { type: Number, default: null });
const unit = defineModel('unit', { type: String, required: true });

const { t } = useI18n();

const selectedTrigger = ref(DEFAULT_TRIGGER);
const triggerStatus = ref(DEFAULT_TRIGGER_STATUS);
// No inbox selected means the rule applies to every inbox.
const triggerInboxes = ref([]);
const conditionsRef = useTemplateRef('conditionsRef');

const isStatusTrigger = computed(
  () => selectedTrigger.value === 'conversation_status'
);

const managedAttributeKeys = computed(() => {
  const keys = ['inbox_id'];
  if (isStatusTrigger.value) return new Set([...keys, 'status']);
  return new Set([...keys, 'message_type', 'private_note']);
});

const additionalFilterTypes = computed(() => {
  // Conversation-level waits only support status and inbox, and both are already managed by the
  // wait controls. Message waits can safely combine their event fields with the remaining filters.
  if (isStatusTrigger.value) return [];

  return props.filterTypes.filter(
    filter => !managedAttributeKeys.value.has(filter.attributeKey)
  );
});

const isAdditionalCondition = condition =>
  !managedAttributeKeys.value.has(condition.attribute_key);

const additionalConditionIndexes = computed(() =>
  conditions.value.flatMap((condition, index) =>
    isAdditionalCondition(condition) ? [index] : []
  )
);

const triggerOptions = computed(() =>
  DELAYED_TRIGGERS.map(trigger => ({
    value: trigger.key,
    label: t(`AUTOMATION.ADD.FORM.WAIT.OPTIONS.${trigger.key.toUpperCase()}`),
  }))
);

const MINUTES_PER_UNIT = {
  [DURATION_UNITS.MINUTES]: 1,
  [DURATION_UNITS.HOURS]: 60,
  [DURATION_UNITS.DAYS]: 24 * 60,
};

// The input only shows whole units, so the wait has to be at least one of them: without this,
// switching 4 hours to days shows 0 days while the rule keeps the 10 minute minimum.
const minDelay = computed(() =>
  Math.max(MIN_DELAY_MINUTES, MINUTES_PER_UNIT[unit.value])
);

// "4 hours" in the unit the inputs above are using, so the explanation reads the same.
const durationLabel = computed(() => {
  const count = Math.floor((delay.value || 0) / MINUTES_PER_UNIT[unit.value]);
  return t(
    `AUTOMATION.ADD.FORM.WAIT.DURATION.${unit.value.toUpperCase()}`,
    { count },
    count
  );
});

const explanation = computed(() =>
  t(
    `AUTOMATION.ADD.FORM.WAIT.EXPLANATION.${selectedTrigger.value.toUpperCase()}`,
    { duration: durationLabel.value }
  )
);

// A single value is a raw string in create mode and an option object ({ id }) after edit-mode
// formatting; return its plain value either way.
const rawConditionValue = condition => {
  const raw = Array.isArray(condition?.values)
    ? condition.values[0]
    : condition?.values;
  return raw && typeof raw === 'object' ? raw.id : raw;
};

const conditionFor = key =>
  conditions.value.find(condition => condition.attribute_key === key);

// Read the rule into the controls, so an existing wait opens on its own trigger, status and
// inboxes instead of the defaults.
const hydrateFromRule = () => {
  const inboxIds = (conditionFor('inbox_id')?.values || []).map(value =>
    value && typeof value === 'object' ? value.id : value
  );
  triggerInboxes.value = props.inboxOptions.filter(inbox =>
    inboxIds.includes(inbox.id)
  );

  const messageType = rawConditionValue(conditionFor('message_type'));
  if (eventName.value === 'message_created') {
    if (messageType === 'incoming')
      selectedTrigger.value = 'agent_unresponsive';
    else if (messageType === 'outgoing')
      selectedTrigger.value = 'customer_unresponsive';
    return;
  }

  if (eventName.value === 'conversation_updated') {
    selectedTrigger.value = 'conversation_status';
    triggerStatus.value =
      rawConditionValue(conditionFor('status')) || DEFAULT_TRIGGER_STATUS;
  }
};

const buildCondition = (attributeKey, values) => ({
  attribute_key: attributeKey,
  filter_operator: 'equal_to',
  values,
  query_operator: 'and',
  custom_attribute_type: '',
});

const connectorBeforeCondition = conditionIndex => {
  const connectorSource =
    conditions.value[conditionIndex === 0 ? 0 : conditionIndex - 1];

  return connectorSource?.query_operator?.toLowerCase() === 'or' ? 'or' : 'and';
};

const connectorLabel = conditionIndex =>
  connectorBeforeCondition(conditionIndex) === 'or'
    ? t('FILTER.QUERY_DROPDOWN_LABELS.OR')
    : t('FILTER.QUERY_DROPDOWN_LABELS.AND');

const replaceManagedCondition = (nextConditions, replacement) => {
  const conditionIndex = nextConditions.findIndex(
    condition => condition.attribute_key === replacement.attribute_key
  );
  if (conditionIndex === -1) return false;

  nextConditions[conditionIndex] = {
    ...replacement,
    query_operator: nextConditions[conditionIndex].query_operator,
  };
  return true;
};

const removeManagedCondition = (nextConditions, attributeKey) => {
  const conditionIndex = nextConditions.findIndex(
    condition => condition.attribute_key === attributeKey
  );
  if (conditionIndex !== -1) nextConditions.splice(conditionIndex, 1);
};

const insertManagedConditionAfter = (
  nextConditions,
  anchorAttributeKey,
  newCondition
) => {
  const anchorIndex = nextConditions.findIndex(
    condition => condition.attribute_key === anchorAttributeKey
  );
  if (anchorIndex === -1) return;

  const connectorAfterAnchor = nextConditions[anchorIndex].query_operator;
  nextConditions[anchorIndex] = {
    ...nextConditions[anchorIndex],
    query_operator: 'and',
  };
  nextConditions.splice(anchorIndex + 1, 0, {
    ...newCondition,
    query_operator: connectorAfterAnchor,
  });
};

const patchMessageWaitConditions = trigger => {
  const nextConditions = conditions.value.map(condition => ({ ...condition }));
  replaceManagedCondition(
    nextConditions,
    buildCondition('message_type', trigger.messageType)
  );

  const privateNoteCondition = buildCondition('private_note', [false]);
  if (trigger.messageType === 'outgoing') {
    const privateNoteExists = replaceManagedCondition(
      nextConditions,
      privateNoteCondition
    );
    if (!privateNoteExists) {
      insertManagedConditionAfter(
        nextConditions,
        'message_type',
        privateNoteCondition
      );
    }
  } else {
    removeManagedCondition(nextConditions, 'private_note');
  }

  const inboxCondition = triggerInboxes.value.length
    ? buildCondition(
        'inbox_id',
        triggerInboxes.value.map(inbox => inbox.id)
      )
    : null;
  if (inboxCondition) {
    const inboxExists = replaceManagedCondition(nextConditions, inboxCondition);
    if (!inboxExists) {
      const inboxAnchor =
        trigger.messageType === 'outgoing' ? 'private_note' : 'message_type';
      insertManagedConditionAfter(nextConditions, inboxAnchor, inboxCondition);
    }
  } else {
    removeManagedCondition(nextConditions, 'inbox_id');
  }

  if (nextConditions.length) nextConditions.at(-1).query_operator = null;
  conditions.value = nextConditions;
};

const applyTrigger = ({ preserveAdditional = true } = {}) => {
  const trigger = DELAYED_TRIGGERS.find(
    item => item.key === selectedTrigger.value
  );
  const canPatchMessageWait =
    preserveAdditional &&
    eventName.value === 'message_created' &&
    trigger.eventName === 'message_created' &&
    conditionFor('message_type');

  eventName.value = trigger.eventName;
  if (canPatchMessageWait) {
    patchMessageWaitConditions(trigger);
    return;
  }

  const additionalConditions = preserveAdditional
    ? conditions.value.filter(isAdditionalCondition)
    : [];
  const waitConditions = [
    trigger.messageType
      ? buildCondition('message_type', trigger.messageType)
      : buildCondition('status', triggerStatus.value),
  ];
  // A private note is an outgoing message, so without this an internal note would read as a reply
  // and arm the customer-unresponsive wait. Incoming messages are never private.
  if (trigger.messageType === 'outgoing') {
    waitConditions.push(buildCondition('private_note', [false]));
  }
  if (triggerInboxes.value.length) {
    waitConditions.push(
      buildCondition(
        'inbox_id',
        triggerInboxes.value.map(inbox => inbox.id)
      )
    );
  }
  if (additionalConditions.length) {
    waitConditions.at(-1).query_operator = connectorBeforeCondition(
      conditions.value.indexOf(additionalConditions[0])
    );
  }
  conditions.value = [...waitConditions, ...additionalConditions];
};

const addCondition = () => {
  const selectableFilters = additionalFilterTypes.value.filter(
    filter => !filter.disabled
  );
  const defaultFilter =
    selectableFilters.find(filter => filter.attributeKey === 'status') ||
    selectableFilters[0];
  if (!defaultFilter) return;

  const lastConditionIndex = conditions.value.length - 1;
  conditions.value = [
    ...conditions.value.map((condition, index) =>
      index === lastConditionIndex
        ? { ...condition, query_operator: 'and' }
        : condition
    ),
    {
      attribute_key: defaultFilter.attributeKey,
      filter_operator: defaultFilter.filterOperators[0].value,
      values: '',
      query_operator: null,
      custom_attribute_type:
        defaultFilter.attributeModel === 'standard'
          ? ''
          : defaultFilter.attributeModel || '',
    },
  ];
};

const validate = () => {
  const validationResults =
    conditionsRef.value?.map(condition => condition.validate()) ?? [];
  return validationResults.every(Boolean);
};

const resetValidation = () => {
  conditionsRef.value?.forEach(condition => condition.resetValidation());
};

hydrateFromRule();

// A rule that wasn't saved as a wait still carries the instant editor's conditions, which can't be
// shown here: a leftover private note filter would arm the wait on internal notes.
// Deferred to mount because writing the models during setup would mutate the rule mid-render.
onMounted(() => {
  if (!props.isSavedWait) applyTrigger({ preserveAdditional: false });
});

watch(
  [selectedTrigger, triggerStatus, triggerInboxes],
  ([nextTrigger], [previousTrigger]) => {
    const triggerChanged = nextTrigger !== previousTrigger;
    const nextEvent = DELAYED_TRIGGERS.find(
      trigger => trigger.key === nextTrigger
    ).eventName;
    applyTrigger({
      preserveAdditional: !triggerChanged || nextEvent === eventName.value,
    });
  }
);

defineExpose({ validate, resetValidation });
</script>

<template>
  <div class="flex flex-col min-w-0 gap-2">
    <label class="mb-0">
      {{ $t('AUTOMATION.ADD.FORM.WAIT.LABEL') }}
    </label>
    <div
      class="flex flex-col min-w-0 gap-3 p-4 outline outline-1 -outline-offset-1 rounded-xl"
      :class="
        hasError
          ? 'outline-n-ruby-5 bg-n-ruby-2/50'
          : 'outline-n-weak dark:outline-n-strong'
      "
    >
      <div class="grid gap-3 md:grid-cols-[minmax(0,1fr)_20rem]">
        <div class="flex flex-col min-w-0 gap-3">
          <div class="flex items-center gap-3 min-h-8">
            <span class="text-sm w-20 shrink-0 text-n-slate-11">
              {{ $t('AUTOMATION.ADD.FORM.WAIT.WHEN_LABEL') }}
            </span>
            <FilterSelect v-model="selectedTrigger" :options="triggerOptions" />
          </div>
          <div v-if="isStatusTrigger" class="flex items-center gap-3 min-h-8">
            <span class="text-sm w-20 shrink-0 text-n-slate-11">
              {{ $t('AUTOMATION.ADD.FORM.WAIT.STATUS_LABEL') }}
            </span>
            <FilterSelect v-model="triggerStatus" :options="statusOptions" />
          </div>
          <div class="flex items-center gap-3 min-h-8">
            <span class="text-sm w-20 shrink-0 text-n-slate-11">
              {{ $t('AUTOMATION.ADD.FORM.WAIT.FOR_LABEL') }}
            </span>
            <div class="flex items-center w-64 gap-2">
              <DurationInput
                v-model="delay"
                v-model:unit="unit"
                :min="minDelay"
                :max="MAX_DELAY_MINUTES"
              />
            </div>
          </div>
          <div class="flex items-center gap-3 min-h-8">
            <span class="text-sm w-20 shrink-0 text-n-slate-11">
              {{ $t('AUTOMATION.ADD.FORM.WAIT.INBOX_LABEL') }}
            </span>
            <MultiSelect v-model="triggerInboxes" :options="inboxOptions" />
          </div>
        </div>
        <aside
          class="flex gap-2 p-3 min-w-0 rounded-xl bg-n-alpha-1 md:self-start"
        >
          <Icon icon="i-lucide-info" class="mt-0.5 shrink-0 text-n-slate-10" />
          <div class="flex flex-col min-w-0 gap-2">
            <p class="mb-0 text-xs text-n-slate-11">{{ explanation }}</p>
            <p class="mb-0 text-xs text-n-slate-11">
              {{ $t('AUTOMATION.ADD.FORM.WAIT.FOOTNOTE') }}
            </p>
          </div>
        </aside>
      </div>
      <div
        v-if="additionalConditionIndexes.length"
        class="grid gap-3 pt-3 border-t border-n-weak"
      >
        <ul
          v-for="conditionIndex in additionalConditionIndexes"
          :key="conditionIndex"
          class="flex flex-col items-stretch gap-2 p-0 m-0 list-none min-w-0"
        >
          <li
            class="flex items-center self-start h-8 px-3 text-sm font-medium rounded-md bg-n-alpha-2 text-n-slate-11 shrink-0"
          >
            {{ connectorLabel(conditionIndex) }}
          </li>
          <ConditionRow
            ref="conditionsRef"
            v-model:attribute-key="conditions[conditionIndex].attribute_key"
            v-model:filter-operator="conditions[conditionIndex].filter_operator"
            v-model:values="conditions[conditionIndex].values"
            class="w-full min-w-0"
            :filter-types="additionalFilterTypes"
            @remove="removeFilter(conditionIndex)"
          />
        </ul>
      </div>
      <div v-if="additionalFilterTypes.length">
        <NextButton
          icon="i-lucide-plus"
          blue
          faded
          sm
          :label="$t('AUTOMATION.ADD.CONDITION_BUTTON_LABEL')"
          @click="addCondition"
        />
      </div>
    </div>
    <span v-if="hasError" class="text-xs text-n-ruby-9">
      {{ $t('AUTOMATION.ADD.FORM.WAIT.ERROR') }}
    </span>
  </div>
</template>
