<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import {
  PARAM_SOURCES,
  fingerprintLabel,
  schemaParams,
  sourceOf,
  requiresVerification,
} from './mcpTools';

const props = defineProps({
  serverName: { type: String, required: true },
  serverUrl: { type: String, required: true },
  authType: { type: String, required: true },
  tools: { type: Array, required: true },
  selections: { type: Object, required: true },
  toolSchema: { type: Function, required: true },
  toolDigest: { type: Function, required: true },
});

const { t } = useI18n();

const host = computed(() => {
  try {
    return new URL(props.serverUrl).host;
  } catch {
    return props.serverUrl;
  }
});

const SOURCE_STYLES = {
  [PARAM_SOURCES.MODEL]: 'bg-n-alpha-2 text-n-slate-11',
  [PARAM_SOURCES.VERIFIED_EMAIL]: 'bg-n-teal-3 text-n-teal-11',
  [PARAM_SOURCES.FIXED]: 'bg-n-blue-3 text-n-blue-11',
};
const SOURCE_KEYS = {
  [PARAM_SOURCES.MODEL]: 'MODEL',
  [PARAM_SOURCES.VERIFIED_EMAIL]: 'VERIFIED_EMAIL',
  [PARAM_SOURCES.FIXED]: 'FIXED',
};

const paramChips = tool =>
  schemaParams(props.toolSchema(tool)).map(param => {
    const source = sourceOf(
      props.selections[tool.name].paramSources,
      param.name
    );
    return {
      name: param.name,
      source,
      label:
        source === PARAM_SOURCES.FIXED
          ? props.selections[tool.name].paramSources[param.name].value
          : t(
              `CAPTAIN.MCP_SERVERS.DIALOG.SOURCE_SUMMARY.${SOURCE_KEYS[source]}`
            ),
    };
  });
</script>

<template>
  <div class="flex flex-col gap-5">
    <header class="flex flex-col gap-1">
      <h3 class="m-0 text-base font-medium text-n-slate-12">
        {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW.TITLE') }}
      </h3>
      <p class="m-0 text-sm text-n-slate-11">
        {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW.DESCRIPTION') }}
      </p>
    </header>

    <div class="flex items-center gap-3 px-4 py-3.5 rounded-xl bg-n-alpha-1">
      <div class="flex flex-col flex-1 min-w-0">
        <span class="text-sm font-medium truncate text-n-slate-12">
          {{ serverName }}
        </span>
        <span class="text-xs truncate text-n-slate-11">{{ host }}</span>
      </div>
      <span class="text-xs text-n-slate-11 shrink-0">
        {{ t(`CAPTAIN.MCP_SERVERS.AUTH_TYPES.${authType.toUpperCase()}`) }}
      </span>
    </div>

    <p
      v-if="!tools.length"
      class="px-4 py-10 m-0 text-sm text-center rounded-xl bg-n-alpha-1 text-n-slate-11"
    >
      {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW.NO_TOOLS') }}
    </p>

    <ul
      v-else
      class="m-0 overflow-hidden list-none divide-y rounded-xl outline outline-1 -outline-offset-1 outline-n-weak divide-n-weak"
    >
      <li
        v-for="tool in tools"
        :key="tool.name"
        class="flex flex-col gap-2.5 px-4 py-3.5"
      >
        <div class="flex items-center justify-between gap-3">
          <span
            class="font-mono text-[0.8125rem] font-medium truncate text-n-slate-12"
          >
            {{ tool.name }}
          </span>
          <span
            class="font-mono text-[0.6875rem] text-n-slate-10 shrink-0"
            :title="t('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW_COLUMNS.FINGERPRINT')"
          >
            {{ fingerprintLabel(toolDigest(tool)) }}
          </span>
        </div>
        <div class="flex flex-wrap items-center gap-1.5">
          <span
            class="inline-flex items-center gap-1 h-6 px-2 text-xs rounded-md"
            :class="
              requiresVerification(selections[tool.name])
                ? 'bg-n-teal-3 text-n-teal-11'
                : 'bg-n-alpha-2 text-n-slate-11'
            "
          >
            <i
              class="size-3"
              :class="
                requiresVerification(selections[tool.name])
                  ? 'i-lucide-shield-check'
                  : 'i-lucide-users'
              "
            />
            {{
              requiresVerification(selections[tool.name])
                ? t('CAPTAIN.MCP_SERVERS.WHO.VERIFIED')
                : t('CAPTAIN.MCP_SERVERS.WHO.ANYONE')
            }}
          </span>
          <span
            v-for="chip in paramChips(tool)"
            :key="chip.name"
            class="inline-flex items-center h-6 gap-1 px-2 text-xs rounded-md max-w-full"
            :class="SOURCE_STYLES[chip.source]"
          >
            <span class="font-mono">{{ chip.name }}</span>
            <span class="opacity-60">·</span>
            <span class="truncate">{{ chip.label }}</span>
          </span>
        </div>
      </li>
    </ul>
  </div>
</template>
