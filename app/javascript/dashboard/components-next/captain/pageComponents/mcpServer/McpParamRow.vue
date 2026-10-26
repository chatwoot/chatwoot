<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import { PARAM_SOURCES, isEmailParam, isIdParam } from './mcpTools';

const props = defineProps({
  param: { type: Object, required: true },
  // Another parameter of the tool already takes the verified email
  verifiedEmailTaken: { type: Boolean, default: false },
});

const source = defineModel('source', {
  type: String,
  default: PARAM_SOURCES.MODEL,
});
const fixedValue = defineModel('fixedValue', { type: String, default: '' });

const { t } = useI18n();

const canTakeVerifiedEmail = computed(
  () => props.param.type === 'string' && !props.verifiedEmailTaken
);

const options = computed(() => [
  {
    value: PARAM_SOURCES.MODEL,
    label: t('CAPTAIN.MCP_SERVERS.DIALOG.SOURCES.MODEL'),
  },
  {
    value: PARAM_SOURCES.VERIFIED_EMAIL,
    label: t('CAPTAIN.MCP_SERVERS.DIALOG.SOURCES.VERIFIED_EMAIL'),
    disabled:
      !canTakeVerifiedEmail.value &&
      source.value !== PARAM_SOURCES.VERIFIED_EMAIL,
  },
  {
    value: PARAM_SOURCES.FIXED,
    label: t('CAPTAIN.MCP_SERVERS.DIALOG.SOURCES.FIXED'),
  },
]);

const HINT_STYLES = {
  ok: { icon: 'i-lucide-shield-check', class: 'text-n-teal-11' },
  warn: { icon: 'i-lucide-triangle-alert', class: 'text-n-amber-11' },
  muted: { icon: 'i-lucide-info', class: 'text-n-slate-10' },
};

const hint = computed(() => {
  if (source.value === PARAM_SOURCES.VERIFIED_EMAIL)
    return { tone: 'ok', key: 'VERIFIED_EMAIL' };
  if (source.value === PARAM_SOURCES.FIXED)
    return { tone: 'muted', key: 'FIXED' };
  if (isEmailParam(props.param.name)) return { tone: 'warn', key: 'EMAIL' };
  if (isIdParam(props.param.name)) return { tone: 'warn', key: 'ID' };
  return { tone: 'muted', key: 'MODEL' };
});

const showUseVerified = computed(
  () =>
    source.value === PARAM_SOURCES.MODEL &&
    isEmailParam(props.param.name) &&
    canTakeVerifiedEmail.value
);
</script>

<template>
  <div class="flex flex-col gap-2.5 px-4 py-3.5">
    <div class="grid items-start grid-cols-[minmax(0,1fr)_auto] gap-x-6">
      <div class="flex flex-col min-w-0 gap-1">
        <div class="flex items-center gap-2">
          <span class="font-mono text-[0.8125rem] font-medium text-n-slate-12">
            {{ param.name }}
          </span>
          <span
            class="px-1.5 py-px font-mono text-[0.6875rem] rounded-md bg-n-alpha-2 text-n-slate-11"
          >
            {{ param.type }}
          </span>
          <span v-if="param.required" class="text-[0.6875rem] text-n-slate-10">
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REQUIRED') }}
          </span>
        </div>
        <span
          v-if="param.description"
          class="text-xs text-n-slate-11 line-clamp-2"
        >
          {{ param.description }}
        </span>
      </div>

      <div
        role="radiogroup"
        :aria-label="param.name"
        class="inline-flex p-0.5 rounded-lg bg-n-alpha-2 shrink-0"
      >
        <button
          v-for="option in options"
          :key="option.value"
          type="button"
          role="radio"
          :aria-checked="source === option.value"
          :disabled="option.disabled"
          class="h-7 px-2.5 text-xs font-medium rounded-md transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          :class="
            source === option.value
              ? 'bg-n-solid-1 text-n-slate-12 shadow-sm'
              : 'text-n-slate-11 hover:text-n-slate-12'
          "
          @click="source = option.value"
        >
          {{ option.label }}
        </button>
      </div>
    </div>

    <input
      v-if="source === PARAM_SOURCES.FIXED"
      v-model="fixedValue"
      type="text"
      :placeholder="t('CAPTAIN.MCP_SERVERS.DIALOG.FIXED_PLACEHOLDER')"
      class="!h-9 !px-3 !m-0 text-sm !rounded-lg !bg-n-alpha-1 !border-0 !shadow-none outline outline-1 -outline-offset-1 outline-n-weak focus:outline-n-brand text-n-slate-12 placeholder:text-n-slate-10"
    />

    <p
      class="flex items-start gap-1.5 m-0 text-xs"
      :class="HINT_STYLES[hint.tone].class"
    >
      <i class="mt-px size-3.5 shrink-0" :class="HINT_STYLES[hint.tone].icon" />
      <span>
        {{ t(`CAPTAIN.MCP_SERVERS.DIALOG.HINTS.${hint.key}`) }}
        <button
          v-if="showUseVerified"
          type="button"
          class="p-0 font-medium text-n-blue-11 hover:underline"
          @click="source = PARAM_SOURCES.VERIFIED_EMAIL"
        >
          {{ t('CAPTAIN.MCP_SERVERS.DIALOG.USE_VERIFIED_EMAIL') }}
        </button>
      </span>
    </p>
  </div>
</template>
