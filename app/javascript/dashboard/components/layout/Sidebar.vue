<template>
  <aside ref="sidebarRef" class="flex h-full">
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
      :class="sidebarClassName"
      :account-id="accountId"
      :inboxes="inboxes"
      :labels="labels"
      :teams="teams"
      :custom-views="customViews"
      :menu-config="activeSecondaryMenu"
      :current-user="currentUser"
      :is-on-chatwoot-cloud="isOnChatwootCloud"
      @add-label="showAddLabelPopup"
      @toggle-accounts="toggleAccountModal"
    />
  </aside>
</template>

<script>
import { ref } from 'vue';
import { mapGetters } from 'vuex';
import { getSidebarItems } from './config/default-sidebar';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useRoute, useRouter } from 'dashboard/composables/route';

import PrimarySidebar from './sidebarComponents/Primary.vue';
import SecondarySidebar from './sidebarComponents/Secondary.vue';
import { routesWithPermissions } from '../../routes';
import { hasPermissions } from '../../helper/permissionsHelper';

export default {
  components: {
    PrimarySidebar,
    SecondarySidebar,
  },
  props: {
    showSecondarySidebar: {
      type: Boolean,
      default: true,
    },
    sidebarClassName: {
      type: String,
      default: '',
    },
  },
  setup(props, { emit }) {
    const sidebarRef = ref(null);
    const route = useRoute();
    const router = useRouter();

    const toggleKeyShortcutModal = () => {
      emit('open-key-shortcut-modal');
    };

    const closeKeyShortcutModal = () => {
      emit('close-key-shortcut-modal');
    };

    const isCurrentRouteSameAsNavigation = routeName => {
      return route.name === routeName;
    };
    const navigateToRoute = routeName => {
      if (!isCurrentRouteSameAsNavigation(routeName)) {
        router.push({ name: routeName });
      }
    };

    const keyboardEvents = {
      '$mod+Slash': {
        action: toggleKeyShortcutModal,
      },
      '$mod+Escape': {
        action: closeKeyShortcutModal,
      },
      'Alt+KeyC': {
        action: () => navigateToRoute('home'),
      },
      'Alt+KeyV': {
        action: () => navigateToRoute('contacts_dashboard'),
      },
      'Alt+KeyR': {
        action: () => navigateToRoute('account_overview_reports'),
      },
      'Alt+KeyS': {
        action: () => navigateToRoute('agent_list'),
      },
    };

    useKeyboardEvents(keyboardEvents, sidebarRef);

    return {
      toggleKeyShortcutModal,
      sidebarRef,
    };
  },
  data() {
    return {
      showOptionsMenu: false,
    };
  },

  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      currentRole: 'getCurrentRole',
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      inboxes: 'inboxes/getInboxes',
      isACustomBrandedInstance: 'globalConfig/isACustomBrandedInstance',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud',
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
      const userPermissions = this.currentUser.permissions;
      const menuItems = this.sideMenuConfig.primaryMenu;
      return menuItems.filter(menuItem => {
        const isAvailableForTheUser = hasPermissions(
          routesWithPermissions[menuItem.toStateName],
          userPermissions
        );

        if (!isAvailableForTheUser) {
          return false;
        }
        if (
          menuItem.alwaysVisibleOnChatwootInstances &&
          !this.isACustomBrandedInstance
        ) {
          return true;
        }
        if (menuItem.featureFlag) {
          return this.isFeatureEnabledonAccount(
            this.accountId,
            menuItem.featureFlag
          );
        }
        return true;
      });
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
