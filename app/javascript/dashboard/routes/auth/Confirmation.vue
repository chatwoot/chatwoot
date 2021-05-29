<template>
  <loading-state :message="$t('CONFIRM_EMAIL')"></loading-state>
</template>
<script>
import LoadingState from '../../components/widgets/LoadingState';
import Auth from '../../api/auth';
import { DEFAULT_REDIRECT_URL } from '../../constants';
export default {
  components: {
    LoadingState,
  },
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
        const {
          data: { redirect_url: redirectURL },
        } = await Auth.verifyPasswordToken({
          confirmationToken: this.confirmationToken,
        });
        window.location = redirectURL;
      } catch (error) {
        window.location = DEFAULT_REDIRECT_URL;
      }
    },
  },
};
</script>
