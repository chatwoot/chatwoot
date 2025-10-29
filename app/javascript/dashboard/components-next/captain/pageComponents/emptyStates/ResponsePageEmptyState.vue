<script setup>
import { useAccount } from 'dashboard/composables/useAccount';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ResponseCard from 'dashboard/components-next/captain/assistant/ResponseCard.vue';
import FeatureSpotlight from 'dashboard/components-next/feature-spotlight/FeatureSpotlight.vue';
import { responsesList } from 'dashboard/components-next/captain/pageComponents/emptyStates/captainEmptyStateContent.js';

defineProps({
  showFeatureSpotlight: {
    type: Boolean,
    default: true,
  },
  showCreateButton: {
    type: Boolean,
    default: true,
  },
  showBackdropCard: {
    type: Boolean,
    default: true,
  },
  showSubTitle: {
    type: Boolean,
    default: true,
  },
  hasActiveFilters: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['click', 'clearFilters']);
const { isOnChatwootCloud } = useAccount();

const onClick = () => {
  emit('click');
};

const onClearFilters = () => {
  emit('clearFilters');
};
</script>

<template>
  <FeatureSpotlight
    v-if="showFeatureSpotlight"
    :title="$t('CAPTAIN.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
    :note="$t('CAPTAIN.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
    fallback-thumbnail="/assets/images/dashboard/captain/faqs-light.svg"
    fallback-thumbnail-dark="/assets/images/dashboard/captain/faqs-dark.svg"
    learn-more-url="https://chwt.app/captain-faq"
    :hide-actions="!isOnChatwootCloud"
    class="mb-8"
  />
  <EmptyStateLayout
    :title="
      hasActiveFilters
        ? $t('CAPTAIN.RESPONSES.EMPTY_STATE.NO_PENDING_TITLE')
        : $t('CAPTAIN.RESPONSES.EMPTY_STATE.TITLE')
    "
    :subtitle="showSubTitle ? $t('CAPTAIN.RESPONSES.EMPTY_STATE.SUBTITLE') : ''"
    :action-perms="['administrator']"
    :show-backdrop="showBackdropCard"
  >
    <template v-if="showBackdropCard" #empty-state-item>
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
      <div class="flex flex-col items-center gap-3">
        <Button
          v-if="showCreateButton"
          :label="$t('CAPTAIN.RESPONSES.ADD_NEW')"
          icon="i-lucide-plus"
          @click="onClick"
        />
        <Button
          v-else-if="hasActiveFilters"
          :label="$t('CAPTAIN.RESPONSES.EMPTY_STATE.CLEAR_SEARCH')"
          variant="link"
          size="sm"
          @click="onClearFilters"
        />
      </div>
    </template>
  </EmptyStateLayout>
</template>
