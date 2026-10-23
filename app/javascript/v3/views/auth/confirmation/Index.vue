<script>
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import { verifyPasswordToken } from '../../../api/auth';
import {
  getLoginRedirectURL,
  getMfaSignInURL,
} from '../../../helpers/AuthHelper';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: { Spinner },
  props: {
    ssoAccountId: { type: String, default: '' },
    confirmationToken: {
      type: String,
      default: '',
    },
    redirectUrl: {
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
        const user = await verifyPasswordToken({
          confirmationToken: this.confirmationToken,
        });
        window.location =
          (user?.redirectUrl &&
            getMfaSignInURL({
              loginUrl: user.redirectUrl,
              redirectUrl: this.redirectUrl,
              ssoAccountId: this.ssoAccountId,
            })) ||
          getLoginRedirectURL({
            user,
            ssoAccountId: this.ssoAccountId,
            redirectUrl: this.redirectUrl,
          });
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
