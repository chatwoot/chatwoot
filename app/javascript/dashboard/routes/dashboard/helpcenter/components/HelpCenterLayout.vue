<script>
import { defineAsyncComponent } from 'vue';
import { mapGetters } from 'vuex';
import UpgradePage from './UpgradePage.vue';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal.vue';
import AccountSelector from 'dashboard/components/layout/sidebarComponents/AccountSelector.vue';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import portalMixin from '../mixins/portalMixin';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const CommandBar = defineAsyncComponent(
  () => import('dashboard/routes/dashboard/commands/commandbar.vue')
);

// Add Sidebar as an async component
const Sidebar = defineAsyncComponent(
  () => import('dashboard/components/layout/Sidebar.vue')
);

export default {
  components: {
    Sidebar,
    AccountSelector,
    CommandBar,
    NotificationPanel,
    UpgradePage,
    WootKeyShortcutModal,
  },
  mixins: [portalMixin],
  setup() {
    const { uiSettings, updateUISettings } = useUISettings();

    return {
      uiSettings,
      updateUISettings,
    };
  },
  data() {
    return {
      isOnDesktop: true,
      showShortcutModal: false,
      showNotificationPanel: false,
      showPortalPopover: false,
      showAddCategoryModal: false,
      showAccountModal: false,
    };
  },

  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      portals: 'portals/allPortals',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),

    isHelpCenterEnabled() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.HELP_CENTER
      );
    },
    selectedPortal() {
      const slug = this.$route.params.portalSlug || this.lastActivePortalSlug;
      if (slug) return this.$store.getters['portals/portalBySlug'](slug);

      return this.portals[0];
    },
    selectedLocaleInPortal() {
      return this.$route.params.locale || this.defaultPortalLocale;
    },
    selectedPortalSlug() {
      return this.selectedPortal ? this.selectedPortal?.slug : '';
    },
    defaultPortalLocale() {
      return this.selectedPortal
        ? this.selectedPortal?.meta?.default_locale
        : '';
    },
    currentRoute() {
      return '  ';
    },
  },

  mounted() {
    this.fetchPortalAndItsCategories();
  },
  updated() {
    const slug = this.$route.params.portalSlug;
    const { last_active_portal_slug: lastActivePortalSlug } = this.uiSettings;

    if (slug && slug !== lastActivePortalSlug) {
      this.updateUISettings({
        last_active_portal_slug: slug,
        last_active_locale_code: this.selectedLocaleInPortal,
      });
    }
  },
  methods: {
    async fetchPortalAndItsCategories() {
      await this.$store.dispatch('portals/index');
      const selectedPortalParam = {
        portalSlug: this.selectedPortalSlug,
        locale: this.selectedLocaleInPortal,
      };
      this.$store.dispatch('portals/show', selectedPortalParam);
      this.$store.dispatch('categories/index', selectedPortalParam);
      this.$store.dispatch('agents/get');
    },
    toggleKeyShortcutModal() {
      this.showShortcutModal = true;
    },
    closeKeyShortcutModal() {
      this.showShortcutModal = false;
    },
    openNotificationPanel() {
      this.showNotificationPanel = true;
    },
    closeNotificationPanel() {
      this.showNotificationPanel = false;
    },
    openPortalPopover() {
      this.showPortalPopover = !this.showPortalPopover;
    },
    closePortalPopover() {
      this.showPortalPopover = false;
    },
    onClickOpenAddCategoryModal() {
      this.showAddCategoryModal = true;
    },
    onClickCloseAddCategoryModal() {
      this.showAddCategoryModal = false;
    },
    toggleAccountModal() {
      this.showAccountModal = !this.showAccountModal;
    },
  },
};
</script>

<template>
  <div class="flex flex-grow-0 w-full h-full min-h-0 app-wrapper">
    <Sidebar
      :route="currentRoute"
      @toggle-account-modal="toggleAccountModal"
      @open-notification-panel="openNotificationPanel"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
    />
    <section
      v-if="isHelpCenterEnabled"
      class="flex flex-1 h-full px-0 overflow-hidden bg-white dark:bg-slate-900"
    >
      <router-view />
      <CommandBar />
      <AccountSelector
        :show-account-modal="showAccountModal"
        @close-account-modal="toggleAccountModal"
      />
      <WootKeyShortcutModal
        v-if="showShortcutModal"
        @close="closeKeyShortcutModal"
        @clickaway="closeKeyShortcutModal"
      />
      <NotificationPanel
        v-if="showNotificationPanel"
        @close="closeNotificationPanel"
      />
    </section>
    <UpgradePage v-else />
  </div>
</template>
