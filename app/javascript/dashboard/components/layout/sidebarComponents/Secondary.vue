<template>
  <div
    v-if="hasSecondaryMenu"
    class="h-full overflow-auto w-48 flex flex-col bg-white dark:bg-slate-900 border-r dark:border-slate-800/50 rtl:border-r-0 rtl:border-l border-slate-50 text-sm px-2 pb-8"
  >
    <account-context @toggle-accounts="toggleAccountModal" />
    <transition-group
      name="menu-list"
      tag="ul"
      class="pt-2 list-none ml-0 mb-0"
    >
      <secondary-nav-item
        v-for="menuItem in accessibleMenuItems"
        :key="menuItem.toState"
        :menu-item="menuItem"
      />
      <secondary-nav-item
        v-for="menuItem in additionalSecondaryMenuItems[menuConfig.parentNav]"
        :key="menuItem.key"
        :menu-item="menuItem"
        @add-label="showAddLabelPopup"
      />
    </transition-group>
  </div>
</template>
<script>
import { frontendURL } from '../../../helper/URLHelper';
import SecondaryNavItem from './SecondaryNavItem.vue';
import AccountContext from './AccountContext.vue';
import { mapGetters } from 'vuex';
import { FEATURE_FLAGS } from '../../../featureFlags';

export default {
  components: {
    AccountContext,
    SecondaryNavItem,
  },
  props: {
    accountId: {
      type: Number,
      default: 0,
    },
    labels: {
      type: Array,
      default: () => [],
    },
    inboxes: {
      type: Array,
      default: () => [],
    },
    teams: {
      type: Array,
      default: () => [],
    },
    conversationStatuses: {
      type: Array,
      default: () => [],
    },
    customViews: {
      type: Array,
      default: () => [],
    },
    menuConfig: {
      type: Object,
      default: () => {},
    },
    currentRole: {
      type: String,
      default: '',
    },
    isOnChatwootCloud: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    hasSecondaryMenu() {
      return this.menuConfig.menuItems && this.menuConfig.menuItems.length;
    },
    contactCustomViews() {
      return this.customViews.filter(
        view => view.filter_type === 'contact' && view.account_scoped === false
      );
    },
    contactCustomGlobalViews() {
      return this.customViews.filter(
        view => view.filter_type === 'contact' && view.account_scoped === true
      );
    },
    accessibleMenuItems() {
      if (!this.currentRole) {
        return [];
      }
      let menuItemsFilteredByRole = this.menuConfig.menuItems.filter(
        menuItem =>
          window.roleWiseRoutes[this.currentRole].indexOf(
            menuItem.toStateName
          ) > -1
      );
      menuItemsFilteredByRole = menuItemsFilteredByRole.filter(item => {
        if (item.showOnlyOnCloud) {
          return this.isOnChatwootCloud;
        }
        return true;
      });
      if (this.menuConfig.parentNav === 'conversations')
        return menuItemsFilteredByRole.map(menuItem => {
          return {
            ...menuItem,
            unreadLoaded: this.$store.getters[
              'conversationStats/getUnreadLoadedByKey'
            ](menuItem.key),
            unreadMeta: this.$store.getters[
              'conversationStats/getUnreadStatsByKey'
            ](menuItem.key),
          };
        });
      return menuItemsFilteredByRole;
    },
    inboxSection() {
      return {
        icon: 'folder',
        label: 'INBOXES',
        hasSubMenu: true,
        newLink: this.showNewLink(FEATURE_FLAGS.INBOX_MANAGEMENT),
        newLinkTag: 'NEW_INBOX',
        key: 'inbox',
        toState: frontendURL(`accounts/${this.accountId}/settings/inboxes/new`),
        toStateName: 'settings_inbox_new',
        newLinkRouteName: 'settings_inbox_new',
        children: this.inboxes
          .map(inbox => ({
            id: inbox.id,
            label: inbox.name,
            truncateLabel: true,
            toState: frontendURL(
              `accounts/${this.accountId}/inbox/${inbox.id}`
            ),
            type: inbox.channel_type,
            phoneNumber: inbox.phone_number,
            reauthorizationRequired: inbox.reauthorization_required,
            unreadLoaded: this.$store.getters[
              'conversationStats/getUnreadLoadedByKey'
            ](inbox.id),
            unreadMeta: this.$store.getters[
              'conversationStats/getUnreadStatsByKey'
            ](inbox.id),
          }))
          .sort((a, b) =>
            a.label.toLowerCase() > b.label.toLowerCase() ? 1 : -1
          ),
      };
    },
    labelSection() {
      return {
        icon: 'number-symbol',
        label: 'LABELS',
        hasSubMenu: true,
        newLink: this.showNewLink(FEATURE_FLAGS.TEAM_MANAGEMENT),
        newLinkTag: 'NEW_LABEL',
        key: 'label',
        toState: frontendURL(`accounts/${this.accountId}/settings/labels`),
        toStateName: 'labels_list',
        showModalForNewItem: true,
        modalName: 'AddLabel',
        dataTestid: 'sidebar-new-label-button',
        children: this.labels.map(label => ({
          id: label.id,
          label: label.title,
          color: label.color,
          truncateLabel: true,
          toState: frontendURL(
            `accounts/${this.accountId}/label/${label.title}`
          ),
        })),
      };
    },
    contactLabelSection() {
      return {
        icon: 'number-symbol',
        label: 'TAGGED_WITH',
        hasSubMenu: true,
        key: 'label',
        newLink: this.showNewLink(FEATURE_FLAGS.TEAM_MANAGEMENT),
        newLinkTag: 'NEW_LABEL',
        toState: frontendURL(`accounts/${this.accountId}/settings/labels`),
        toStateName: 'labels_list',
        showModalForNewItem: true,
        modalName: 'AddLabel',
        children: this.labels.map(label => ({
          id: label.id,
          label: label.description || label.title,
          color: label.color,
          truncateLabel: true,
          toState: frontendURL(
            `accounts/${this.accountId}/labels/${label.title}/contacts`
          ),
        })),
      };
    },
    teamSection() {
      return {
        icon: 'people-team',
        label: 'TEAMS',
        hasSubMenu: true,
        newLink: this.showNewLink(FEATURE_FLAGS.TEAM_MANAGEMENT),
        newLinkTag: 'NEW_TEAM',
        key: 'team',
        toState: frontendURL(`accounts/${this.accountId}/settings/teams/new`),
        toStateName: 'settings_teams_new',
        newLinkRouteName: 'settings_teams_new',
        children: this.teams.map(team => ({
          id: team.id,
          label: team.name,
          truncateLabel: true,
          toState: frontendURL(`accounts/${this.accountId}/team/${team.id}`),
        })),
      };
    },
    statusSection() {
      return {
        icon: 'people-team',
        label: 'STATUSES',
        hasSubMenu: true,
        key: 'status',
        children: this.conversationStatuses.map(status => ({
          id: status.id,
          label: status.name,
          truncateLabel: true,
          icon: status.icon,
          toState: frontendURL(
            `accounts/${this.accountId}/${status.id}/conversations`
          ),
          unreadLoaded: this.$store.getters[
            'conversationStats/getUnreadLoadedByKey'
          ](status.id),
          unreadMeta: this.$store.getters[
            'conversationStats/getUnreadStatsByKey'
          ](status.id),
        })),
      };
    },
    foldersSection() {
      return {
        icon: 'folder',
        label: 'CUSTOM_VIEWS_FOLDER',
        hasSubMenu: true,
        key: 'custom_view',
        children: this.customViews
          .filter(view => view.filter_type === 'conversation')
          .map(view => ({
            id: view.id,
            label: view.name,
            truncateLabel: true,
            toState: frontendURL(
              `accounts/${this.accountId}/custom_view/${view.id}`
            ),
          })),
      };
    },
    contactGlobalSegmentsSection() {
      return {
        icon: 'folder',
        label: 'CUSTOM_VIEWS_GLOBAL_SEGMENTS',
        hasSubMenu: true,
        key: 'global_custom_view',
        children: this.contactCustomGlobalViews.map(view => ({
          id: view.id,
          label: view.name,
          truncateLabel: true,
          toState: frontendURL(
            `accounts/${this.accountId}/contacts/custom_view/${view.id}`
          ),
        })),
      };
    },
    contactSegmentsSection() {
      return {
        icon: 'folder',
        label: 'CUSTOM_VIEWS_SEGMENTS',
        hasSubMenu: true,
        key: 'custom_view',
        children: this.contactCustomViews.map(view => ({
          id: view.id,
          label: view.name,
          truncateLabel: true,
          toState: frontendURL(
            `accounts/${this.accountId}/contacts/custom_view/${view.id}`
          ),
        })),
      };
    },
    additionalSecondaryMenuItems() {
      let conversationMenuItems = [
        this.statusSection,
        this.inboxSection,
        this.labelSection,
      ];
      let contactMenuItems = [this.contactLabelSection];
      if (this.teams.length) {
        conversationMenuItems = [this.teamSection, ...conversationMenuItems];
      }
      if (this.customViews.length) {
        conversationMenuItems = [this.foldersSection, ...conversationMenuItems];
      }
      if (this.contactCustomGlobalViews.length) {
        contactMenuItems = [
          this.contactGlobalSegmentsSection,
          ...contactMenuItems,
        ];
      }
      if (this.contactCustomViews.length) {
        contactMenuItems = [this.contactSegmentsSection, ...contactMenuItems];
      }
      return {
        conversations: conversationMenuItems,
        contacts: contactMenuItems,
      };
    },
  },
  methods: {
    showAddLabelPopup() {
      this.$emit('add-label');
    },
    toggleAccountModal() {
      this.$emit('toggle-accounts');
    },
    showNewLink(featureFlag) {
      return this.isFeatureEnabledonAccount(this.accountId, featureFlag);
    },
  },
};
</script>
