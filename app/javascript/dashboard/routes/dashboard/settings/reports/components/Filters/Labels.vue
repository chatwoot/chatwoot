<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const props = defineProps({
  selectedLabel: { type: [Array, Object], default: null },
});
const emit = defineEmits(['labelsFilterSelection']);
const store = useStore();

store.dispatch('labels/get');

const options = computed(() => store.getters['labels/getLabels']);
const selectedItems = ref(
  Array.isArray(props.selectedLabel) ? [...props.selectedLabel] : []
);

const tags = computed(() => selectedItems.value.map(l => l.title));
const menuItems = computed(() =>
  options.value
    .filter(o => !selectedItems.value.find(s => s.id === o.id))
    .map(o => ({ action: 'select', value: String(o.id), label: o.title }))
);

const handleAdd = ({ value }) => {
  const item = options.value.find(o => String(o.id) === value);
  if (item) {
    selectedItems.value = [...selectedItems.value, item];
    emit('labelsFilterSelection', selectedItems.value);
  }
};
const handleRemove = index => {
  selectedItems.value = selectedItems.value.filter((_, i) => i !== index);
  emit('labelsFilterSelection', selectedItems.value);
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
      :placeholder="$t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL')"
      @add="handleAdd"
      @remove="handleRemove"
    />
  </div>
</template>
