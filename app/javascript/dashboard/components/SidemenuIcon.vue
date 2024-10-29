<script>
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { mapGetters } from 'vuex';
import { emitter } from 'shared/helpers/mitt';

export default {
  props: {
    size: {
      type: String,
      default: 'small',
    },
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    hasNextSidebar() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.CHATWOOT_V4
      );
    },
  },
  methods: {
    onMenuItemClick() {
      emitter.emit(BUS_EVENTS.TOGGLE_SIDEMENU);
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <woot-button
    v-if="!hasNextSidebar"
    :size="size"
    variant="clear"
    color-scheme="secondary"
    class="-ml-3 text-black-900 dark:text-slate-300"
    icon="list"
    @click="onMenuItemClick"
  />
</template>
