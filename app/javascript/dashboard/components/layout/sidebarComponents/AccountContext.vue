<template>
  <div v-if="showShowCurrentAccountContext" class="account-context--group">
    {{ $t('SIDEBAR.CURRENTLY_VIEWING_ACCOUNT') }}
    <p class="account-context--name text-ellipsis">
      {{ account.name }}
    </p>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
export default {
  computed: {
    ...mapGetters({
      account: 'getCurrentAccount',
      userAccounts: 'getUserAccounts',
    }),
    showShowCurrentAccountContext() {
      return this.userAccounts.length > 1 && this.account.name;
    },
  },
};
</script>
<style scoped lang="scss">
.account-context--group {
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  font-size: var(--font-size-mini);
  padding: var(--space-small);
  margin-bottom: var(--space-small);

  .account-context--name {
    font-weight: var(--font-weight-medium);
    margin-bottom: 0;
  }
}
</style>
