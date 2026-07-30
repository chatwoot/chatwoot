<script setup>
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['update']);

const { t } = useI18n();
</script>

<template>
  <Button
    v-tooltip="t('BULK_ACTION.READ_STATUS.MARK_AS_READ')"
    icon="i-lucide-mail-open"
    slate
    xs
    ghost
    @click="emit('update', 'read')"
  />
  <Button
    v-tooltip="t('BULK_ACTION.READ_STATUS.MARK_AS_UNREAD')"
    icon="i-lucide-mail"
    slate
    xs
    ghost
    @click="emit('update', 'unread')"
  />
</template>
