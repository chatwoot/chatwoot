<template>
  <div class="wizard-body columns content-box small-9">
    <form class="row" method="POST" action="/twitter/authorization">
      <input type="hidden" name="user_id" :value="currentUserID" />
      <woot-submit-button button-text="Sign in with Twitter" type="submit" />
    </form>
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
