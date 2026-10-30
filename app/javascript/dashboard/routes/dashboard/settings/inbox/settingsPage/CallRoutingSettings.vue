<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxesAPI from 'dashboard/api/inboxes';
import Select from 'dashboard/components-next/select/Select.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SettingsCheckboxOption from './SettingsCheckboxOption.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

// The bounds the server accepts
const RING_STEP_SECONDS = { min: 10, max: 60 };
const COOLDOWN_SECONDS = { min: 0, max: 600 };
const SEQUENTIAL = 'sequential';

const store = useStore();
const { t } = useI18n();

const saved = () => ({
  ringStrategy: props.inbox.ring_strategy,
  ringStepSeconds: props.inbox.ring_step_seconds,
  preferFreeAgents: !!props.inbox.prefer_free_agents,
  callCooldownSeconds: props.inbox.call_cooldown_seconds,
});
const form = ref(saved());
const isSaving = ref(false);

watch(
  () => [
    props.inbox.id,
    props.inbox.ring_strategy,
    props.inbox.ring_step_seconds,
    props.inbox.prefer_free_agents,
    props.inbox.call_cooldown_seconds,
  ],
  () => {
    form.value = saved();
  }
);

const strategyOptions = computed(() => [
  {
    value: 'simultaneous',
    label: t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STRATEGY.SIMULTANEOUS'),
  },
  {
    value: SEQUENTIAL,
    label: t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STRATEGY.SEQUENTIAL'),
  },
]);
const stepHelp = computed(() =>
  form.value.ringStrategy === SEQUENTIAL
    ? t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STEP.HELP_SEQUENTIAL')
    : t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STEP.HELP_SIMULTANEOUS')
);
// A cleared seconds field is not read as 0
const canSave = computed(
  () =>
    form.value.ringStepSeconds !== '' &&
    form.value.callCooldownSeconds !== '' &&
    JSON.stringify(form.value) !== JSON.stringify(saved())
);

const save = async () => {
  if (isSaving.value) return;
  isSaving.value = true;
  try {
    await InboxesAPI.setCallRouting(props.inbox.id, {
      ...form.value,
      ringStepSeconds: Number(form.value.ringStepSeconds),
      callCooldownSeconds: Number(form.value.callCooldownSeconds),
    });
    await store.dispatch('inboxes/get', props.inbox.id);
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error?.response?.data?.error || t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE')
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
    <div class="flex flex-col gap-1">
      <span class="text-body-main text-n-slate-12">
        {{ t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STRATEGY.LABEL') }}
      </span>
      <Select
        v-model="form.ringStrategy"
        :options="strategyOptions"
        :aria-label="t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STRATEGY.LABEL')"
        :disabled="isSaving"
      />
    </div>
    <div class="flex flex-col gap-1">
      <label
        :for="`call-routing-step-${inbox.id}`"
        class="flex items-center gap-2 mb-0 text-body-main text-n-slate-12"
      >
        {{ t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.STEP.LABEL') }}
        <span
          class="flex items-center gap-2 h-8 px-3 rounded-lg bg-n-alpha-black2 outline outline-1 -outline-offset-1 outline-n-weak focus-within:outline-n-brand"
        >
          <input
            :id="`call-routing-step-${inbox.id}`"
            v-model="form.ringStepSeconds"
            type="number"
            :min="RING_STEP_SECONDS.min"
            :max="RING_STEP_SECONDS.max"
            :disabled="isSaving"
            class="w-10 reset-base !mb-0 !p-0 !border-0 !bg-transparent text-sm text-n-slate-12"
          />
          <span class="text-sm text-n-slate-11">{{
            t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.UNIT')
          }}</span>
        </span>
      </label>
      <span class="text-body-main text-n-slate-11">
        {{ stepHelp }}
      </span>
    </div>
    <SettingsCheckboxOption
      v-model="form.preferFreeAgents"
      :header="t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.PREFER_FREE')"
    />
    <div class="flex flex-col gap-1">
      <label
        :for="`call-routing-cooldown-${inbox.id}`"
        class="flex items-center gap-2 mb-0 text-body-main text-n-slate-12"
      >
        {{ t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.COOLDOWN.LABEL') }}
        <span
          class="flex items-center gap-2 h-8 px-3 rounded-lg bg-n-alpha-black2 outline outline-1 -outline-offset-1 outline-n-weak focus-within:outline-n-brand"
        >
          <input
            :id="`call-routing-cooldown-${inbox.id}`"
            v-model="form.callCooldownSeconds"
            type="number"
            :min="COOLDOWN_SECONDS.min"
            :max="COOLDOWN_SECONDS.max"
            :disabled="isSaving"
            class="w-10 reset-base !mb-0 !p-0 !border-0 !bg-transparent text-sm text-n-slate-12"
          />
          <span class="text-sm text-n-slate-11">{{
            t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.UNIT')
          }}</span>
        </span>
      </label>
      <span class="text-body-main text-n-slate-11">
        {{ t('INBOX_MGMT.VOICE_CONFIGURATION.ROUTING.COOLDOWN.HELP') }}
      </span>
    </div>
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
