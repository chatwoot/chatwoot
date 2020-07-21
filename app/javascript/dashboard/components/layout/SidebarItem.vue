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

            {{ child.label }}
          </div>
        </a>
      </router-link>
    </ul>
  </router-link>
</template>

<script>
/* eslint no-console: 0 */
import { mapGetters } from 'vuex';

import router from '../../routes';
import adminMixin from '../../mixins/isAdmin';

const INBOX_TYPES = {
  WEB: 'Channel::WebWidget',
  FB: 'Channel::FacebookPage',
  TWITTER: 'Channel::TwitterProfile',
  TWILIO: 'Channel::TwilioSms',
  API: 'Channel::Api',
  EMAIL: 'Channel::Email',
};
const getInboxClassByType = type => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'ion-earth';

    case INBOX_TYPES.FB:
      return 'ion-social-facebook';

    case INBOX_TYPES.TWITTER:
      return 'ion-social-twitter';

    case INBOX_TYPES.TWILIO:
      return 'ion-android-textsms';

    case INBOX_TYPES.API:
      return 'ion-cloud';

    case INBOX_TYPES.EMAIL:
      return 'ion-email';

    default:
      return '';
  }
};

export default {
  mixins: [adminMixin],
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
  width: $space-normal;
}
</style>
