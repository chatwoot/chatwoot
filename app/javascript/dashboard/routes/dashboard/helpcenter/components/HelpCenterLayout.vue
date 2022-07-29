<template>
  <div class="row app-wrapper">
    <sidebar
      :route="currentRoute"
      @open-notification-panel="openNotificationPanel"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @close-key-shortcut-modal="closeKeyShortcutModal"
    />
    <div class="margin-right-small">
      <help-center-sidebar
        header-title="Help Center"
        sub-title="English"
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
        @close-popover="closePortalPopover"
      />
    </section>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

import { frontendURL } from '../../../../helper/URLHelper';
import Sidebar from 'dashboard/components/layout/Sidebar';
import PortalPopover from 'dashboard/routes/dashboard/helpcenter/components/PortalPopover';
import HelpCenterSidebar from 'dashboard/routes/dashboard/helpcenter/components/Sidebar/Sidebar';
import CommandBar from 'dashboard/routes/dashboard/commands/commandbar.vue';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel.vue';

export default {
  components: {
    Sidebar,
    HelpCenterSidebar,
    CommandBar,
    WootKeyShortcutModal,
    NotificationPanel,
    PortalPopover,
  },
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
    }),
    accessibleMenuItems() {
      return [
        {
          icon: 'book',
          label: 'HELP_CENTER.ALL_ARTICLES',
          key: 'list_all_locale_articles',
          count: 199,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/:portalSlug/:locale/articles`
          ),
          toolTip: 'All Articles',
          toStateName: 'list_all_locale_articles',
        },
        {
          icon: 'pen',
          label: 'HELP_CENTER.MY_ARTICLES',
          key: 'mine_articles',
          count: 112,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/:portalSlug/:locale/articles/mine`
          ),
          toolTip: 'My articles',
          toStateName: 'mine_articles',
        },
        {
          icon: 'draft',
          label: 'HELP_CENTER.DRAFT',
          key: 'list_draft_articles',
          count: 32,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/:portalSlug/:locale/articles/draft`
          ),
          toolTip: 'Draft',
          toStateName: 'list_draft_articles',
        },
        {
          icon: 'archive',
          label: 'HELP_CENTER.ARCHIVED',
          key: 'list_archived_articles',
          count: 10,
          toState: frontendURL(
            `accounts/${this.accountId}/portals/:portalSlug/:locale/articles/archived`
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
            {
              id: 3,
              label: 'Feature',
              count: 24,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/feature`
              ),
            },
            {
              id: 4,
              label: 'Advanced',
              count: 8,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/advanced`
              ),
            },
            {
              id: 5,
              label: 'Mobile app',
              count: 3,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/mobile-app`
              ),
            },
            {
              id: 6,
              label: 'Others',
              count: 39,
              truncateLabel: true,
              toState: frontendURL(
                `accounts/${this.accountId}/portals/:portalSlug/:locale/categories/others`
              ),
            },
          ],
        },
      ];
    },
    portals() {
      return [
        {
          name: 'Chatwoot Help Center',
          id: 1,
          color: null,
          custom_domain: 'doc',
          articles_count: 123,
          header_text: null,
          homepage_link: null,
          page_title: null,
          slug: 'first_portal',
          archived: false,
          config: {
            allowed_locales: [
              {
                code: 'en',
                name: 'English',
                articles_count: 123,
              },
              {
                code: 'fr',
                name: 'Français',
                articles_count: 123,
              },
              {
                code: 'de',
                name: 'Deutsch',
                articles_count: 32,
              },
              {
                code: 'es',
                name: 'Español',
                articles_count: 12,
              },
              {
                code: 'it',
                name: 'Italiano',
                articles_count: 8,
              },
            ],
          },
          locales: [
            {
              name: 'English',
              code: 'en',
              articles_count: 12,
            },
            {
              name: 'Español',
              code: 'es',
              articles_count: 42,
            },
            {
              name: 'French',
              code: 'fr',
              articles_count: 29,
            },
            {
              name: 'Italian',
              code: 'it',
              articles_count: 4,
            },
            {
              name: 'German',
              code: 'de',
              articles_count: 66,
            },
          ],
        },
        {
          name: 'Chatwoot Docs',
          id: 2,
          color: null,
          custom_domain: 'doc',
          articles_count: 124,
          header_text: null,
          homepage_link: null,
          page_title: null,
          slug: 'second_portal',
          archived: false,
          config: {
            allowed_locales: [
              {
                code: 'en',
                name: 'English',
                articles_count: 123,
              },
              {
                code: 'fr',
                name: 'Français',
                articles_count: 123,
              },
              {
                code: 'de',
                name: 'Deutsch',
                articles_count: 32,
              },
              {
                code: 'es',
                name: 'Español',
                articles_count: 12,
              },
              {
                code: 'it',
                name: 'Italiano',
                articles_count: 8,
              },
            ],
          },
          locales: [
            {
              name: 'English',
              code: 'en',
              articles_count: 12,
            },
            {
              name: 'Japanese',
              code: 'jp',
              articles_count: 4,
            },
            {
              name: 'Mandarin',
              code: 'CH',
              articles_count: 6,
            },
          ],
        },
      ];
    },
    currentRoute() {
      return ' ';
    },
  },
  methods: {
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
