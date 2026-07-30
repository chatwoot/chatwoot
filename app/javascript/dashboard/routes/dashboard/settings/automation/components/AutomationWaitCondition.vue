<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';
import DurationInput from 'dashboard/components-next/input/DurationInput.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
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

const isStatusTrigger = computed(
  () => selectedTrigger.value === 'conversation_status'
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

const applyTrigger = () => {
  const trigger = DELAYED_TRIGGERS.find(
    item => item.key === selectedTrigger.value
  );
  eventName.value = trigger.eventName;
  const nextConditions = [
    trigger.messageType
      ? buildCondition('message_type', trigger.messageType)
      : buildCondition('status', triggerStatus.value),
  ];
  // A private note is an outgoing message, so without this an internal note would read as a reply
  // and arm the customer-unresponsive wait. Incoming messages are never private.
  if (trigger.messageType === 'outgoing') {
    nextConditions.push(buildCondition('private_note', [false]));
  }
  if (triggerInboxes.value.length) {
    nextConditions.push(
      buildCondition(
        'inbox_id',
        triggerInboxes.value.map(inbox => inbox.id)
      )
    );
  }
  conditions.value = nextConditions;
};

hydrateFromRule();

// A rule that wasn't saved as a wait still carries the instant editor's conditions, which can't be
// shown here: a leftover private note filter would arm the wait on internal notes.
// Deferred to mount because writing the models during setup would mutate the rule mid-render.
onMounted(() => {
  if (!props.isSavedWait) applyTrigger();
});

watch([selectedTrigger, triggerStatus, triggerInboxes], applyTrigger);
</script>

<template>
  <div class="flex flex-col gap-2">
    <label class="mb-0">
      {{ $t('AUTOMATION.ADD.FORM.WAIT.LABEL') }}
    </label>
    <div class="grid gap-3 lg:grid-cols-[minmax(0,1fr)_17rem]">
      <div
        class="flex flex-col gap-3 p-4 outline outline-1 -outline-offset-1 rounded-xl"
        :class="
          hasError
            ? 'outline-n-ruby-5 bg-n-ruby-2/50'
            : 'outline-n-weak dark:outline-n-strong'
        "
      >
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
      <aside class="flex flex-col gap-3 p-4 rounded-xl bg-n-alpha-1">
        <Icon icon="i-lucide-info" class="text-n-slate-10" />
        <p class="mb-0 text-xs text-n-slate-11">{{ explanation }}</p>
        <p class="mb-0 text-xs text-n-slate-11">
          {{ $t('AUTOMATION.ADD.FORM.WAIT.FOOTNOTE') }}
        </p>
      </aside>
    </div>
    <span v-if="hasError" class="text-xs text-n-ruby-9">
      {{ $t('AUTOMATION.ADD.FORM.WAIT.ERROR') }}
    </span>
  </div>
</template>
