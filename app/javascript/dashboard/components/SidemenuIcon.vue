<script>
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { mapGetters } from 'vuex';
import { emitter } from 'shared/helpers/mitt';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    size: {
      type: String,
      default: 'sm',
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
  <NextButton
    v-if="!hasNextSidebar"
    ghost
    slate
    :size="size"
    icon="i-lucide-menu"
    class="-ml-3"
    @click="onMenuItemClick"
  />
</template>
