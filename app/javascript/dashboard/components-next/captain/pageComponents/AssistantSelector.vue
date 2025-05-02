<script setup>
import { computed, ref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  assistantId: {
    type: [String, Number],
    required: true,
  },
});

const emit = defineEmits(['update']);
const { t } = useI18n();
const isFilterOpen = ref(false);

const assistants = useMapGetter('captainAssistants/getRecords');
const assistantOptions = computed(() => [
  {
    label: t(`CAPTAIN.RESPONSES.FILTER.ALL_ASSISTANTS`),
    value: 'all',
    action: 'filter',
  },
  ...assistants.value.map(assistant => ({
    value: assistant.id,
    label: assistant.name,
    action: 'filter',
  })),
]);

const selectedAssistantLabel = computed(() => {
  const assistant = assistantOptions.value.find(
    option => option.value === props.assistantId
  );
  return t('CAPTAIN.RESPONSES.FILTER.ASSISTANT', {
    selected: assistant ? assistant.label : '',
  });
});

const handleAssistantFilterChange = ({ value }) => {
  isFilterOpen.value = false;
  emit('update', value);
};
</script>

<template>
  <OnClickOutside @trigger="isFilterOpen = false">
    <Button
      :label="selectedAssistantLabel"
      icon="i-lucide-chevron-down"
      size="sm"
      color="slate"
      trailing-icon
      class="max-w-48"
      @click="isFilterOpen = !isFilterOpen"
    />

    <DropdownMenu
      v-if="isFilterOpen"
      :menu-items="assistantOptions"
      class="mt-2"
      @action="handleAssistantFilterChange"
    />
  </OnClickOutside>
</template>
