<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { usePolicy } from 'dashboard/composables/usePolicy';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import AssistantPlayground from 'dashboard/components-next/captain/assistant/AssistantPlayground.vue';

const route = useRoute();
const { isFeatureFlagEnabled } = usePolicy();
const assistantId = computed(() => Number(route.params.assistantId));
const isV2 = computed(() => isFeatureFlagEnabled(FEATURE_FLAGS.CAPTAIN_V2));
</script>

<template>
  <PageLayout
    show-assistant-switcher
    :show-pagination-footer="false"
    :show-know-more="false"
    :container-class="isV2 ? 'max-w-none' : undefined"
    class="h-full"
  >
    <template #body>
      <div class="flex flex-col h-full">
        <AssistantPlayground
          :assistant-id="assistantId"
          class="bg-n-surface-1"
        />
      </div>
    </template>
  </PageLayout>
</template>
