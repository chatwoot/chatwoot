<template>
  <div
    v-if="showShowCurrentAccountContext"
    class="account-context--group"
    @mouseover="setShowSwitch"
    @mouseleave="resetShowSwitch"
  >
    {{ $t('SIDEBAR.CURRENTLY_VIEWING_ACCOUNT') }}
    <p class="account-context--name text-ellipsis">
      {{ account.name }}
    </p>
    <transition name="fade">
      <div v-if="showSwitchButton" class="account-context--switch-group">
        <woot-button
          variant="clear"
          size="tiny"
          icon="arrow-swap"
          class="switch-button"
          @click="$emit('toggle-accounts')"
        >
          {{ $t('SIDEBAR.SWITCH') }}
        </woot-button>
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
.account-context--group {
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  font-size: var(--font-size-mini);
  padding: var(--space-small);
  margin: var(--space-small) var(--space-small) 0 var(--space-small);
  position: relative;

  &:hover {
    background: var(--b-100);
  }

  .account-context--name {
    font-weight: var(--font-weight-medium);
    margin-bottom: 0;
  }
}

.switch-button {
  margin-right: var(--space-small);
}

.account-context--switch-group {
  --overlay-shadow: linear-gradient(
    to right,
    rgba(255, 255, 255, 0) 0%,
    rgba(255, 255, 255, 1) 50%
  );

  align-items: center;
  background-image: var(--overlay-shadow);
  border-top-left-radius: 0;
  border-top-right-radius: var(--border-radius-normal);
  border-bottom-left-radius: 0;
  border-bottom-right-radius: var(--border-radius-normal);
  display: flex;
  height: 100%;
  justify-content: flex-end;
  opacity: 1;
  position: absolute;
  right: 0;
  top: 0;
  width: 100%;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 300ms ease;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}
</style>
