<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  tools: { type: Array, required: true },
  selectedNames: { type: Array, required: true },
  approvedTools: { type: Array, default: () => [] },
  missingTools: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
  loadFailed: { type: Boolean, default: false },
  isBusy: { type: Boolean, default: false },
});

const emit = defineEmits(['toggle', 'selectAll', 'approve']);

const { t } = useI18n();

// Searching helps once a server lists more tools than fit on screen
const SEARCH_THRESHOLD = 8;

const query = ref('');
const reviewing = ref(null);

const readTools = computed(() => props.tools.filter(tool => tool.read_only));
const visibleTools = computed(() => {
  const text = query.value.trim().toLowerCase();
  if (!text) return props.tools;
  return props.tools.filter(
    tool =>
      tool.name.toLowerCase().includes(text) ||
      (tool.description || '').toLowerCase().includes(text)
  );
});
const allReadSelected = computed(
  () =>
    readTools.value.length > 0 &&
    readTools.value.every(tool => props.selectedNames.includes(tool.name))
);

const isSelected = tool => props.selectedNames.includes(tool.name);
const approvedDescription = tool =>
  props.approvedTools.find(item => item.name === tool.name)?.description;
const schemaChanged = tool =>
  JSON.stringify(
    props.approvedTools.find(item => item.name === tool.name)?.input_schema
  ) !== JSON.stringify(tool.input_schema);

const toggle = tool => {
  if (!tool.read_only) return;
  emit('toggle', tool.name, !isSelected(tool));
};
</script>

