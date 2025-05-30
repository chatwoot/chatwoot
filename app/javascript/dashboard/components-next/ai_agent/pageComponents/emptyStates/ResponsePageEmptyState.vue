<script setup>
import { useI18n } from 'vue-i18n';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ResponseCard from 'dashboard/components-next/ai_agent/topic/ResponseCard.vue';
import FeatureSpotlight from 'dashboard/components-next/feature-spotlight/FeatureSpotlight.vue';
import { responsesList } from './aiAgentEmptyStateContent';

const emit = defineEmits(['click']);
const { t } = useI18n();

const handleClick = () => {
  emit('click');
};
</script>

<template>
  <FeatureSpotlight
    :title="t('AI_AGENT.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
    :note="t('AI_AGENT.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
    illustration-light="/assets/images/dashboard/ai_agent/response-spotlight-light.svg"
    illustration-dark="/assets/images/dashboard/ai_agent/response-spotlight-dark.svg"
    class="mb-8"
  />
  <EmptyStateLayout
    :title="t('AI_AGENT.RESPONSES.EMPTY_STATE.TITLE')"
    :subtitle="t('AI_AGENT.RESPONSES.EMPTY_STATE.DESCRIPTION')"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <ResponseCard
          v-for="response in responsesList"
          :id="response.id"
          :key="response.id"
          :question="response.question"
          :answer="response.answer"
          :status="response.status"
          :topic="response.topic"
          :updated-at="response.created_at"
          :created-at="response.created_at"
          compact
          example
        />
      </div>
    </template>
    <template #actions>
      <Button color="primary" @click="handleClick">
        {{ t('AI_AGENT.RESPONSES.ADD') }}
      </Button>
    </template>
  </EmptyStateLayout>
</template>
