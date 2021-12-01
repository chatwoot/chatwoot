<template>
  <li :class="computedClass" class="sidebar-item">
    <a
      class="sub-menu-title"
      :class="getMenuItemClass"
      data-tooltip
      aria-haspopup="true"
      :title="menuItem.toolTip"
    >
      {{ $t(`SIDEBAR.${menuItem.label}`) }}
    </a>
    <ul v-if="menuItem.hasSubMenu" class="nested vertical menu">
      <secondary-nav-item
        v-for="child in menuItem.children"
        :key="child.id"
        :to="child.toState"
        :label="child.label"
        :label-color="child.color"
        :should-truncate="child.truncateLabel"
        :icon="computedInboxClass(child)"
      />
      <router-link
        v-if="menuItem.newLink"
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
            <fluent-icon icon="add" />
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

import adminMixin from '../../mixins/isAdmin';
import { getInboxClassByType } from 'dashboard/helper/inbox';

import SecondaryNavItem from 'dashboard/modules/sidebar/components/SecondaryNavItem';

export default {
  components: { SecondaryNavItem },
  mixins: [adminMixin],
  props: {
    menuItem: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    ...mapGetters({ activeInbox: 'getSelectedInbox' }),
    getMenuItemClass() {
      return this.menuItem.cssClass
        ? `side-menu ${this.menuItem.cssClass}`
        : 'side-menu';
    },
    computedClass() {
      // If active Inbox is present
      // donot highlight conversations
      if (this.activeInbox) return ' ';

      if (
        this.$store.state.route.name === 'inbox_conversation' &&
        this.menuItem.toStateName === 'home'
      ) {
        return 'active';
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
    computedChildClass(child) {
      if (!child.truncateLabel) return '';
      return 'text-truncate';
    },
    computedChildTitle(child) {
      if (!child.truncateLabel) return false;
      return child.label;
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
  margin: var(--space-small) 0;
}
.sub-menu-title {
  display: flex;
  justify-content: space-between;
  padding: 0 var(--space-small);
  margin-bottom: var(--space-smaller);
  color: var(--s-600);
  font-weight: var(--font-weight-bold);
  line-height: var(--space-two);
  text-transform: uppercase;
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
</style>
