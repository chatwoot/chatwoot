<template>
  <div class="wizard-body columns content-box small-9">
    <div class="login-init full-height text-center">
      <form method="POST" action="/twitter/authorization">
        <input type="hidden" name="user_id" :value="currentUserID" />
        <woot-submit-button
          icon-class="ion-social-twitter"
          button-text="Sign in with Twitter"
          type="submit"
        />
      </form>
      <p>{{ $t('INBOX_MGMT.ADD.TWITTER.HELP') }}</p>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      currentUserID: 'getCurrentUserID',
    }),
  },
};
</script>
