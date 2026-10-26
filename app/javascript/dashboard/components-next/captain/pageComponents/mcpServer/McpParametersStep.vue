<script setup>
import { useI18n } from 'vue-i18n';

import Switch from 'dashboard/components-next/switch/Switch.vue';
import McpParamRow from './McpParamRow.vue';
import {
  PARAM_SOURCES,
  schemaParams,
  sourceOf,
  usesVerifiedEmail,
  requiresVerification,
} from './mcpTools';

defineProps({
  tools: { type: Array, required: true },
  selections: { type: Object, required: true },
  toolSchema: { type: Function, required: true },
});

const emit = defineEmits([
  'updateSource',
  'updateFixedValue',
  'setVerification',
]);

const { t } = useI18n();
</script>

<template>
  <div class="flex flex-col gap-5">
    <header class="flex flex-col gap-1">
      <h3 class="m-0 text-base font-medium text-n-slate-12">
        {{ t('CAPTAIN.MCP_SERVERS.DIALOG.PARAMS_TITLE') }}
      </h3>
      <p class="m-0 text-sm text-n-slate-11">
        {{ t('CAPTAIN.MCP_SERVERS.DIALOG.PARAMS_DESCRIPTION') }}
      </p>
    </header>

    <p
      v-if="!tools.length"
      class="px-4 py-10 m-0 text-sm text-center rounded-xl bg-n-alpha-1 text-n-slate-11"
    >
      {{ t('CAPTAIN.MCP_SERVERS.DIALOG.PARAMS_NONE_SELECTED') }}
    </p>

    <section
      v-for="tool in tools"
      :key="tool.name"
      class="overflow-hidden rounded-xl outline outline-1 -outline-offset-1 outline-n-weak"
    >
      <header
        class="flex items-center justify-between gap-3 px-4 py-3 bg-n-alpha-1"
      >
        <span
          class="font-mono text-[0.8125rem] font-medium truncate text-n-slate-12"
        >
          {{ tool.name }}
        </span>
        <span
          class="inline-flex items-center gap-1 text-xs shrink-0"
          :class="
            requiresVerification(selections[tool.name])
              ? 'text-n-teal-11'
              : 'text-n-slate-11'
          "
        >
          <i
            class="size-3.5"
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
      </header>

      <div class="divide-y divide-n-weak">
        <p
          v-if="!schemaParams(toolSchema(tool)).length"
          class="px-4 py-3.5 m-0 text-sm text-n-slate-11"
        >
          {{ t('CAPTAIN.MCP_SERVERS.DIALOG.NO_PARAMS') }}
        </p>
        <McpParamRow
          v-for="param in schemaParams(toolSchema(tool))"
          :key="param.name"
          :param="param"
          :source="sourceOf(selections[tool.name].paramSources, param.name)"
          :fixed-value="
            selections[tool.name].paramSources[param.name]?.value || ''
          "
          :verified-email-taken="
            usesVerifiedEmail(selections[tool.name].paramSources) &&
            sourceOf(selections[tool.name].paramSources, param.name) !==
              PARAM_SOURCES.VERIFIED_EMAIL
          "
          @update:source="emit('updateSource', tool, param, $event)"
          @update:fixed-value="emit('updateFixedValue', tool, param, $event)"
        />
      </div>

      <label
        class="flex items-center justify-between gap-4 px-4 py-3 border-t cursor-pointer border-n-weak"
      >
        <span class="flex flex-col gap-0.5">
          <span class="text-sm text-n-slate-12">
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REQUIRE_VERIFICATION') }}
          </span>
          <span
            v-if="usesVerifiedEmail(selections[tool.name].paramSources)"
            class="text-xs text-n-slate-11"
          >
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REQUIRE_VERIFICATION_LOCKED') }}
          </span>
        </span>
        <Switch
          :model-value="requiresVerification(selections[tool.name])"
          :disabled="usesVerifiedEmail(selections[tool.name].paramSources)"
          @update:model-value="emit('setVerification', tool, $event)"
        />
      </label>
    </section>
  </div>
</template>
