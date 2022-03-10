<template>
  <li class="sidebar-item">
    <span v-if="hasSubMenu" class="secondary-menu--title fs-small">
      {{ $t(`SIDEBAR.${menuItem.label}`) }}
    </span>
    <router-link
      v-else
      class="secondary-menu--title secondary-menu--link fs-small"
      :class="computedClass"
      :to="menuItem && menuItem.toState"
    >
      <fluent-icon
        :icon="menuItem.icon"
        class="secondary-menu--icon"
        size="14"
      />
      {{ $t(`SIDEBAR.${menuItem.label}`) }}
      <span
        v-if="menuItem.label === 'AUTOMATION'"
        data-view-component="true"
        label="Beta"
        class="beta"
      >
        {{ $t('SIDEBAR.BETA') }}
      </span>
    </router-link>

    <ul v-if="hasSubMenu" class="nested vertical menu">
      <secondary-child-nav-item
        v-for="child in menuItem.children"
        :key="child.id"
        :to="child.toState"
        :label="child.label"
        :label-color="child.color"
        :should-truncate="child.truncateLabel"
        :icon="computedInboxClass(child)"
      />
      <router-link
        v-if="showItem(menuItem)"
        v-slot="{ href, isActive, navigate }"
        :to="menuItem.toState"
        custom
      >
        <li>
          <a
            :href="href"
            class="button small clear menu-item--new secondary"
            :class="{ 'is-active': isActive }"
            @click="e => newLinkClick(e, navigate)"
          >
            <fluent-icon icon="add" size="16" />
            <span class="button__content">
              {{ $t(`SIDEBAR.${menuItem.newLinkTag}`) }}
            </span>
          </a>
        </li>
      </router-link>
    </ul>
  </li>
</template>

<script>
import { mapGetters } from 'vuex';

import adminMixin from '../../../mixins/isAdmin';
import { getInboxClassByType } from 'dashboard/helper/inbox';

import SecondaryChildNavItem from './SecondaryChildNavItem';

export default {
  components: { SecondaryChildNavItem },
  mixins: [adminMixin],
  props: {
    menuItem: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    ...mapGetters({ activeInbox: 'getSelectedInbox' }),
    hasSubMenu() {
      return !!this.menuItem.children;
    },
    isInboxConversation() {
      return (
        this.$store.state.route.name === 'inbox_conversation' &&
        this.menuItem.toStateName === 'home'
      );
    },
    isTeamsSettings() {
      return (
        this.$store.state.route.name === 'settings_teams_edit' &&
        this.menuItem.toStateName === 'settings_teams_list'
      );
    },
    isInboxsSettings() {
      return (
        this.$store.state.route.name === 'settings_inbox_show' &&
        this.menuItem.toStateName === 'settings_inbox_list'
      );
    },
    isIntegrationsSettings() {
      return (
        this.$store.state.route.name === 'settings_integrations_webhook' &&
        this.menuItem.toStateName === 'settings_integrations'
      );
    },
    isApplicationsSettings() {
      return (
        this.$store.state.route.name === 'settings_applications_integration' &&
        this.menuItem.toStateName === 'settings_applications'
      );
    },

    computedClass() {
      // If active Inbox is present
      // donot highlight conversations
      if (this.activeInbox) return ' ';

      if (
        this.isInboxConversation ||
        this.isTeamsSettings ||
        this.isInboxsSettings ||
        this.isIntegrationsSettings ||
        this.isApplicationsSettings
      ) {
        return 'is-active';
      }
      return ' ';
    },
  },
  methods: {
    computedInboxClass(child) {
      const { type, phoneNumber } = child;
      if (!type) return '';
      const classByType = getInboxClassByType(type, phoneNumber);
      return classByType;
    },
    newLinkClick(e, navigate) {
      if (this.menuItem.newLinkRouteName) {
        navigate(e);
      } else if (this.menuItem.showModalForNewItem) {
        if (this.menuItem.modalName === 'AddLabel') {
          e.preventDefault();
          this.$emit('add-label');
        }
      }
    },
    showItem(item) {
      return this.isAdmin && item.newLink !== undefined;
    },
  },
};
</script>
<style lang="scss" scoped>
.sidebar-item {
  margin: var(--space-smaller) 0 0;
}

.secondary-menu--title {
  color: var(--s-600);
  display: flex;
  font-weight: var(--font-weight-bold);
  line-height: var(--space-two);
  margin: var(--space-small) 0;
  padding: 0 var(--space-small);
}

.secondary-menu--link {
  display: flex;
  align-items: center;
  margin: 0;
  padding: var(--space-small);
  font-weight: var(--font-weight-medium);
  border-radius: var(--border-radius-normal);

  &:hover {
    background: var(--s-25);
    color: var(--s-600);
  }

  &:focus {
    border-color: var(--w-300);
  }

  &.router-link-exact-active,
  &.is-active {
    background: var(--w-25);
    color: var(--w-500);
    border-color: var(--w-25);
  }
}

.secondary-menu--icon {
  margin-right: var(--space-smaller);
  min-width: var(--space-normal);
}

.sub-menu-link {
  color: var(--s-600);
}

.wrap {
  display: flex;
  align-items: center;
}

.label-color--display {
  border-radius: var(--space-smaller);
  height: var(--space-normal);
  margin-right: var(--space-small);
  min-width: var(--space-normal);
  width: var(--space-normal);
}

.inbox-icon {
  position: relative;
  top: -1px;
}

.sidebar-item .button.menu-item--new {
  display: inline-flex;
  height: var(--space-medium);
  margin: var(--space-smaller) 0;
  padding: var(--space-smaller);
  color: var(--s-500);

  &:hover {
    color: var(--w-500);
  }
}
.beta {
  padding-right: var(--space-smaller) !important;
  padding-left: var(--space-smaller) !important;
  margin-left: var(--space-half) !important;
  display: inline-block;
  font-size: var(--font-size-micro);
  font-weight: var(--font-weight-medium);
  line-height: 18px;
  border: 1px solid transparent;
  border-radius: 2em;
  color: var(--g-800);
  border-color: var(--g-700);
}
</style>
