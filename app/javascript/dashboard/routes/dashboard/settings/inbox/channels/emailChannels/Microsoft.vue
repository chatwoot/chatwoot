<script setup>
import OAuthChannel from './OAuthChannel.vue';
import { defineOptions } from 'vue';

defineOptions({
  name: 'MicrosoftOAuthChannel',
});
</script>

<template>
  <OAuthChannel
    provider="microsoft"
    :title="$t('INBOX_MGMT.ADD.MICROSOFT.TITLE')"
    :description="$t('INBOX_MGMT.ADD.MICROSOFT.DESCRIPTION')"
    :submit-button-text="$t('INBOX_MGMT.ADD.MICROSOFT.SIGN_IN')"
    :error-message="$t('INBOX_MGMT.ADD.MICROSOFT.ERROR_MESSAGE')"
  />
</template>
