<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import { useStore } from 'vuex';

const store = useStore();

const handleConversationSidebarToggle = () => {
  store.dispatch('uiState/set', {
    isConversationSidebarOpen: true,
    isCopilotSidebarOpen: false,
  });
};

const handleCopilotSidebarToggle = () => {
  store.dispatch('uiState/set', {
    isCopilotSidebarOpen: true,
    isConversationSidebarOpen: false,
  });
};
</script>

<template>
  <div
    class="flex flex-col justify-center items-center absolute top-20 right-1 bg-n-alpha-2 border border-n-weak rounded-lg bg-n-background gap-2 py-0.5 px-0.5"
  >
    <Button
      ghost
      slate
      sm
      class="!text-sm"
      icon="i-ph-user-bold"
      @click="handleConversationSidebarToggle"
    />
    <Button
      ghost
      class="!text-sm !text-n-iris-11"
      sm
      icon="i-woot-captain"
      @click="handleCopilotSidebarToggle"
    />
  </div>
</template>
