<template>
  <div class="row app-wrapper">
    <sidebar
      :route="currentRoute"
      @open-notification-panel="openNotificationPanel"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
    />
    <div v-if="portals.length" class="margin-right-small">
      <help-center-sidebar
        :header-title="headerTitle"
        :sub-title="localeName(selectedPortalLocale)"
        :accessible-menu-items="accessibleMenuItems"
        :additional-secondary-menu-items="additionalSecondaryMenuItems"
        @open-popover="openPortalPopover"
      />
    </div>
    <section class="app-content columns">
      <router-view />
      <command-bar />
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
        :active-portal="selectedPortal"
        @close-popover="closePortalPopover"
      />
    </section>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

import { frontendURL } from '../../../../helper/URLHelper';
import Sidebar from 'dashboard/components/layout/Sidebar';
import PortalPopover from '../components/PortalPopover.vue';
import HelpCenterSidebar from '../components/Sidebar/Sidebar.vue';
import CommandBar from 'dashboard/routes/dashboard/commands/commandbar.vue';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel.vue';
import portalMixin from '../mixins/portalMixin';
export default {
  components: {
    Sidebar,
    HelpCenterSidebar,
    CommandBar,
    WootKeyShortcutModal,
    NotificationPanel,
    PortalPopover,
  },
  mixins: [portalMixin],
  data() {
    return {
      showShortcutModal: false,
      showNotificationPanel: false,
      showPortalPopover: false,
    };
  },

  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      selectedPortal: 'portals/getSelectedPortal',
      portals: 'portals/allPortals',
      meta: 'portals/getMeta',
      isFetching: 'portals/isFetchingPortals',
    }),
    selectedPortalSlug() {
      return this.portalSlug || this.selectedPortal?.slug;
    },
    selectedPortalLocale() {
      return this.locale || this.selectedPortal?.meta?.default_locale;
    },
    accessibleMenuItems() {
      const {
        meta: {
          all_articles_count: allArticlesCount,
          mine_articles_count: mineArticlesCount,
          draft_articles_count: draftArticlesCount,
          archived_articles_count: archivedArticlesCount,
        } = {},
      } = this.selectedPortal;
      return [
        {
          icon: 'book',
          label: 'HELP_CENTER.ALL_ARTICLES',
          key: 'list_all_locale_articles',
          count: allArticlesCount,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/${this.selectedPortalSlug}/${this.selectedPortalLocale}/articles`
          ),
          toolTip: 'All Articles',
          toStateName: 'list_all_selectedPortalLocale_articles',
        },
        {
          icon: 'pen',
          label: 'HELP_CENTER.MY_ARTICLES',
          key: 'mine_articles',
          count: mineArticlesCount,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/${this.selectedPortalSlug}/${this.selectedPortalLocale}/articles/mine`
          ),
          toolTip: 'My articles',
          toStateName: 'mine_articles',
        },
        {
          icon: 'draft',
          label: 'HELP_CENTER.DRAFT',
          key: 'list_draft_articles',
          count: draftArticlesCount,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/${this.selectedPortalSlug}/${this.selectedPortalLocale}/articles/draft`
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
            `accounts/${this.accountId}/portals/${this.selectedPortalSlug}/${this.selectedPortalLocale}/articles/archived`
          ),
          toolTip: 'Archived',
          toStateName: 'list_archived_articles',
        },
      ];
    },
    additionalSecondaryMenuItems() {
      return [
        {
          icon: 'folder',
          label: 'HELP_CENTER.CATEGORY',
          hasSubMenu: true,
          key: 'category',
          children: [
            {
              id: 1,
              label: 'Getting started',
              count: 12,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/getting-started`
              ),
            },
            {
              id: 2,
              label: 'Channel',
              count: 19,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/channel`
              ),
            },
          ],
        },
      ];
    },
    currentRoute() {
      return ' ';
    },
    headerTitle() {
      return this.selectedPortal.name;
    },
  },
  mounted() {
    this.fetchPortals();
  },
  methods: {
    fetchPortals() {
      this.$store.dispatch('portals/index');
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
  },
};
</script>
