<script setup>
// TODO: Make this component a standard across the app and use it in other places
import { ref, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';

defineProps({
  multiple: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['inboxFilterSelection']);
const store = useStore();
const options = useMapGetter('inboxes/getInboxes');

const selectedOption = ref(null);

onMounted(() => {
  store.dispatch('inboxes/get');
});

const handleInput = () => {
  emit('inboxFilterSelection', selectedOption.value);
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      :placeholder="$t('INBOX_REPORTS.FILTER_DROPDOWN_LABEL')"
      label="name"
      track-by="id"
      :multiple="multiple"
      :options="options"
      :option-height="24"
      :show-labels="false"
      @input="handleInput"
    />
  </div>
</template>
