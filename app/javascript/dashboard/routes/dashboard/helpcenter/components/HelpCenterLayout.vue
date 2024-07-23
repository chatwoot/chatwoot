<template>
  <div class="flex flex-grow-0 w-full h-full min-h-0 app-wrapper">
    <sidebar
      :route="currentRoute"
      @toggle-account-modal="toggleAccountModal"
      @open-notification-panel="openNotificationPanel"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
    />
    <help-center-sidebar
      v-if="showHelpCenterSidebar"
      :header-title="headerTitle"
      :portal-slug="selectedPortalSlug"
      :locale-slug="selectedLocaleInPortal"
      :sub-title="localeName(selectedLocaleInPortal)"
      :accessible-menu-items="accessibleMenuItems"
      :additional-secondary-menu-items="additionalSecondaryMenuItems"
      @open-popover="openPortalPopover"
      @open-modal="onClickOpenAddCategoryModal"
    />
    <section
      v-if="isHelpCenterEnabled"
      class="flex flex-1 h-full min-h-0 px-0 overflow-hidden bg-white dark:bg-slate-900"
    >
      <router-view @reload-locale="fetchPortalAndItsCategories" />
      <command-bar />
      <account-selector
        :show-account-modal="showAccountModal"
        @close-account-modal="toggleAccountModal"
      />
      <woot-key-shortcut-modal
        v-if="showShortcutModal"
        @close="closeKeyShortcutModal"
        @clickaway="closeKeyShortcutModal"
      />
      <notification-panel
        v-if="showNotificationPanel"
        @close="closeNotificationPanel"
      />
      <portal-popover
        v-if="showPortalPopover"
        :portals="portals"
        :active-portal-slug="selectedPortalSlug"
        :active-locale="selectedLocaleInPortal"
        @fetch-portal="fetchPortalAndItsCategories"
        @close-popover="closePortalPopover"
      />
      <add-category
        v-if="showAddCategoryModal"
        :show.sync="showAddCategoryModal"
        :portal-name="selectedPortalName"
        :locale="selectedLocaleInPortal"
        :portal-slug="selectedPortalSlug"
        @cancel="onClickCloseAddCategoryModal"
      />
    </section>
    <upgrade-page v-else />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import UpgradePage from './UpgradePage.vue';
import { frontendURL } from '../../../../helper/URLHelper';
import Sidebar from 'dashboard/components/layout/Sidebar.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import PortalPopover from '../components/PortalPopover.vue';
import HelpCenterSidebar from '../components/Sidebar/Sidebar.vue';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal.vue';
import AccountSelector from 'dashboard/components/layout/sidebarComponents/AccountSelector.vue';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import portalMixin from '../mixins/portalMixin';
import AddCategory from '../pages/categories/AddCategory.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
const CommandBar = () =>
  import('dashboard/routes/dashboard/commands/commandbar.vue');

