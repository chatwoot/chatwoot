<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Select from 'dashboard/components-next/select/Select.vue';
import Input from 'dashboard/components-next/input/Input.vue';
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

const sourceOptions = computed(() => [
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

const hint = computed(() => {
  if (source.value === PARAM_SOURCES.VERIFIED_EMAIL)
    return { tone: 'ok', key: 'VERIFIED_EMAIL' };
  if (source.value === PARAM_SOURCES.FIXED)
    return { tone: 'muted', key: 'FIXED' };
  if (isEmailParam(props.param.name)) return { tone: 'warn', key: 'EMAIL' };
  if (isIdParam(props.param.name)) return { tone: 'warn', key: 'ID' };
  return { tone: 'muted', key: 'MODEL' };
});

const HINT_CLASSES = {
  ok: 'text-n-teal-11',
  warn: 'text-n-amber-11',
  muted: 'text-n-slate-11',
};

const showUseVerified = computed(
  () =>
    source.value === PARAM_SOURCES.MODEL &&
    isEmailParam(props.param.name) &&
    canTakeVerifiedEmail.value
);
</script>

<template>
  <div class="grid gap-x-3 gap-y-1.5 sm:grid-cols-2 items-start">
    <div class="flex flex-col min-w-0 gap-0.5">
      <code class="text-sm text-n-slate-12 truncate">{{ param.name }}</code>
      <span class="text-xs text-n-slate-11">
        {{ param.type
        }}{{
          param.required ? `, ${t('CAPTAIN.MCP_SERVERS.DIALOG.REQUIRED')}` : ''
        }}
        <template v-if="param.description"> · {{ param.description }}</template>
      </span>
    </div>
    <div class="flex flex-col gap-1.5 min-w-0">
      <Select
        v-model="source"
        :options="sourceOptions"
        :aria-label="param.name"
      />
      <Input
        v-if="source === PARAM_SOURCES.FIXED"
        v-model="fixedValue"
        :placeholder="t('CAPTAIN.MCP_SERVERS.DIALOG.FIXED_PLACEHOLDER')"
      />
    </div>
    <p class="text-xs mb-0 sm:col-span-2" :class="HINT_CLASSES[hint.tone]">
      {{ t(`CAPTAIN.MCP_SERVERS.DIALOG.HINTS.${hint.key}`) }}
      <button
        v-if="showUseVerified"
        type="button"
        class="p-0 underline text-n-blue-11"
        @click="source = PARAM_SOURCES.VERIFIED_EMAIL"
      >
        {{ t('CAPTAIN.MCP_SERVERS.DIALOG.USE_VERIFIED_EMAIL') }}
      </button>
    </p>
  </div>
</template>
