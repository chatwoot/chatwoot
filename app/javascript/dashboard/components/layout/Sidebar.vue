<template>
  <aside class="woot-sidebar">
    <primary-sidebar
      :logo-source="globalConfig.logoThumbnail"
      :installation-name="globalConfig.installationName"
      :is-a-custom-branded-instance="isACustomBrandedInstance"
      :account-id="accountId"
      :menu-items="primaryMenuItems"
      :active-menu-item="activePrimaryMenu.key"
      @toggle-accounts="toggleAccountModal"
      @key-shortcut-modal="toggleKeyShortcutModal"
      @open-notification-panel="openNotificationPanel"
    />
    <secondary-sidebar
      v-if="showSecondarySidebar"
      :account-id="accountId"
      :inboxes="inboxes"
      :labels="labels"
      :teams="teams"
      :custom-views="customViews"
      :menu-config="activeSecondaryMenu"
      :current-role="currentRole"
      :is-on-chatwoot-cloud="isOnChatwootCloud"
      @add-label="showAddLabelPopup"
      @toggle-accounts="toggleAccountModal"
    />
  </aside>
</template>

<script>
import { mapGetters } from 'vuex';

import adminMixin from '../../mixins/isAdmin';
import { getSidebarItems } from './config/default-sidebar';
import alertMixin from 'shared/mixins/alertMixin';

import PrimarySidebar from './sidebarComponents/Primary';
import SecondarySidebar from './sidebarComponents/Secondary';
import {
  hasPressedAltAndCKey,
  hasPressedAltAndRKey,
  hasPressedAltAndSKey,
  hasPressedAltAndVKey,
  hasPressedCommandAndForwardSlash,
  isEscape,
} from 'shared/helpers/KeyboardHelpers';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import router from '../../routes';

export default {
  components: {
    PrimarySidebar,
    SecondarySidebar,
  },
  mixins: [adminMixin, alertMixin, eventListenerMixins],
  props: {
    showSecondarySidebar: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      showOptionsMenu: false,
    };
  },

  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      isACustomBrandedInstance: 'globalConfig/isACustomBrandedInstance',
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud',
      inboxes: 'inboxes/getInboxes',
      accountId: 'getCurrentAccountId',
      currentRole: 'getCurrentRole',
      labels: 'labels/getLabelsOnSidebar',
      teams: 'teams/getMyTeams',
    }),
    activeCustomView() {
      if (this.activePrimaryMenu.key === 'contacts') {
        return 'contact';
      }
      if (this.activePrimaryMenu.key === 'conversations') {
        return 'conversation';
      }
      return '';
    },
    customViews() {
      return this.$store.getters['customViews/getCustomViewsByFilterType'](
        this.activeCustomView
      );
    },
    isConversationOrContactActive() {
      return (
        this.activePrimaryMenu.key === 'contacts' ||
        this.activePrimaryMenu.key === 'conversations'
      );
    },
    sideMenuConfig() {
      return getSidebarItems(this.accountId);
    },
    primaryMenuItems() {
      const menuItems = this.sideMenuConfig.primaryMenu;
      return menuItems.filter(menuItem =>
        menuItem.roles.includes(this.currentRole)
      );
    },
    activeSecondaryMenu() {
      const { secondaryMenu } = this.sideMenuConfig;
      const { name: currentRoute } = this.$route;

      const activeSecondaryMenu =
        secondaryMenu.find(menuItem =>
          menuItem.routes.includes(currentRoute)
        ) || {};
      return activeSecondaryMenu;
    },
    activePrimaryMenu() {
      const activePrimaryMenu =
        this.primaryMenuItems.find(
          menuItem => menuItem.key === this.activeSecondaryMenu.parentNav
        ) || {};
      return activePrimaryMenu;
    },
  },

  watch: {
    activeCustomView() {
      this.fetchCustomViews();
    },
  },
  mounted() {
    this.$store.dispatch('labels/get');
    this.$store.dispatch('inboxes/get');
    this.$store.dispatch('notifications/unReadCount');
    this.$store.dispatch('teams/get');
    this.$store.dispatch('attributes/get');
    this.fetchCustomViews();
  },

  methods: {
    fetchCustomViews() {
      if (this.isConversationOrContactActive) {
        this.$store.dispatch('customViews/get', this.activeCustomView);
      }
    },
    toggleKeyShortcutModal() {
      this.$emit('open-key-shortcut-modal');
    },
    closeKeyShortcutModal() {
      this.$emit('close-key-shortcut-modal');
    },
    handleKeyEvents(e) {
      if (hasPressedCommandAndForwardSlash(e)) {
        this.toggleKeyShortcutModal();
      }
      if (isEscape(e)) {
        this.closeKeyShortcutModal();
      }

      if (hasPressedAltAndCKey(e)) {
        if (!this.isCurrentRouteSameAsNavigation('home')) {
          router.push({ name: 'home' });
        }
      } else if (hasPressedAltAndVKey(e)) {
        if (!this.isCurrentRouteSameAsNavigation('contacts_dashboard')) {
          router.push({ name: 'contacts_dashboard' });
        }
      } else if (hasPressedAltAndRKey(e)) {
        if (!this.isCurrentRouteSameAsNavigation('settings_account_reports')) {
          router.push({ name: 'settings_account_reports' });
        }
      } else if (hasPressedAltAndSKey(e)) {
        if (!this.isCurrentRouteSameAsNavigation('agent_list')) {
          router.push({ name: 'agent_list' });
        }
      }
    },
    isCurrentRouteSameAsNavigation(routeName) {
      return this.$route.name === routeName;
    },
    toggleSupportChatWindow() {
      window.$chatwoot.toggle();
    },
    toggleAccountModal() {
      this.$emit('toggle-account-modal');
    },
    showAddLabelPopup() {
      this.$emit('show-add-label-popup');
    },
    openNotificationPanel() {
      this.$emit('open-notification-panel');
    },
  },
};
</script>

<style lang="scss" scoped>
.woot-sidebar {
  background: var(--white);
  display: flex;
  min-height: 0;
  height: 100%;
  width: fit-content;
}
</style>

<style lang="scss">
@import '~dashboard/assets/scss/variables';

.account-selector--modal {
  .modal-container {
    width: 40rem;
  }
}

.account-selector {
  cursor: pointer;
  padding: $space-small $space-large;

  .selected--account {
    margin-top: -$space-smaller;

    & + .account--details {
      padding-left: $space-normal - $space-micro;
    }
  }

  .account--details {
    padding-left: $space-large + $space-smaller;
  }

  &:last-child {
    margin-bottom: $space-large;
  }

  a {
    align-items: center;
    cursor: pointer;
    display: flex;

    .account--name {
      cursor: pointer;
      font-size: $font-size-medium;
      font-weight: $font-weight-medium;
      line-height: 1;
    }

    .account--role {
      cursor: pointer;
      font-size: $font-size-mini;
      text-transform: capitalize;
    }
  }
}

.app-context-menu {
  align-items: center;
  cursor: pointer;
  display: flex;
  flex-direction: row;
  height: 6rem;
}

.current-user--options {
  font-size: $font-size-big;
  margin-bottom: auto;
  margin-left: auto;
  margin-top: auto;
}

.secondary-menu .nested.vertical.menu {
  margin-left: var(--space-small);
}
</style>
