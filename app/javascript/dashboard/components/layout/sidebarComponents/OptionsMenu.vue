<template>
  <transition name="menu-slide">
    <div
      v-if="show"
      v-on-clickaway="onClickAway"
      class="dropdown-pane"
      :class="{ 'dropdown-pane--open': show }"
    >
      <availability-status />
      <woot-dropdown-menu>
        <woot-dropdown-item v-if="showChangeAccountOption">
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="ion-arrow-swap"
            class=" change-accounts--button"
            @click="$emit('toggle-accounts')"
          >
            {{ $t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item v-if="globalConfig.chatwootInboxToken">
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="ion-help-buoy"
            class=" change-accounts--button"
            @click="$emit('show-support-chat-window')"
          >
            Contact Support
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            size="small"
            class=" change-accounts--button"
            @click="$emit('key-shortcut-modal')"
          >
            {{ $t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <router-link
            :to="`/app/accounts/${accountId}/profile/settings`"
            class="button clear small secondary change-accounts--button"
          >
            <i class="icon ion-person" />
            <span class="button__content">
              {{ $t('SIDEBAR_ITEMS.PROFILE_SETTINGS') }}
            </span>
          </router-link>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="ion-log-out"
            class=" change-accounts--button"
            @click="logout"
          >
            {{ $t('SIDEBAR_ITEMS.LOGOUT') }}
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
  </transition>
</template>

<script>
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';
import Auth from '../../../api/auth';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu';
import AvailabilityStatus from 'dashboard/components/layout/AvailabilityStatus';

export default {
  components: {
    WootDropdownMenu,
    WootDropdownItem,
    AvailabilityStatus,
  },
  mixins: [clickaway],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      accountId: 'getCurrentAccountId',
    }),
    showChangeAccountOption() {
      if (this.globalConfig.createNewAccountFromDashboard) {
        return true;
      }

      const { accounts = [] } = this.currentUser;
      return accounts.length > 1;
    },
  },
  methods: {
    logout() {
      Auth.logout();
    },
    onClickAway() {
      if (this.show) this.$emit('close');
    },
  },
};
</script>
<style lang="scss" scoped>
.dropdown-pane {
  left: var(--space-slab);
  bottom: var(--space-larger);
}
</style>
