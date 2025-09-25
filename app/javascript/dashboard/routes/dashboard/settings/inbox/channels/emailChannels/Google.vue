<script setup>
import OAuthChannel from './OAuthChannel.vue';
import { defineOptions } from 'vue';

defineOptions({
  name: 'GoogleOAuthChannel',
});
</script>

<template>
  <OAuthChannel
    provider="google"
    :title="$t('INBOX_MGMT.ADD.GOOGLE.TITLE')"
    :description="$t('INBOX_MGMT.ADD.GOOGLE.DESCRIPTION')"
    :submit-button-text="$t('INBOX_MGMT.ADD.GOOGLE.SIGN_IN')"
    :error-message="$t('INBOX_MGMT.ADD.GOOGLE.ERROR_MESSAGE')"
  />
</template>
