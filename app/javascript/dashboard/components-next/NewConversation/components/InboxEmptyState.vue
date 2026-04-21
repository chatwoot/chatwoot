<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <div
    class="flex items-center w-full px-4 py-3 dark:bg-s-subtle/15 bg-s-warning-soft"
  >
    <span class="text-sm dark:text-s-warning-text text-s-warning-text">
      {{ t('COMPOSE_NEW_CONVERSATION.FORM.NO_INBOX_ALERT') }}
    </span>
  </div>
</template>
