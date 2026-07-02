<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Select from 'dashboard/components-next/select/Select.vue';

// REVISÃO + CONECTAR (Tela 5). Summary card built from the generated agent's
// human-facing fields only (IP OCULTO: never instruction/scaffold). The FIRST
// MESSAGE is an editable EXAMPLE (auto-height TextArea) the user can tweak and
// save. "Testar antes" becomes available here; connecting picks an eligible
// inbox (1 agent per inbox) and activates.
const props = defineProps({
  agent: {
    type: Object,
    required: true,
  },
  eligibleInboxes: {
    type: Array,
    default: () => [],
  },
  approvedCount: {
    type: Number,
    default: 0,
  },
  confidencePct: {
    type: Number,
    default: 0,
  },
  isSavingGreeting: {
    type: Boolean,
    default: false,
  },
  isConnecting: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'saveGreeting',
  'test',
  'connect',
  'back',
  'activate',
]);

const { t } = useI18n();

// `human_card` is a plain string (1–2 sentence human summary), never an object
// and never the raw instruction/scaffold (IP OCULTO). Use it directly.
const summary = computed(() => props.agent?.human_card || '');

// V2.1 — internal agents (team copilot) are never customer-facing: no inbox to
// connect. The backend blocks the connect anyway; this hides the UI as a 2nd defense.
const isInternal = computed(() => props.agent?.actuation === 'internal');

// There is no `role` field on the agent. It carries `agent_type` (one of the
// canonical enum values), which maps to a localized label, mirroring the type
// picker's keys.
const TYPE_LABEL_KEY = {
  support: 'SUPPORT',
  sdr: 'SDR',
  reception: 'RECEPTIONIST',
  onboarding: 'POST_SALE',
  scheduler: 'SCHEDULER',
  reactivation: 'REACTIVATION',
  custom: 'SCRATCH',
};
const roleLabel = computed(() => {
  const key = TYPE_LABEL_KEY[props.agent?.agent_type];
  return key ? t(`AGENTS.TYPES.${key}.TITLE`) : '';
});

const starterQuestions = computed(() => props.agent?.starter_questions || []);

// Local editable copy of the greeting (the suggested first message).
const greeting = ref('');
watch(
  () => props.agent,
  agent => {
    greeting.value = agent?.greeting || '';
  },
  { immediate: true }
);

const selectedInbox = ref('');

const inboxOptions = computed(() =>
  props.eligibleInboxes.map(inbox => ({
    value: inbox.id,
    label: inbox.name,
  }))
);

const canConnect = computed(() => !!selectedInbox.value && !props.isConnecting);

const onSaveGreeting = () => emit('saveGreeting', greeting.value);

// Persist the edited greeting before connecting so an un-clicked "Salvar" edit
// isn't silently dropped on activation. The parent saves the greeting (no-op if
// unchanged on its side) and then connects the inbox.
const onConnect = () => {
  if (!canConnect.value) return;
  if (greeting.value !== (props.agent?.greeting || '')) {
    emit('saveGreeting', greeting.value);
  }
  emit('connect', selectedInbox.value);
};
</script>

