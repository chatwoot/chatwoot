<template>
  <div v-if="hasSecondaryMenu" class="main-nav secondary-menu">
    <account-context />
    <transition-group name="menu-list" tag="ul" class="menu vertical">
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
  },
  computed: {
    hasSecondaryMenu() {
      return this.menuConfig.menuItems && this.menuConfig.menuItems.length;
    },
    contactCustomViews() {
      return this.customViews.filter(view => view.filter_type === 'contact');
    },
    accessibleMenuItems() {
      if (!this.currentRole) {
        return [];
      }
      return this.menuConfig.menuItems.filter(
        menuItem =>
          window.roleWiseRoutes[this.currentRole].indexOf(
            menuItem.toStateName
          ) > -1
      );
    },
    inboxSection() {
      return {
        icon: 'folder',
        label: 'INBOXES',
        hasSubMenu: true,
        newLink: true,
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
        newLink: true,
        newLinkTag: 'NEW_LABEL',
        key: 'label',
        toState: frontendURL(`accounts/${this.accountId}/settings/labels`),
        toStateName: 'labels_list',
        showModalForNewItem: true,
        modalName: 'AddLabel',
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
        newLink: true,
        newLinkTag: 'NEW_LABEL',
        toState: frontendURL(`accounts/${this.accountId}/settings/labels`),
        toStateName: 'labels_list',
        showModalForNewItem: true,
        modalName: 'AddLabel',
        children: this.labels.map(label => ({
          id: label.id,
          label: label.title,
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
        newLink: true,
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
    contactSegmentsSection() {
      return {
        icon: 'folder',
        label: 'CUSTOM_VIEWS_SEGMENTS',
        hasSubMenu: true,
        key: 'custom_view',
        children: this.customViews
          .filter(view => view.filter_type === 'contact')
          .map(view => ({
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
      let conversationMenuItems = [this.inboxSection, this.labelSection];
      let contactMenuItems = [this.contactLabelSection];
      if (this.teams.length) {
        conversationMenuItems = [this.teamSection, ...conversationMenuItems];
      }
      if (this.customViews.length) {
        conversationMenuItems = [this.foldersSection, ...conversationMenuItems];
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
  },
};
</script>
<style lang="scss" scoped>
.secondary-menu {
  background: var(--white);
  border-right: 1px solid var(--s-50);
  height: 100%;
  width: 19rem;
  flex-shrink: 0;
  overflow: hidden;
  padding: var(--space-small);

  &:hover {
    overflow: auto;
  }
}
</style>
