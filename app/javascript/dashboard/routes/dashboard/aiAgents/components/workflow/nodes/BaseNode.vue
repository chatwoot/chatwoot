<script setup>
import { computed } from 'vue';
import { Handle, Position } from '@vue-flow/core';
import { NODE_TYPES_META, NODE_CATEGORIES, HANDLE_COLORS } from '../nodeTypes';

const props = defineProps({
  id: { type: String, required: true },
  type: { type: String, required: true },
  data: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
});

const meta = computed(() => NODE_TYPES_META[props.type] || {});
const category = computed(() => NODE_CATEGORIES[meta.value.category] || {});
const inputs = computed(() => meta.value.inputs || []);
const outputs = computed(() => meta.value.outputs || []);
</script>

<template>
  <div
    :data-node-id="id"
    class="min-w-[200px] max-w-[260px] rounded-xl border-2 bg-white shadow-sm transition-shadow dark:bg-n-solid-3"
    :class="[
      selected
        ? 'shadow-lg ring-2 ring-n-brand ring-offset-2'
        : 'hover:shadow-md',
      category.borderColor || 'border-n-weak',
    ]"
  >
    <!-- Header -->
    <div
      class="flex items-center gap-2 rounded-t-[10px] px-3 py-2"
      :class="category.color || 'bg-n-slate-6'"
    >
      <span :class="meta.icon" class="text-sm text-white" />
      <span class="truncate text-xs font-semibold text-white">
        {{ data.label || meta.defaultLabel }}
      </span>
    </div>

    <!-- Body — slot for node-specific content -->
    <div class="px-3 py-2">
      <slot name="body">
        <p class="text-xs text-n-slate-10">
          {{ meta.description }}
        </p>
      </slot>
    </div>

    <!-- Input Handles (left) -->
    <Handle
      v-for="(handle, idx) in inputs"
      :id="handle.id"
      :key="`in-${handle.id}`"
      type="target"
      :position="Position.Left"
      :style="{ top: `${30 + idx * 28}px` }"
      class="!size-3 !rounded-full !border-2 !border-white"
      :class="HANDLE_COLORS[handle.type]"
    />

    <!-- Output Handles (right) -->
    <Handle
      v-for="(handle, idx) in outputs"
      :id="handle.id"
      :key="`out-${handle.id}`"
      type="source"
      :position="Position.Right"
      :style="{ top: `${30 + idx * 28}px` }"
      class="!size-3 !rounded-full !border-2 !border-white"
      :class="HANDLE_COLORS[handle.type]"
    />

    <!-- Handle labels -->
    <div class="pointer-events-none absolute inset-0">
      <div
        v-for="(handle, idx) in inputs.filter(h => h.label)"
        :key="`label-in-${handle.id}`"
        class="absolute left-4 text-[10px] text-n-slate-8"
        :style="{ top: `${25 + idx * 28}px` }"
      >
        {{ handle.label }}
      </div>
      <div
        v-for="(handle, idx) in outputs.filter(h => h.label)"
        :key="`label-out-${handle.id}`"
        class="absolute right-4 text-right text-[10px] text-n-slate-8"
        :style="{ top: `${25 + idx * 28}px` }"
      >
        {{ handle.label }}
      </div>
    </div>
  </div>
</template>
