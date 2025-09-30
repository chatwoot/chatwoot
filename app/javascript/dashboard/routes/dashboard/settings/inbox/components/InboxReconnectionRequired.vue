<script setup>
import Banner from 'dashboard/components-next/banner/Banner.vue';

const props = defineProps({
  actionLabel: {
    type: String,
    default: null,
  },
  description: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['reauthorize']);
</script>

<template>
  <Banner
    color="ruby"
    :action-label="props.actionLabel || $t('INBOX_MGMT.CLICK_TO_RECONNECT')"
    @action="emit('reauthorize')"
  >
    {{ props.description || $t('INBOX_MGMT.RECONNECTION_REQUIRED') }}
  </Banner>
</template>