<template>
  <div class="flex flex-col gap-5">
    <header class="flex flex-col gap-1">
      <h3 class="m-0 text-base font-medium text-n-slate-12">
        {{ t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS.TITLE') }}
      </h3>
      <p class="m-0 text-sm text-n-slate-11">
        {{ t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS.DESCRIPTION') }}
      </p>
    </header>

    <div v-if="isLoading" class="flex items-center justify-center py-16">
      <Spinner />
    </div>

    <p
      v-else-if="loadFailed"
      class="px-4 py-10 m-0 text-sm text-center rounded-xl bg-n-alpha-1 text-n-ruby-11"
    >
      {{ t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS_ERROR') }}
    </p>
    <p
      v-else-if="!tools.length"
      class="px-4 py-10 m-0 text-sm text-center rounded-xl bg-n-alpha-1 text-n-slate-11"
    >
      {{ t('CAPTAIN.MCP_SERVERS.DIALOG.NO_LIVE_TOOLS') }}
    </p>

    <template v-else>
      <div class="flex items-center justify-between gap-3">
        <span class="text-sm text-n-slate-11 tabular-nums">
          {{
            t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS.SELECTED', {
              selected: selectedNames.length,
              total: tools.length,
            })
          }}
        </span>
        <button
          v-if="readTools.length"
          type="button"
          class="p-0 text-sm font-medium text-n-blue-11 hover:underline"
          @click="emit('selectAll', !allReadSelected)"
        >
          {{
            allReadSelected
              ? t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS.CLEAR')
              : t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS.SELECT_ALL_READ')
          }}
        </button>
      </div>

      <label
        v-if="tools.length > SEARCH_THRESHOLD"
        class="flex items-center h-9 gap-2 px-3 rounded-lg bg-n-alpha-1 outline outline-1 -outline-offset-1 outline-n-weak focus-within:outline-n-brand"
      >
        <i class="i-lucide-search size-4 shrink-0 text-n-slate-10" />
        <input
          v-model="query"
          type="search"
          :placeholder="t('CAPTAIN.MCP_SERVERS.DIALOG.TOOLS.SEARCH')"
          class="flex-1 min-w-0 !p-0 !m-0 !h-auto text-sm !bg-transparent !border-0 !shadow-none !outline-none !ring-0 text-n-slate-12 placeholder:text-n-slate-10"
        />
      </label>

      <ul
        class="m-0 overflow-hidden list-none divide-y rounded-xl outline outline-1 -outline-offset-1 outline-n-weak divide-n-weak"
      >
        <li v-for="tool in visibleTools" :key="tool.name">
          <div
            class="flex items-start gap-3 px-4 py-3.5 transition-colors"
            :class="{
              'cursor-pointer hover:bg-n-alpha-1': tool.read_only,
              'bg-n-blue-2': isSelected(tool),
            }"
            @click="toggle(tool)"
          >
            <div class="pt-0.5" @click.stop>
              <Checkbox
                :model-value="isSelected(tool)"
                :disabled="!tool.read_only"
                @update:model-value="emit('toggle', tool.name, $event)"
              />
            </div>
            <div class="flex flex-col flex-1 min-w-0 gap-1">
              <div class="flex items-center gap-2 min-w-0">
                <span
                  class="font-mono text-[0.8125rem] font-medium truncate"
                  :class="
                    tool.read_only ? 'text-n-slate-12' : 'text-n-slate-10'
                  "
                >
                  {{ tool.name }}
                </span>
                <span
                  v-if="tool.changed"
                  class="px-1.5 py-px text-[0.6875rem] font-medium rounded-md bg-n-amber-3 text-n-amber-11 shrink-0"
                >
                  {{ t('CAPTAIN.MCP_SERVERS.DIALOG.CHANGED') }}
                </span>
                <span
                  v-if="!tool.read_only"
                  class="inline-flex items-center gap-1 px-1.5 py-px text-[0.6875rem] font-medium rounded-md bg-n-alpha-2 text-n-slate-11 shrink-0"
                >
                  <i class="i-lucide-lock size-3" />
                  {{ t('CAPTAIN.MCP_SERVERS.DIALOG.WRITE') }}
                </span>
              </div>
              <p
                class="m-0 text-sm line-clamp-2"
                :class="tool.read_only ? 'text-n-slate-11' : 'text-n-slate-10'"
              >
                {{ tool.description }}
              </p>
              <button
                v-if="tool.changed && reviewing !== tool.name"
                type="button"
                class="self-start p-0 text-xs font-medium text-n-blue-11 hover:underline"
                @click.stop="reviewing = tool.name"
              >
                {{ t('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW_CHANGE') }}
              </button>
            </div>
          </div>

          <div
            v-if="tool.changed && reviewing === tool.name"
            class="flex flex-col gap-3 px-4 pb-4 ps-11"
          >
            <div class="grid gap-3 sm:grid-cols-2">
              <div class="flex flex-col gap-1 p-3 rounded-lg bg-n-alpha-1">
                <span class="text-xs text-n-slate-10">
                  {{ t('CAPTAIN.MCP_SERVERS.DIALOG.APPROVED_VERSION') }}
                </span>
                <span class="text-sm text-n-slate-11">
                  {{ approvedDescription(tool) }}
                </span>
              </div>
              <div
                class="flex flex-col gap-1 p-3 rounded-lg bg-n-amber-2 outline outline-1 -outline-offset-1 outline-n-amber-5"
              >
                <span class="text-xs text-n-amber-11">
                  {{ t('CAPTAIN.MCP_SERVERS.DIALOG.LIVE_VERSION') }}
                </span>
                <span class="text-sm text-n-slate-12">
                  {{ tool.description }}
                </span>
              </div>
            </div>
            <p v-if="schemaChanged(tool)" class="m-0 text-xs text-n-slate-11">
              {{ t('CAPTAIN.MCP_SERVERS.DIALOG.PARAMETERS_CHANGED') }}
            </p>
            <p class="m-0 text-xs text-n-amber-11">
              {{ t('CAPTAIN.MCP_SERVERS.DIALOG.CHANGE_WARNING') }}
            </p>
            <div class="flex justify-end gap-2">
              <Button
                size="sm"
                faded
                slate
                :label="t('CAPTAIN.MCP_SERVERS.DIALOG.KEEP_OFF')"
                :disabled="isBusy"
                @click="reviewing = null"
              />
              <Button
                size="sm"
                :label="t('CAPTAIN.MCP_SERVERS.DIALOG.APPROVE_CHANGE')"
                :is-loading="isBusy"
                :disabled="isBusy || !tool.read_only"
                @click="emit('approve', tool)"
              />
            </div>
          </div>
        </li>
      </ul>

      <p
        v-if="missingTools.length"
        class="flex items-start gap-2 px-3 py-2.5 m-0 text-xs rounded-lg bg-n-amber-2 text-n-amber-11"
      >
        <i class="i-lucide-circle-alert mt-px size-3.5 shrink-0" />
        {{
          t('CAPTAIN.MCP_SERVERS.DIALOG.MISSING_TOOLS', {
            names: missingTools.join(', '),
          })
        }}
      </p>
    </template>
  </div>
</template>
