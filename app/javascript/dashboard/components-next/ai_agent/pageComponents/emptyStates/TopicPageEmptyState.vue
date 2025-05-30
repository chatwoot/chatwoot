<script setup>
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import TopicCard from 'dashboard/components-next/ai_agent/topic/TopicCard.vue';
import { topicsList } from './aiAgentEmptyStateContent';

const emit = defineEmits(['click']);
const { t } = useI18n();

const handleClick = () => {
  emit('click');
};
</script>

<template>
  <div class="h-full flex flex-col">
    <div class="text-center my-8">
      <h2 class="text-3xl font-medium text-slate-900 dark:text-white mb-2">
        {{ t('AI_AGENT.TOPICS.EMPTY_STATE.TITLE') }}
      </h2>
      <p class="text-base text-slate-600 dark:text-slate-300 max-w-2xl mx-auto">
        {{ t('AI_AGENT.TOPICS.EMPTY_STATE.SUBTITLE') }}
      </p>
      <Button color="primary" class="mt-4" @click="handleClick">
        {{ t('AI_AGENT.TOPICS.ADD') }}
      </Button>
    </div>

    <div
      class="opacity-50 mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
    >
      <TopicCard
        v-for="topic in topicsList"
        :id="topic.id"
        :key="topic.id"
        :name="topic.name"
        :description="topic.description"
        :updated-at="topic.created_at"
        :created-at="topic.created_at"
        :inboxes-count="0"
        :document-count="0"
        example
      />
    </div>
  </div>
</template>
