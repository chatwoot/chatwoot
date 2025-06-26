<script setup>
import Banner from 'dashboard/components-next/banner/Banner.vue';

const emit = defineEmits(['reauthorize']);
</script>

<template>
  <Banner
    color="ruby"
    :action-label="$t('INBOX_MGMT.CLICK_TO_RECONNECT')"
    @action="emit('reauthorize')"
  >
    {{ $t('INBOX_MGMT.RECONNECTION_REQUIRED') }}
  </Banner>
</template>
