<template>
  <router-link
    :to="menuItem.toState"
    tag="li"
    active-class="active"
    :class="computedClass"
  >
    <a
      :class="getMenuItemClass"
      data-tooltip
      aria-haspopup="true"
      :title="menuItem.toolTip"
    >
      <i :class="menuItem.icon" />
      {{ menuItem.label }}
      <span
        v-if="showItem(menuItem)"
        class="ion-ios-plus-outline"
        @click.prevent="newLinkClick"
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
        <a href="#">
          <i
            v-if="computedInboxClass(child)"
            class="inbox-icon"
            :class="computedInboxClass(child)"
          ></i>
          {{ child.label }}
        </a>
      </router-link>
    </ul>
  </router-link>
</template>

<script>
/* eslint no-console: 0 */
import { mapGetters } from 'vuex';

import router from '../../routes';
import auth from '../../api/auth';

const INBOX_TYPES = {
  WEB: 'Channel::WebWidget',
  FB: 'Channel::FacebookPage',
  TWITTER: 'Channel::TwitterProfile',
};
const getInboxClassByType = type => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'ion-earth';

    case INBOX_TYPES.FB:
      return 'ion-social-facebook';

    case INBOX_TYPES.TWITTER:
      return 'ion-social-twitter';

    default:
      return '';
  }
};

export default {
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
      const { type } = child;
      const classByType = getInboxClassByType(type);
      return classByType;
    },
    newLinkClick() {
      router.push({ name: 'settings_inbox_new', params: { page: 'new' } });
    },
    showItem(item) {
      return auth.isAdmin() && item.newLink !== undefined;
    },
  },
};
</script>
