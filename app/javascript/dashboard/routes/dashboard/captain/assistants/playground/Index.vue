<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import AssistantPlayground from 'dashboard/components-next/captain/assistant/AssistantPlayground.vue';

const route = useRoute();
const assistantId = computed(() => Number(route.params.assistantId));
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.PLAYGROUND.HEADER')"
    show-assistant-switcher
    :show-pagination-footer="false"
    class="h-full"
  >
    <template #body>
      <div class="flex flex-col h-full">
        <AssistantPlayground :assistant-id="assistantId" />
      </div>
    </template>
  </PageLayout>
</template>
