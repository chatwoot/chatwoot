<template>
  <div class="column content-box account-locked">
    <div class="lock-message">
      <!-- No inboxes attached -->
      <div>
        <img src="~assets/images/lock.svg" alt="Lock" />
        <span v-html="$t('BILLING.ACCOUNT_LOCKED')">
        </span>
      </div>
    </div>
  </div>
</template>

<script>
/* eslint no-console: 0 */
/* global bus */
export default {
  props: ['state'],


};
</script>
