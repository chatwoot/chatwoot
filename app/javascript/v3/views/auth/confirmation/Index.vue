<script>
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
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
        window.location = DEFAULT_REDIRECT_URL;
      } catch (error) {
        window.location = DEFAULT_REDIRECT_URL;
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
