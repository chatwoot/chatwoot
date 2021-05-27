<template>
  <loading-state :message="$t('CONFIRM_EMAIL')"></loading-state>
</template>
<script>
/* eslint-disable */
import LoadingState from '../../components/widgets/LoadingState';
import Auth from '../../api/auth';
export default {
  props: {
    confirmationToken: String,
    redirectUrl: String,
    config: String,
  },
  components: {
    LoadingState,
  },
  mounted() {
    this.confirmToken();
  },
  methods: {
    confirmToken() {
      Auth.verifyPasswordToken({
        confirmationToken: this.confirmationToken
      }).then(res => {
        if (res.status === 200) {
          window.location = '/';
        } else{ 
          window.location = res.data.redirect_url;
        }
      }).catch(res => {
        window.location = '/';
      });
    }
  }
}
</script>
