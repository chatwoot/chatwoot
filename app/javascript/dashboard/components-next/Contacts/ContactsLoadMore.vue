<script setup>
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['loadMore']);

const { t } = useI18n();
</script>

<template>
  <div class="flex justify-center py-4">
    <Button
      :label="t('CONTACTS_LAYOUT.LOAD_MORE')"
      :is-loading="isLoading"
      variant="faded"
      color="slate"
      size="sm"
      @click="emit('loadMore')"
    />
  </div>
</template>
