<script setup>
import { useI18n } from 'vue-i18n';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DocumentCard from 'dashboard/components-next/ai_agent/topic/DocumentCard.vue';
import FeatureSpotlight from 'dashboard/components-next/feature-spotlight/FeatureSpotlight.vue';
import { documentsList } from './aiAgentEmptyStateContent';

const emit = defineEmits(['click']);
const { t } = useI18n();

const handleClick = () => {
  emit('click');
};
</script>

<template>
  <FeatureSpotlight
    :title="t('AI_AGENT.DOCUMENTS.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
    :note="t('AI_AGENT.DOCUMENTS.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
    illustration-light="/assets/images/dashboard/ai_agent/document-spotlight-light.svg"
    illustration-dark="/assets/images/dashboard/ai_agent/document-spotlight-dark.svg"
    class="mb-8"
  />
  <EmptyStateLayout
    :title="t('AI_AGENT.DOCUMENTS.EMPTY_STATE.TITLE')"
    :subtitle="t('AI_AGENT.DOCUMENTS.EMPTY_STATE.DESCRIPTION')"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <DocumentCard
          v-for="document in documentsList"
          :id="document.id"
          :key="document.id"
          :name="document.name"
          :external-link="document.external_link"
          :topic="document.topic"
          :created-at="document.created_at"
          example
        />
      </div>
    </template>
    <template #actions>
      <Button color="primary" @click="handleClick">
        {{ t('AI_AGENT.DOCUMENTS.ADD') }}
      </Button>
    </template>
  </EmptyStateLayout>
</template>
