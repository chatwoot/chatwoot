<template>
  <div v-if="isFeatureEnabled">
    <slot />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
export default {
  props: {
    featureKey: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      accountId: 'getCurrentAccountId',
    }),
    isFeatureEnabled() {
      return this.isFeatureEnabledonAccount(this.accountId, this.featureKey);
    },
  },
};
</script>
