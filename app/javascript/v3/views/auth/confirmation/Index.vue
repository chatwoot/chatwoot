<template>
  <div class="flex items-center justify-center h-full w-full">
    <woot-spinner color-scheme="primary" size="" />
    <div class="ml-2">{{ $t('CONFIRM_EMAIL') }}</div>
  </div>
</template>
<script>
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { verifyPasswordToken } from '../../../api/auth';

export default {
  props: {
    confirmationToken: {
      type: String,
      default: '',
    },
  },
  mounted() {
    this.confirmToken();
  },
  methods: {
    async confirmToken() {
      try {
        await verifyPasswordToken({
          confirmationToken: this.confirmationToken,
        });
        window.location = DEFAULT_REDIRECT_URL;
      } catch (error) {
        window.location = DEFAULT_REDIRECT_URL;
      }
    },
  },
};
</script>
