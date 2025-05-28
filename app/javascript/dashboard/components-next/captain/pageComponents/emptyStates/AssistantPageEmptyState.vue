<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import AssistantCard from 'dashboard/components-next/captain/assistant/AssistantCard.vue';
import FeatureSpotlight from 'dashboard/components-next/feature-spotlight/FeatureSpotlight.vue';
import { assistantsList } from 'dashboard/components-next/captain/pageComponents/emptyStates/captainEmptyStateContent.js';

const emit = defineEmits(['click']);

const onClick = () => {
  emit('click');
};
</script>

<template>
  <FeatureSpotlight
    :title="$t('CAPTAIN.ASSISTANTS.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
    :note="$t('CAPTAIN.ASSISTANTS.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
    fallback-thumbnail="/assets/images/dashboard/captain/assistant-light.svg"
    fallback-thumbnail-dark="/assets/images/dashboard/captain/assistant-dark.svg"
    learn-more-url="https://chwt.app/captain-assistant"
    class="mb-8"
  />
  <EmptyStateLayout
    :title="$t('CAPTAIN.ASSISTANTS.EMPTY_STATE.TITLE')"
    :subtitle="$t('CAPTAIN.ASSISTANTS.EMPTY_STATE.SUBTITLE')"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div class="grid grid-cols-1 gap-4 p-px overflow-hidden">
        <AssistantCard
          v-for="(assistant, index) in assistantsList.slice(0, 5)"
          :id="assistant.id"
          :key="`assistant-${index}`"
          :name="assistant.name"
          :description="assistant.description"
          :updated-at="assistant.created_at"
        />
      </div>
    </template>
    <template #actions>
      <Button
        :label="$t('CAPTAIN.ASSISTANTS.ADD_NEW')"
        icon="i-lucide-plus"
        @click="onClick"
      />
    </template>
  </EmptyStateLayout>
</template>
