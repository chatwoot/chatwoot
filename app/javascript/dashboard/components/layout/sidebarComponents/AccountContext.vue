<script>
import { mapGetters } from 'vuex';

export default {
  emits: ['toggleAccounts'],
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

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="showShowCurrentAccountContext"
    class="relative px-2 py-2 mt-2 text-xs border rounded-md cursor-pointer text-slate-700 dark:text-slate-200 border-slate-50 dark:border-slate-800/50 hover:bg-slate-50 dark:hover:bg-slate-800"
    @mouseover="setShowSwitch"
    @mouseleave="resetShowSwitch"
  >
    {{ $t('SIDEBAR.CURRENTLY_VIEWING_ACCOUNT') }}
    <p
      class="mb-0 overflow-hidden font-medium text-ellipsis whitespace-nowrap text-slate-800 dark:text-slate-100"
    >
      {{ account.name }}
    </p>
    <transition name="fade">
      <div
        v-if="showSwitchButton"
        class="absolute top-0 right-0 flex items-center justify-end w-full h-full rounded-md ltr:overlay-shadow ltr:dark:overlay-shadow-dark rtl:rtl-overlay-shadow rtl:dark:rtl-overlay-shadow-dark"
      >
        <div class="mx-2 my-0">
          <woot-button
            variant="clear"
            size="tiny"
            icon="arrow-swap"
            @click="$emit('toggleAccounts')"
          >
            {{ $t('SIDEBAR.SWITCH') }}
          </woot-button>
        </div>
      </div>
    </transition>
  </div>
</template>

<style scoped>
@tailwind components;
@layer components {
  .overlay-shadow {
    background-image: linear-gradient(
      to right,
      rgba(255, 255, 255, 0) 0%,
      rgba(255, 255, 255, 1) 50%
    );
  }

  .overlay-shadow-dark {
    background-image: linear-gradient(
      to right,
      rgba(0, 0, 0, 0) 0%,
      rgb(21, 23, 24) 50%
    );
  }

  .rtl-overlay-shadow {
    background-image: linear-gradient(
      to left,
      rgba(255, 255, 255, 0) 0%,
      rgba(255, 255, 255, 1) 50%
    );
  }

  .rtl-overlay-shadow-dark {
    background-image: linear-gradient(
      to left,
      rgba(0, 0, 0, 0) 0%,
      rgb(21, 23, 24) 50%
    );
  }
}
.fade-enter-active,
.fade-leave-active {
  transition: opacity 300ms ease;
}

.fade-enter,
.fade-leave-to {
  @apply opacity-0;
}
</style>
