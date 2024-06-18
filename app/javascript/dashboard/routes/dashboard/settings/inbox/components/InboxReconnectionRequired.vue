<script setup>
import Banner from 'dashboard/components/ui/Banner.vue';
</script>

<template>
  <banner
    color-scheme="alert"
    class="justify-start rounded-md"
    :banner-message="$t('INBOX_MGMT.RECONNECTION_REQUIRED')"
    :action-button-label="$t('INBOX_MGMT.CLICK_TO_RECONNECT')"
    has-action-button
    @click="$emit('reauthorize')"
  />
</template>
