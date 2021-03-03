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
import adminMixin from '../../mixins/isAdmin';
import { INBOX_TYPES } from 'shared/mixins/inboxMixin';

const getInboxClassByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'ion-earth';

    case INBOX_TYPES.FB:
      return 'ion-social-facebook';

    case INBOX_TYPES.TWITTER:
      return 'ion-social-twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber.startsWith('whatsapp')
        ? 'ion-social-whatsapp-outline'
        : 'ion-android-textsms';

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
}

.label-color--display {
  border-radius: $space-smaller;
  height: $space-normal;
  margin-right: $space-small;
  min-width: $space-normal;
  width: $space-normal;
}

.inbox-icon.ion-social-facebook {
	color: var(--color-facebook-brand);
}

.inbox-icon.ion-social-whatsapp-outline {
	color: var(--color-twitter-brand);
}

.inbox-icon.ion-social-twitter {
	color: var(--color-twitter-brand);
}

.inbox-icon.ion-android-textsms {
	color: var(--color-sms-twilio);
}

.inbox-icon.ion-earth {
	color: var(--color-woot);
}

.inbox-icon.ion-cloud {
	color: var(--color-cloud-generic);
}
</style>
