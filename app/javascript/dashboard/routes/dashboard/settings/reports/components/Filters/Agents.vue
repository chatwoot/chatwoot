<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const props = defineProps({
  selectedAgents: { type: Array, default: () => [] },
});
const emit = defineEmits(['agentsFilterSelection']);
const store = useStore();

store.dispatch('agents/get');

const options = computed(() => store.getters['agents/getAgents']);
const selectedItems = ref([...props.selectedAgents]);

const tags = computed(() => selectedItems.value.map(a => a.name));
const menuItems = computed(() =>
  options.value
    .filter(o => !selectedItems.value.find(s => s.id === o.id))
    .map(o => ({ action: 'select', value: String(o.id), label: o.name }))
);

const handleAdd = ({ value }) => {
  const item = options.value.find(o => String(o.id) === value);
  if (item) {
    selectedItems.value = [...selectedItems.value, item];
    emit('agentsFilterSelection', selectedItems.value);
  }
};
const handleRemove = index => {
  selectedItems.value = selectedItems.value.filter((_, i) => i !== index);
  emit('agentsFilterSelection', selectedItems.value);
};
</script>

<template>
  <div
    class="rounded-xl outline outline-1 -outline-offset-1 outline-n-weak hover:outline-n-strong px-2 py-2"
  >
    <TagInput
      :model-value="tags"
      :menu-items="menuItems"
      show-dropdown
      :allow-create="false"
      :auto-open-dropdown="false"
      :placeholder="$t('CSAT_REPORTS.FILTERS.AGENTS.PLACEHOLDER')"
      @add="handleAdd"
      @remove="handleRemove"
    />
  </div>
</template>
