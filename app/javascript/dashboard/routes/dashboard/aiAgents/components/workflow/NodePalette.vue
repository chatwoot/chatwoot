<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { NODE_PALETTE_ITEMS } from './nodeTypes';

const { t } = useI18n();
const searchQuery = ref('');
const expandedCategories = ref(NODE_PALETTE_ITEMS.map(c => c.key));

function toggleCategory(key) {
  const idx = expandedCategories.value.indexOf(key);
  if (idx >= 0) {
    expandedCategories.value.splice(idx, 1);
  } else {
    expandedCategories.value.push(key);
  }
}

function filteredNodes(nodes) {
  if (!searchQuery.value) return nodes;
  const q = searchQuery.value.toLowerCase();
  return nodes.filter(
    n =>
      n.label.toLowerCase().includes(q) ||
      n.description.toLowerCase().includes(q)
  );
}

function onDragStart(event, nodeType) {
  event.dataTransfer.setData('application/workflow-node', nodeType);
  event.dataTransfer.effectAllowed = 'move';
}
</script>

<template>
  <div class="flex h-full w-60 flex-col border-r border-n-weak bg-n-background">
    <div class="border-b border-n-weak p-3">
      <h3 class="mb-2 text-sm font-semibold text-n-slate-12">
        {{ t('AI_AGENTS.WORKFLOW.PALETTE.TITLE') }}
      </h3>
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="t('AI_AGENTS.WORKFLOW.PALETTE.SEARCH')"
        class="w-full rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-1.5 text-sm text-n-slate-12 placeholder:text-n-slate-8 focus:border-n-brand focus:outline-none"
      />
    </div>

    <div class="flex-1 overflow-y-auto p-2">
      <div
        v-for="category in NODE_PALETTE_ITEMS"
        :key="category.key"
        class="mb-2"
      >
        <button
          class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-xs font-semibold uppercase tracking-wider text-n-slate-10 hover:bg-n-alpha-2"
          @click="toggleCategory(category.key)"
        >
          <span :class="category.icon" class="text-sm" />
          {{ category.label }}
          <span
            class="i-lucide-chevron-down ml-auto text-xs transition-transform"
            :class="{
              'rotate-180': !expandedCategories.includes(category.key),
            }"
          />
        </button>

        <div
          v-if="expandedCategories.includes(category.key)"
          class="mt-1 space-y-1"
        >
          <div
            v-for="node in filteredNodes(category.nodes)"
            :key="node.type"
            class="flex cursor-grab items-center gap-2 rounded-lg border border-transparent px-3 py-2 text-sm text-n-slate-12 hover:border-n-weak hover:bg-n-alpha-2 active:cursor-grabbing"
            draggable="true"
            @dragstart="onDragStart($event, node.type)"
          >
            <span
              :class="[node.icon, category.color]"
              class="flex size-6 shrink-0 items-center justify-center rounded text-xs text-white"
            />
            <div class="min-w-0">
              <div class="truncate text-sm font-medium">{{ node.label }}</div>
              <div class="truncate text-xs text-n-slate-10">
                {{ node.description }}
              </div>
            </div>
          </div>
          <div
            v-if="filteredNodes(category.nodes).length === 0"
            class="px-3 py-2 text-xs text-n-slate-8"
          >
            {{ t('AI_AGENTS.WORKFLOW.PALETTE.NO_RESULTS') }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
