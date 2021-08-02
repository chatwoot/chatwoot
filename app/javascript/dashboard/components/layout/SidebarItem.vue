<template>
  <router-link
    :to="menuItem.toState"
    tag="li"
    active-class="active"
    :class="computedClass"
  >
    <a
      class="sub-menu-title"
      :class="getMenuItemClass"
      data-tooltip
      aria-haspopup="true"
      :title="menuItem.toolTip"
    >
      <div class="wrap">
        <i :class="menuItem.icon" />
        {{ $t(`SIDEBAR.${menuItem.label}`) }}
      </div>
      <span
        v-if="showItem(menuItem)"
        class="child-icon ion-android-add-circle"
        @click.prevent="newLinkClick(menuItem)"
      />
    </a>
    <ul v-if="menuItem.hasSubMenu" class="nested vertical menu">
      <router-link
        v-for="child in menuItem.children"
        :key="child.id"
        active-class="active flex-container"
        tag="li"
        :to="child.toState"
      >
        <a href="#" :class="computedChildClass(child)">
          <div class="wrap">
            <i
              v-if="computedInboxClass(child)"
              class="inbox-icon"
              :class="computedInboxClass(child)"
            />
            <span
              v-if="child.color"
              class="label-color--display"
              :style="{ backgroundColor: child.color }"
            />
            <div
              :title="computedChildTitle(child)"
              :class="computedChildClass(child)"
            >
              {{ child.label }}
            </div>
          </div>
        </a>
      </router-link>
    </ul>
  </router-link>
</template>

<script>
import { mapGetters } from 'vuex';

import router from '../../routes';
import {
  hasPressedAltAndCKey,
  hasPressedAltAndVKey,
  hasPressedAltAndRKey,
  hasPressedAltAndSKey,
} from 'shared/helpers/KeyboardHelpers';
import adminMixin from '../../mixins/isAdmin';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import { getInboxClassByType } from 'dashboard/helper/inbox';
export default {
  mixins: [adminMixin, eventListenerMixins],
  props: {
    menuItem: {
      type: Object,
      default() {
        return {};
      },
    },
  },
  computed: {
    ...mapGetters({
      activeInbox: 'getSelectedInbox',
    }),
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
    newLinkClick(item) {
      if (item.newLinkRouteName) {
        router.push({ name: item.newLinkRouteName, params: { page: 'new' } });
      } else if (item.showModalForNewItem) {
        if (item.modalName === 'AddLabel') {
          this.$emit('add-label');
        }
      }
    },
    handleKeyEvents(e) {
      if (hasPressedAltAndCKey(e)) {
        router.push({ name: 'home' });
      }
      if (hasPressedAltAndVKey(e)) {
        router.push({ name: 'contacts_dashboard' });
      }
      if (hasPressedAltAndRKey(e)) {
        router.push({ name: 'settings_account_reports' });
      }
      if (hasPressedAltAndSKey(e)) {
        router.push({ name: 'settings_home' });
      }
    },
    showItem(item) {
      return this.isAdmin && item.newLink !== undefined;
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';

.sub-menu-title {
  display: flex;
  justify-content: space-between;
}

.wrap {
  display: flex;
  align-items: center;
}

.label-color--display {
  border-radius: $space-smaller;
  height: $space-normal;
  margin-right: $space-small;
  min-width: $space-normal;
  width: $space-normal;
}

.inbox-icon {
  position: relative;
  top: -1px;
  &.ion-ios-email {
    font-size: var(--font-size-medium);
  }
}
</style>
