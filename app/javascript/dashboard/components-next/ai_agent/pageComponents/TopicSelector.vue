<script setup>
import { computed, ref, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useMapGetters } from 'dashboard/composables/store';
import { OnClickOutside } from '@vueuse/components';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  topicId: {
    type: [Number, String],
    default: 'all',
  },
});

const emit = defineEmits(['update']);
const store = useStore();
const { locale } = useI18n();
const isFilterOpen = ref(false);

const { topics } = useMapGetters('aiAgentTopics', ['getTopics']);

// Helper function to get translated "All Topics" text based on locale
const getAllTopicsText = () => {
  return locale.value === 'fr' ? 'Tous les sujets' : 'All Topics';
};

const allTopics = computed(() => {
  if (!topics.value) return [];

  const formattedTopics = topics.value.map(topic => ({
    id: topic.id,
    name: topic.name,
  }));

  return [
    {
      id: 'all',
      name: getAllTopicsText(),
    },
    ...formattedTopics,
  ];
});

const topicOptions = computed(() =>
  allTopics.value.map(topic => ({
    label: topic.name,
    value: topic.id,
    action: 'filter',
  }))
);

const selectedTopic = computed(() => {
  return (
    allTopics.value.find(
      topic => String(topic.id) === String(props.topicId)
    ) || {
      id: 'all',
      name: getAllTopicsText(),
    }
  );
});

onMounted(() => {
  store.dispatch('aiAgentTopics/get');
});

const handleTopicFilterChange = ({ value }) => {
  isFilterOpen.value = false;
  emit('update', value);
};
</script>

<template>
  <OnClickOutside @trigger="isFilterOpen = false">
    <Button
      :label="selectedTopic.name"
      icon="i-lucide-chevron-down"
      size="sm"
      color="slate"
      trailing-icon
      class="max-w-48"
      @click="isFilterOpen = !isFilterOpen"
    />

    <DropdownMenu
      v-if="isFilterOpen"
      :menu-items="topicOptions"
      class="mt-2"
      @action="handleTopicFilterChange"
    />
  </OnClickOutside>
</template>
