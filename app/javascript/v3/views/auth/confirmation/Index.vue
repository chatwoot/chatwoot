<script>
import { verifyPasswordToken } from '../../../api/auth';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: { Spinner },
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
        // After successful confirmation, redirect to login page
        // The user needs to login after email confirmation
        window.location = '/app/login';
      } catch (error) {
        // On error, also redirect to login page with error message
        window.location = '/app/login?error=invalid_confirmation_token';
      }
    },
  },
};
</script>

<template>
  <div
    class="flex items-center justify-center min-h-screen h-full bg-n-background w-full"
  >
    <Spinner color-scheme="primary" size="" />
    <div class="ml-2 text-n-slate-11">{{ $t('CONFIRM_EMAIL') }}</div>
  </div>
</template>
