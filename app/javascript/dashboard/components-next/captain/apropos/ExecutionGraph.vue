<script setup>
import { computed, nextTick, ref, shallowRef, useId } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ActivityEventDetail from './ActivityEventDetail.vue';
import { buildExecutionGraph, GRAPH_LAYOUT } from './executionGraph';

const props = defineProps({
  nodes: { type: Array, required: true },
  expanded: { type: Boolean, default: false },
});
const expandedDialog = ref(null);
const selectedIndex = ref(null);
const nodeTrigger = shallowRef(null);
const closeButton = ref(null);
const detailsId = useId();
const selectedNode = computed(() =>
  props.nodes.find(node => node.index === selectedIndex.value)
);
const selectNode = async (index, trigger) => {
  selectedIndex.value = index;
  nodeTrigger.value = trigger;
  await nextTick();
  closeButton.value?.focus();
};
const closeDetails = () => {
  selectedIndex.value = null;
  nodeTrigger.value?.focus({ preventScroll: true });
};
const { t } = useI18n();
const MIN_ZOOM = 0.3;
const MAX_ZOOM = 1.5;
const ZOOM_STEP = 0.15;
const zoom = defineModel('zoom', { type: Number, default: 0.75 });
const graph = computed(() =>
  buildExecutionGraph(props.nodes, t('CAPTAIN_ASK.TRACE.GRAPH_ROOT'))
);
const STATUS_CLASSES = {
  error: 'border-n-ruby-7 text-n-ruby-11',
  success: 'border-n-teal-7 text-n-teal-11',
  step: 'border-n-weak text-n-slate-11',
};
const EDGE_CLASSES = {
  error: 'text-n-ruby-7',
  success: 'text-n-teal-7',
  step: 'text-n-slate-6',
};
</script>

