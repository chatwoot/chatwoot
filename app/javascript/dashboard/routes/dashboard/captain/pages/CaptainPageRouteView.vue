<script setup>
import { watch } from 'vue';
import { useRoute } from 'vue-router';
import { useUISettings } from 'dashboard/composables/useUISettings';

const route = useRoute();
const { uiSettings, updateUISettings } = useUISettings();

watch(
  () => route.params.assistantId,
  newAssistantId => {
    if (
      newAssistantId &&
      newAssistantId !== String(uiSettings.value.last_active_assistant_id)
    ) {
      updateUISettings({
        last_active_assistant_id: Number(newAssistantId),
      });
    }
  }
);
</script>

<template>
  <div class="flex w-full h-full min-h-0">
    <section class="flex flex-1 h-full px-0 overflow-hidden bg-n-background">
      <router-view />
    </section>
  </div>
</template>