export default {
  components: {
    AccountSelector,
    AddCategory,
    CommandBar,
    HelpCenterSidebar,
    NotificationPanel,
    PortalPopover,
    Sidebar,
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
      lastActivePortalSlug: '',
      showAccountModal: false,
    };
  },

  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      portals: 'portals/allPortals',
      categories: 'categories/allCategories',
      meta: 'portals/getMeta',
      isFetching: 'portals/isFetchingPortals',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),

    isHelpCenterEnabled() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.HELP_CENTER
      );
    },
    isSidebarOpen() {
      const { show_help_center_secondary_sidebar: showSecondarySidebar } =
        this.uiSettings;
      return showSecondarySidebar;
    },
    showHelpCenterSidebar() {
      if (!this.isHelpCenterEnabled) {
        return false;
      }

      return this.portals.length === 0 ? false : this.isSidebarOpen;
    },
    selectedPortal() {
      const slug = this.$route.params.portalSlug || this.lastActivePortalSlug;
      if (slug) return this.$store.getters['portals/portalBySlug'](slug);

      return this.$store.getters['portals/allPortals'][0];
    },
    selectedLocaleInPortal() {
      return this.$route.params.locale || this.defaultPortalLocale;
    },
    selectedPortalName() {
      return this.selectedPortal ? this.selectedPortal.name : '';
    },
    selectedPortalSlug() {
      return this.selectedPortal ? this.selectedPortal?.slug : '';
    },
    defaultPortalLocale() {
      return this.selectedPortal
        ? this.selectedPortal?.meta?.default_locale
        : '';
    },
    accessibleMenuItems() {
      if (!this.selectedPortal) return [];

      const {
        allArticlesCount,
        mineArticlesCount,
        draftArticlesCount,
        archivedArticlesCount,
      } = this.meta;

      return [
        {
          icon: 'book',
          label: 'HELP_CENTER.ALL_ARTICLES',
          key: 'list_all_locale_articles',
          count: allArticlesCount,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/${this.selectedPortalSlug}/${this.selectedLocaleInPortal}/articles`
          ),
          toolTip: 'All Articles',
          toStateName: 'list_all_locale_articles',
        },
        {
          icon: 'pen',
          label: 'HELP_CENTER.MY_ARTICLES',
          key: 'list_mine_articles',
          count: mineArticlesCount,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/${this.selectedPortalSlug}/${this.selectedLocaleInPortal}/articles/mine`
          ),
          toolTip: 'My articles',
          toStateName: 'list_mine_articles',
        },
        {
          icon: 'draft',
          label: 'HELP_CENTER.DRAFT',
          key: 'list_draft_articles',
          count: draftArticlesCount,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/${this.selectedPortalSlug}/${this.selectedLocaleInPortal}/articles/draft`
          ),
          toolTip: 'Draft',
          toStateName: 'list_draft_articles',
        },
        {
          icon: 'archive',
          label: 'HELP_CENTER.ARCHIVED',
          key: 'list_archived_articles',
          count: archivedArticlesCount,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/${this.selectedPortalSlug}/${this.selectedLocaleInPortal}/articles/archived`
          ),
          toolTip: 'Archived',
          toStateName: 'list_archived_articles',
        },
        {
          icon: 'settings',
          label: 'HELP_CENTER.SETTINGS',
          key: 'edit_portal_information',
          toState: frontendURL(
            `accounts/${this.accountId}/portals/${this.selectedPortalSlug}/edit`
          ),
          toStateName: 'edit_portal_information',
        },
      ];
    },
    additionalSecondaryMenuItems() {
      if (!this.selectedPortal) return [];
      return [
        {
          icon: 'folder',
          label: 'HELP_CENTER.CATEGORY',
          hasSubMenu: true,
          showNewButton: true,
          key: 'category',
          children: this.categories.map(category => ({
            id: category.id,
            label: category.icon
              ? `${category.icon} ${category.name}`
              : category.name,
            count: category.meta.articles_count,
            truncateLabel: true,
            toState: frontendURL(
              `accounts/${this.accountId}/portals/${this.selectedPortalSlug}/${category.locale}/categories/${category.slug}`
            ),
          })),
        },
      ];
    },
    currentRoute() {
      return '  ';
    },
    headerTitle() {
      return this.selectedPortal ? this.selectedPortal.name : '';
    },
  },

  watch: {
    '$route.name'() {
      const routeName = this.$route?.name;
      const routeParams = this.$route?.params;
      const updateMetaInAllPortals = routeName === 'list_all_portals';
      const updateMetaInEditArticle =
        routeName === 'edit_article' && routeParams?.recentlyCreated;
      const updateMetaInLocaleArticles =
        routeName === 'list_all_locale_articles' &&
        routeParams?.recentlyDeleted;
      if (
        updateMetaInAllPortals ||
        updateMetaInEditArticle ||
        updateMetaInLocaleArticles
      ) {
        this.fetchPortalAndItsCategories();
      }
    },
  },

  mounted() {
    this.$emitter.on(BUS_EVENTS.TOGGLE_SIDEMENU, this.toggleSidebar);

    const slug = this.$route.params.portalSlug;
    if (slug) this.lastActivePortalSlug = slug;

    this.fetchPortalAndItsCategories();
  },
  beforeDestroy() {
    this.$emitter.off(BUS_EVENTS.TOGGLE_SIDEMENU, this.toggleSidebar);
  },
  updated() {
    const slug = this.$route.params.portalSlug;
    if (slug !== this.lastActivePortalSlug) {
      this.lastActivePortalSlug = slug;
      this.updateUISettings({
        last_active_portal_slug: slug,
        last_active_locale_code: this.selectedLocaleInPortal,
      });
    }
  },
  methods: {
    toggleSidebar() {
      if (this.portals.length > 0) {
        this.updateUISettings({
          show_help_center_secondary_sidebar: !this.isSidebarOpen,
        });
      }
    },
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