<template>
  <div class="space-y-3">
    <p class="m-0 text-xs text-n-slate-10">
      {{ t('CAPTAIN_ASK.TRACE.GRAPH_HELP') }}
    </p>
    <div class="flex items-center justify-end gap-2">
      <button
        v-if="!expanded"
        type="button"
        class="me-auto flex items-center gap-2 rounded px-2 py-1 text-xs text-n-slate-11 hover:bg-n-alpha-2 focus-visible:ring-2 focus-visible:ring-n-brand"
        @click="expandedDialog.open()"
      >
        <Icon icon="i-lucide-expand" class="size-4" />
        {{ t('CAPTAIN_ASK.TRACE.EXPAND_GRAPH') }}
      </button>
      <button
        type="button"
        class="p-1 rounded hover:bg-n-alpha-2 focus-visible:ring-2 focus-visible:ring-n-brand disabled:opacity-40"
        :disabled="zoom <= MIN_ZOOM"
        :aria-label="t('CAPTAIN_ASK.TRACE.ZOOM_OUT')"
        @click="zoom = Math.max(MIN_ZOOM, zoom - ZOOM_STEP)"
      >
        <Icon icon="i-lucide-minus" class="size-4 text-n-slate-11" />
      </button>
      <span class="text-xs tabular-nums text-n-slate-10">
        {{
          t('CAPTAIN_ASK.TRACE.ZOOM_LEVEL', { percent: Math.round(zoom * 100) })
        }}
      </span>
      <button
        type="button"
        class="p-1 rounded hover:bg-n-alpha-2 focus-visible:ring-2 focus-visible:ring-n-brand disabled:opacity-40"
        :disabled="zoom >= MAX_ZOOM"
        :aria-label="t('CAPTAIN_ASK.TRACE.ZOOM_IN')"
        @click="zoom = Math.min(MAX_ZOOM, zoom + ZOOM_STEP)"
      >
        <Icon icon="i-lucide-plus" class="size-4 text-n-slate-11" />
      </button>
    </div>
    <div class="relative">
      <div
        class="overflow-auto rounded-lg border border-n-weak bg-n-solid-2"
        :class="expanded ? 'h-[calc(100dvh-16rem)] min-h-64' : 'h-96'"
        tabindex="0"
        role="region"
        :aria-label="t('CAPTAIN_ASK.TRACE.GRAPH')"
      >
        <svg
          :width="graph.width * zoom"
          :height="graph.height * zoom"
          :viewBox="`0 0 ${graph.width} ${graph.height}`"
          class="block max-w-none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <g
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
            aria-hidden="true"
          >
            <path
              v-for="edge in graph.edges"
              :key="edge.id"
              :d="edge.path"
              :class="EDGE_CLASSES[edge.status]"
            />
          </g>
          <foreignObject
            v-for="node in graph.nodes"
            :key="node.index"
            :x="node.x"
            :y="node.y"
            :width="GRAPH_LAYOUT.width"
            :height="GRAPH_LAYOUT.height"
          >
            <div
              v-if="node.index === -1"
              class="h-full flex items-center justify-center rounded-lg border border-n-brand bg-n-solid-1 text-sm font-medium text-n-slate-12"
            >
              {{ node.label }}
            </div>
            <button
              v-else
              type="button"
              class="flex h-full w-full items-center gap-2 rounded-lg border bg-n-solid-1 px-3 py-2 text-start hover:bg-n-solid-3 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-n-brand"
              :class="[
                STATUS_CLASSES[node.status],
                {
                  'ring-2 ring-inset ring-n-brand':
                    selectedIndex === node.index,
                },
              ]"
              :title="node.detail"
              :aria-expanded="selectedIndex === node.index"
              :aria-controls="
                selectedIndex === node.index ? detailsId : undefined
              "
              @click="selectNode(node.index, $event.currentTarget)"
            >
              <Icon :icon="node.icon" class="size-4 shrink-0" />
              <span class="min-w-0 flex-1">
                <span class="block truncate text-sm font-medium">{{
                  node.label
                }}</span>
                <span class="block truncate text-xs text-n-slate-10">{{
                  node.detail
                }}</span>
                <span v-if="node.depth" class="block text-xs text-n-slate-10">{{
                  t('CAPTAIN_ASK.TRACE.WORKER_DEPTH', { depth: node.depth })
                }}</span>
              </span>
              <span class="text-xs tabular-nums text-n-slate-9">{{
                node.index + 1
              }}</span>
            </button>
          </foreignObject>
        </svg>
      </div>
      <section
        v-if="selectedNode"
        :id="detailsId"
        class="absolute end-3 top-3 bottom-3 z-10 flex w-[28rem] max-w-[calc(100%-1.5rem)] flex-col overflow-hidden rounded-xl border border-n-weak bg-n-solid-1 shadow-lg"
        :aria-label="selectedNode.label"
        @keydown.esc.stop.prevent="closeDetails"
      >
        <header
          class="flex shrink-0 items-center gap-3 border-b border-n-weak px-4 py-3"
        >
          <Icon
            :icon="selectedNode.icon"
            class="size-4 shrink-0 text-n-slate-11"
          />
          <h3 class="m-0 min-w-0 flex-1 text-heading-3 text-n-slate-12">
            {{ selectedNode.label }}
          </h3>
          <span class="text-xs tabular-nums text-n-slate-10">{{
            selectedNode.index + 1
          }}</span>
          <button
            ref="closeButton"
            type="button"
            class="rounded p-1 text-n-slate-11 hover:bg-n-alpha-2 focus-visible:ring-2 focus-visible:ring-n-brand"
            :aria-label="t('CAPTAIN_ASK.TRACE.CLOSE_DETAILS')"
            @click="closeDetails"
          >
            <Icon icon="i-lucide-x" class="size-4" />
          </button>
        </header>
        <div class="min-h-0 overflow-auto p-4">
          <ActivityEventDetail
            :key="selectedNode.index"
            :event="selectedNode.event"
          />
        </div>
      </section>
    </div>
    <Dialog
      v-if="!expanded"
      ref="expandedDialog"
      :title="t('CAPTAIN_ASK.TRACE.GRAPH')"
      :show-confirm-button="false"
      :cancel-button-label="t('CAPTAIN_ASK.TRACE.CLOSE_GRAPH')"
      overflow-y-auto
      width="screen"
    >
      <ExecutionGraph v-model:zoom="zoom" :nodes="nodes" expanded />
    </Dialog>
  </div>
</template>
