<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const props = defineProps({
  selectedTeam: { type: Array, default: () => [] },
});
const emit = defineEmits(['teamFilterSelection']);
const store = useStore();

store.dispatch('teams/get');

const options = computed(() => store.getters['teams/getTeams']);
const selectedItems = ref([...props.selectedTeam]);

const tags = computed(() => selectedItems.value.map(team => team.name));
const menuItems = computed(() =>
  options.value
    .filter(o => !selectedItems.value.find(s => s.id === o.id))
    .map(o => ({ action: 'select', value: String(o.id), label: o.name }))
);

const handleAdd = ({ value }) => {
  const item = options.value.find(o => String(o.id) === value);
  if (item) {
    selectedItems.value = [...selectedItems.value, item];
    emit('teamFilterSelection', selectedItems.value);
  }
};
const handleRemove = index => {
  selectedItems.value = selectedItems.value.filter((_, i) => i !== index);
  emit('teamFilterSelection', selectedItems.value);
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
      :placeholder="$t('TEAM_REPORTS.FILTER_DROPDOWN_LABEL')"
      @add="handleAdd"
      @remove="handleRemove"
    />
  </div>
</template>
