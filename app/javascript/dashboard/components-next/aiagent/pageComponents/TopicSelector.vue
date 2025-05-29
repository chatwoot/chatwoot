<script setup>
import { computed, ref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  topicId: {
    type: [String, Number],
    required: true,
  },
});

const emit = defineEmits(['update']);
const { t } = useI18n();
const isFilterOpen = ref(false);

const topics = useMapGetter('aiagentTopics/getRecords');
const topicOptions = computed(() => [
  {
    label: t(`AIAGENT.RESPONSES.FILTER.ALL_TOPICS`),
    value: 'all',
    action: 'filter',
  },
  ...topics.value.map(topic => ({
    value: topic.id,
    label: topic.name,
    action: 'filter',
  })),
]);

const selectedTopicLabel = computed(() => {
  const topic = topicOptions.value.find(
    option => option.value === props.topicId
  );
  return t('AIAGENT.RESPONSES.FILTER.TOPIC', {
    selected: topic ? topic.label : '',
  });
});

const handleTopicFilterChange = ({ value }) => {
  isFilterOpen.value = false;
  emit('update', value);
};
</script>

<template>
  <OnClickOutside @trigger="isFilterOpen = false">
    <Button
      :label="selectedTopicLabel"
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