<template>
  <div class="flex flex-col w-full gap-5">
    <!-- Summary card -->
    <div
      class="flex flex-col overflow-hidden border shadow-sm rounded-xl border-n-iris-4 bg-n-solid-2"
    >
      <div
        class="flex items-center gap-2 px-6 py-3 border-b bg-gradient-to-r from-n-iris-3 to-n-solid-2 border-n-iris-4"
      >
        <i class="i-lucide-sparkles text-n-iris-10 size-4 shrink-0" />
        <span
          class="text-xs font-medium tracking-wide uppercase text-n-iris-11"
        >
          {{ t('AGENTS.REVIEW.TITLE') }}
        </span>
      </div>

      <div class="flex flex-col gap-5 p-6">
        <div class="flex items-center gap-3">
          <Avatar
            :name="agent.name || t('AGENTS.BUILDER.BUILDER_NAME')"
            :src="agent.avatar_url"
            rounded-full
            :size="44"
            class="shrink-0"
          />
          <div class="flex flex-col gap-0.5 min-w-0">
            <h3 class="text-lg font-medium truncate text-n-slate-12">
              {{ agent.name }}
            </h3>
            <span v-if="roleLabel" class="text-xs text-n-slate-11">
              {{ roleLabel }}
            </span>
          </div>
        </div>

        <p v-if="summary" class="text-sm leading-relaxed text-n-slate-11">
          {{ summary }}
        </p>

        <!-- First message: editable EXAMPLE -->
        <div class="flex flex-col gap-2">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('AGENTS.REVIEW.FIRST_MESSAGE_LABEL') }}
          </span>
          <TextArea
            v-model="greeting"
            auto-height
            :resize="false"
            min-height="3rem"
            max-height="10rem"
            :placeholder="t('AGENTS.REVIEW.FIRST_MESSAGE_HINT')"
          />
          <div class="flex justify-end">
            <NextButton
              outline
              slate
              sm
              :label="t('AGENTS.REVIEW.SAVE_FIRST_MESSAGE')"
              :is-loading="isSavingGreeting"
              @click="onSaveGreeting"
            />
          </div>
        </div>

        <div v-if="starterQuestions.length" class="flex flex-col gap-2">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('AGENTS.REVIEW.STARTERS') }}
          </span>
          <div class="flex flex-wrap gap-2">
            <span
              v-for="(question, index) in starterQuestions"
              :key="index"
              class="px-3 py-1.5 text-xs rounded-full bg-n-alpha-2 text-n-slate-12 border border-n-weak"
            >
              {{ question }}
            </span>
          </div>
        </div>

        <p class="text-xs text-n-slate-11">
          {{
            t('AGENTS.REVIEW.APPROVED_SUMMARY', {
              count: approvedCount,
              pct: confidencePct,
            })
          }}
        </p>
      </div>
    </div>

    <!-- Connect -->
    <div
      class="flex flex-col gap-4 p-6 border rounded-xl border-n-weak bg-n-solid-1"
    >
      <h4 class="text-sm font-medium text-n-slate-12">
        {{
          isInternal
            ? t('AGENTS.REVIEW.INTERNAL_TITLE')
            : t('AGENTS.REVIEW.CONNECT_TITLE')
        }}
      </h4>

      <!-- Internal agent: team copilot, no inbox to connect. -->
      <div
        v-if="isInternal"
        class="flex items-start gap-2 px-3 py-2 text-xs rounded-lg bg-n-iris-3 text-n-iris-11"
      >
        <i class="i-lucide-headset size-4 mt-0.5 shrink-0" />
        <span>{{ t('AGENTS.REVIEW.INTERNAL_HINT') }}</span>
      </div>

      <template v-else>
        <div
          class="flex items-start gap-2 px-3 py-2 text-xs rounded-lg bg-n-iris-3 text-n-iris-11"
        >
          <i class="i-lucide-info size-4 mt-0.5 shrink-0" />
          <span>{{ t('AGENTS.CHANNELS.ONE_PER_INBOX') }}</span>
        </div>

        <div class="flex flex-col gap-2">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('AGENTS.REVIEW.SELECT_INBOX') }}
          </label>
          <Select
            v-model="selectedInbox"
            class="!w-full [&_select]:w-full"
            :options="inboxOptions"
            :placeholder="t('AGENTS.REVIEW.SELECT_INBOX')"
            :disabled="!inboxOptions.length"
          />
          <p v-if="!inboxOptions.length" class="text-xs text-n-slate-10">
            {{ t('AGENTS.CHANNELS.NO_ELIGIBLE') }}
          </p>
        </div>
      </template>

      <div
        class="flex flex-col gap-2 pt-2 border-t sm:flex-row sm:items-center sm:justify-between border-n-weak"
      >
        <NextButton
          outline
          slate
          icon="i-lucide-flask-conical"
          :label="t('AGENTS.REVIEW.TEST_FIRST')"
          @click="emit('test')"
        />
        <div class="flex gap-2">
          <NextButton
            outline
            slate
            :label="t('AGENTS.REVIEW.BACK')"
            @click="emit('back')"
          />
          <NextButton
            v-if="!isInternal"
            solid
            blue
            icon="i-lucide-plug"
            :label="t('AGENTS.REVIEW.CONNECT_ACTIVATE')"
            :is-loading="isConnecting"
            :disabled="!canConnect"
            @click="onConnect"
          />
          <!-- Interno (copiloto): não há canal para conectar — ativa direto. -->
          <NextButton
            v-else
            solid
            blue
            icon="i-lucide-headset"
            :label="t('AGENTS.REVIEW.ACTIVATE_INTERNAL')"
            :is-loading="isConnecting"
            @click="emit('activate')"
          />
        </div>
      </div>
    </div>
  </div>
</template>
