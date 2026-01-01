<script setup>
import { computed } from 'vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const props = defineProps({
  modelValue: {
    type: Set,
    default: () => new Set(),
  },
  allItems: {
    type: Array,
    default: () => [],
  },
  selectAllLabel: {
    type: String,
    default: '',
  },
  selectedCountLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue']);

const allSelected = computed(() => {
  if (!props.allItems.length) return false;
  return props.modelValue.size === props.allItems.length;
});

const someSelected = computed(() => {
  return props.modelValue.size > 0 && !allSelected.value;
});

const hasSelection = computed(() => props.modelValue.size > 0);

const toggleAll = () => {
  if (allSelected.value) {
    emit('update:modelValue', new Set());
  } else {
    emit('update:modelValue', new Set(props.allItems.map(item => item.id)));
  }
};
</script>

<template>
  <div
    class="flex items-center gap-3 px-3 py-2 bg-n-solid-2 border border-n-weak rounded-lg"
  >
    <div class="flex items-center gap-2">
      <Checkbox
        :model-value="allSelected"
        :indeterminate="someSelected"
        @update:model-value="toggleAll"
      />
      <span v-if="hasSelection" class="text-sm text-n-slate-11 font-medium">
        {{ selectedCountLabel }}
      </span>
      <button
        v-else
        type="button"
        class="text-sm text-n-slate-11 hover:text-n-slate-12"
        @click="toggleAll"
      >
        {{ selectAllLabel }}
      </button>
    </div>
    <slot name="secondary-actions" />
    <div class="flex-1" />
    <slot name="actions" />
  </div>
</template>
