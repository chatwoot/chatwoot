<template>
  <div
    v-if="showShowCurrentAccountContext"
    class="rounded-md text-xs py-2 px-2 mt-2 relative border border-slate-50 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700 cursor-pointer"
    @mouseover="setShowSwitch"
    @mouseleave="resetShowSwitch"
  >
    {{ $t('SIDEBAR.CURRENTLY_VIEWING_ACCOUNT') }}
    <p class="text-ellipsis font-medium mb-0">
      {{ account.name }}
    </p>
    <transition name="fade">
      <div
        v-if="showSwitchButton"
        class="bg-gradient-to-r rtl:bg-gradient-to-l from-transparent via-white dark:via-slate-700 to-white dark:to-slate-700 flex items-center h-full justify-end absolute top-0 right-0 w-full"
      >
        <div class="my-0 mx-2">
          <woot-button
            variant="clear"
            size="tiny"
            icon="arrow-swap"
            @click="$emit('toggle-accounts')"
          >
            {{ $t('SIDEBAR.SWITCH') }}
          </woot-button>
        </div>
      </div>
    </transition>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

export default {
  data() {
    return { showSwitchButton: false };
  },
  computed: {
    ...mapGetters({
      account: 'getCurrentAccount',
      userAccounts: 'getUserAccounts',
    }),
    showShowCurrentAccountContext() {
      return this.userAccounts.length > 1 && this.account.name;
    },
  },
  methods: {
    setShowSwitch() {
      this.showSwitchButton = true;
    },
    resetShowSwitch() {
      this.showSwitchButton = false;
    },
  },
};
</script>
<style scoped lang="scss">
.fade-enter-active,
.fade-leave-active {
  transition: opacity 300ms ease;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}
</style>
