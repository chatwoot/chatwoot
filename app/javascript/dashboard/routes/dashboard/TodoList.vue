<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

const store = useStore();
const { t } = useI18n();

// Get current account ID from store
const accountId = computed(() => {
  const accountIdFromRoute = store.getters.getCurrentAccountId;
  return accountIdFromRoute;
});

// Build iframe URL
const iframeUrl = computed(() => {
  // Get URL from environment variable or use default
  // TODO: Replace with actual deployed URL
  const baseUrl =
    window.chatwootConfig?.todoAppUrl ||
    process.env.VUE_APP_TODO_URL ||
    'https://todolist-test.swgaming.dev/';
  const params = new URLSearchParams({
    accountId: accountId.value,
    embedded: 'true',
    fullscreen: 'true',
  });
  return `${baseUrl}?${params.toString()}`;
});
</script>

<template>
  <div class="todo-list-container">
    <iframe
      :src="iframeUrl"
      class="todo-iframe"
      :title="t('TODO.TITLE')"
      allow="clipboard-write"
    />
  </div>
</template>

<style scoped>
.todo-list-container {
  width: 100%;
  height: 100%;
  position: relative;
  overflow: hidden;
}

.todo-iframe {
  width: 100%;
  height: 100%;
  background: #ffffff;
  border: none;
}
</style>
