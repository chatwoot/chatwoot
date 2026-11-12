<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import Select from 'dashboard/components-next/select/Select.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SettingsCheckboxOption from './SettingsCheckboxOption.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

// Choices within the bounds the server accepts (10–60 s interval, 0–600 s wrap-up)
const RING_STEP_PRESETS = [10, 15, 20, 30, 45, 60];
const WRAP_UP_PRESETS = [0, 30, 60, 120, 300, 600];
const SIMULTANEOUS = 'simultaneous';
const SEQUENTIAL = 'sequential';

const store = useStore();
const { t } = useI18n();

const saved = () => ({
  ringStrategy: props.inbox.ring_strategy,
  ringStepSeconds: props.inbox.ring_step_seconds,
  assigneeRingsFirst: props.inbox.assignee_rings_first !== false,
  callCooldownSeconds: props.inbox.call_cooldown_seconds,
});
const form = ref(saved());
const isSaving = ref(false);

watch(
  () => [
    props.inbox.id,
    props.inbox.ring_strategy,
    props.inbox.ring_step_seconds,
    props.inbox.assignee_rings_first,
    props.inbox.call_cooldown_seconds,
  ],
  () => {
    form.value = saved();
  }
);

const durationLabel = seconds => {
  if (seconds === 0) return t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.OFF');
  if (seconds % 60 === 0) {
    return t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.MINUTES', seconds / 60);
  }
  return t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.SECONDS', { seconds });
};

// A value saved before the presets existed stays selectable
const durationOptions = (presets, savedValue) =>
  [...new Set([...presets, savedValue])]
    .sort((a, b) => a - b)
    .map(seconds => ({ value: seconds, label: durationLabel(seconds) }));

const ringStepOptions = computed(() =>
  durationOptions(RING_STEP_PRESETS, props.inbox.ring_step_seconds)
);
const wrapUpOptions = computed(() =>
  durationOptions(WRAP_UP_PRESETS, props.inbox.call_cooldown_seconds)
);

const strategies = computed(() => [
  {
    id: SIMULTANEOUS,
    label: t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STRATEGY.SIMULTANEOUS'),
    description: t(
      'INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STRATEGY.SIMULTANEOUS_HELP'
    ),
  },
  {
    id: SEQUENTIAL,
    label: t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STRATEGY.SEQUENTIAL'),
    description: t(
      'INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STRATEGY.SEQUENTIAL_HELP'
    ),
  },
]);

const canSave = computed(
  () => JSON.stringify(form.value) !== JSON.stringify(saved())
);

const save = async () => {
  if (isSaving.value) return;
  isSaving.value = true;
  try {
    await InboxesAPI.setCallRouting(props.inbox.id, form.value);
    await store.dispatch('inboxes/get', props.inbox.id);
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error?.response?.data?.message || t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
    );
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div
    class="flex flex-col gap-4 px-4 py-3 outline outline-1 -outline-offset-1 outline-n-weak rounded-xl"
    :class="{ 'pointer-events-none opacity-60': isSaving }"
  >
    <div class="flex flex-col gap-1">
      <span class="text-heading-3 text-n-slate-12">{{
        t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.TITLE')
      }}</span>
      <span class="text-body-main text-n-slate-11">
        {{ t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.DESCRIPTION') }}
      </span>
    </div>
    <div class="flex flex-col gap-2">
      <RadioCard
        v-for="strategy in strategies"
        :id="`call-routing-${strategy.id}-${inbox.id}`"
        :key="strategy.id"
        :name="`call-routing-strategy-${inbox.id}`"
        :label="strategy.label"
        :description="strategy.description"
        :is-active="form.ringStrategy === strategy.id"
        @select="form.ringStrategy = strategy.id"
      />
    </div>
    <label
      v-if="form.ringStrategy === SEQUENTIAL"
      class="flex items-center gap-2 mb-0 text-body-main text-n-slate-12"
    >
      {{ t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STEP') }}
      <Select
        v-model="form.ringStepSeconds"
        :options="ringStepOptions"
        :aria-label="t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STEP')"
        :disabled="isSaving"
      />
    </label>
    <SettingsCheckboxOption
      v-model="form.assigneeRingsFirst"
      :header="t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.ASSIGNEE_FIRST')"
    />
    <div class="flex flex-col gap-1">
      <label
        class="flex items-center gap-2 mb-0 text-body-main text-n-slate-12"
      >
        {{ t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.WRAP_UP.LABEL') }}
        <Select
          v-model="form.callCooldownSeconds"
          :options="wrapUpOptions"
          :aria-label="
            t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.WRAP_UP.LABEL')
          "
          :disabled="isSaving"
        />
      </label>
      <span class="text-body-main text-n-slate-11">
        {{ t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.WRAP_UP.HELP') }}
      </span>
    </div>
    <p class="text-body-main text-n-slate-11">
      {{ t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.BUSY_AGENTS') }}
    </p>
    <div class="flex justify-end">
      <NextButton
        :label="t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.SAVE')"
        :is-loading="isSaving"
        :disabled="!canSave"
        sm
        @click="save"
      />
    </div>
  </div>
</template>
