<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ResponseCard from 'dashboard/components-next/captain/assistant/ResponseCard.vue';
import FeatureSpotlight from 'dashboard/components-next/feature-spotlight/FeatureSpotlight.vue';
import { responsesList } from 'dashboard/components-next/captain/pageComponents/emptyStates/captainEmptyStateContent.js';

const emit = defineEmits(['click']);

const onClick = () => {
  emit('click');
};
</script>

<template>
  <FeatureSpotlight
    :title="$t('CAPTAIN.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
    :note="$t('CAPTAIN.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
    fallback-thumbnail="/assets/images/dashboard/captain/faqs-light.svg"
    fallback-thumbnail-dark="/assets/images/dashboard/captain/faqs-dark.svg"
    learn-more-url="https://chwt.app/captain-faq"
    class="mb-8"
  />
  <EmptyStateLayout
    :title="$t('CAPTAIN.RESPONSES.EMPTY_STATE.TITLE')"
    :subtitle="$t('CAPTAIN.RESPONSES.EMPTY_STATE.SUBTITLE')"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div class="grid grid-cols-1 gap-4 p-px overflow-hidden">
        <ResponseCard
          v-for="(response, index) in responsesList.slice(0, 5)"
          :id="response.id"
          :key="`response-${index}`"
          :question="response.question"
          :answer="response.answer"
          :status="response.status"
          :assistant="response.assistant"
          :created-at="response.created_at"
          :updated-at="response.created_at"
        />
      </div>
    </template>
    <template #actions>
      <Button
        :label="$t('CAPTAIN.RESPONSES.ADD_NEW')"
        icon="i-lucide-plus"
        @click="onClick"
      />
    </template>
  </EmptyStateLayout>
</template>
