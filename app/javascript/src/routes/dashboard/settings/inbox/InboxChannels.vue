<template>
  <div class="row content-box full-height">
    <woot-wizard class="small-3 columns" :items="wizardItems"></woot-wizard>
    <router-view></router-view>
  </div>
</template>
<script>
/* eslint no-console: 0 */
/* eslint-env browser */

export default {
  data() {
    return {
      wizardItems: this.$t('INBOX_MGMT.CREATE_FLOW'),
    };
  },
};
</script>
