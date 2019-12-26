<template>
  <aside class="sidebar animated shrink columns">
    <div class="logo">
      <router-link :to="dashboardPath" replace>
        <img src="~dashboard/assets/images/woot-logo.svg" alt="Woot-logo" />
      </router-link>
    </div>

    <div class="main-nav">
      <transition-group name="menu-list" tag="ul" class="menu vertical">
        <sidebar-item
          v-for="item in accessibleMenuItems"
          :key="item.toState"
          :menu-item="item"
        />

        <sidebar-item
          v-if="shouldShowInboxes"
          :key="inboxSection.toState"
          :menu-item="inboxSection"
        />
      </transition-group>
    </div>

    <!-- this block is only required in the hosted version with billing enabled -->
    <transition name="fade" mode="out-in">
      <woot-status-bar
        v-if="shouldShowStatusBox"
        :message="trialMessage"
        :button-text="$t('APP_GLOBAL.TRAIL_BUTTON')"
        :button-route="{ name: 'billing' }"
        :type="statusBarClass"
        :show-button="isAdmin()"
      />
    </transition>

    <div class="bottom-nav">
      <transition name="menu-slide">
        <div
          v-if="showOptionsMenu"
          v-on-clickaway="showOptions"
          class="dropdown-pane top"
        >
          <ul class="vertical dropdown menu">
            <li><a href="#" @click.prevent="logout()">Logout</a></li>
          </ul>
        </div>
      </transition>
      <div class="current-user" @click.prevent="showOptions()">
        <thumbnail :src="gravatarUrl()" :username="currentUser.name" />
        <div class="current-user--data">
          <h3 class="current-user--name">
            {{ currentUser.name }}
          </h3>
          <h5 class="current-user--role">
            {{ currentUser.role }}
          </h5>
        </div>
        <span class="current-user--options icon ion-android-more-vertical">
        </span>
      </div>
    </div>
  </aside>
</template>

<script>
import { mapGetters } from 'vuex';
import md5 from 'md5';
import { mixin as clickaway } from 'vue-clickaway';

import adminMixin from '../../mixins/isAdmin';
import Auth from '../../api/auth';
import SidebarItem from './SidebarItem';
import WootStatusBar from '../widgets/StatusBar';
import { frontendURL } from '../../helper/URLHelper';
import Thumbnail from '../widgets/Thumbnail';
import sidemenuItems from '../../i18n/default-sidebar';

export default {
  components: {
    SidebarItem,
    WootStatusBar,
    Thumbnail,
  },
  mixins: [clickaway, adminMixin],
  props: {
    route: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      showOptionsMenu: false,
    };
  },
  computed: {
    ...mapGetters({
      daysLeft: 'getTrialLeft',
      subscriptionData: 'getSubscription',
      inboxes: 'inboxes/getInboxes',
    }),
    accessibleMenuItems() {
      // get all keys in menuGroup
      const groupKey = Object.keys(sidemenuItems);

      let menuItems = [];
      // Iterate over menuGroup to find the correct group
      for (let i = 0; i < groupKey.length; i += 1) {
        const groupItem = sidemenuItems[groupKey[i]];
        // Check if current route is included
        const isRouteIncluded = groupItem.routes.includes(this.currentRoute);
        if (isRouteIncluded) {
          menuItems = Object.values(groupItem.menuItems);
        }
      }

      if (!window.chatwootConfig.billingEnabled) {
        menuItems = this.filterBillingRoutes(menuItems);
      }

      return this.filterMenuItemsByRole(menuItems);
    },
    currentRoute() {
      return this.$store.state.route.name;
    },
    shouldShowInboxes() {
      return sidemenuItems.common.routes.includes(this.currentRoute);
    },
    inboxSection() {
      return {
        icon: 'ion-folder',
        label: 'Inboxes',
        hasSubMenu: true,
        newLink: true,
        key: 'inbox',
        cssClass: 'menu-title align-justify',
        toState: frontendURL('settings/inboxes'),
        toStateName: 'settings_inbox_list',
        children: this.inboxes.map(inbox => ({
          id: inbox.id,
          label: inbox.name,
          toState: frontendURL(`inbox/${inbox.id}`),
        })),
      };
    },
    currentUser() {
      return Auth.getCurrentUser();
    },
    dashboardPath() {
      return frontendURL('dashboard');
    },
    shouldShowStatusBox() {
      return (
        window.chatwootConfig.billingEnabled &&
        (this.subscriptionData.state === 'trial' ||
          this.subscriptionData.state === 'cancelled')
      );
    },
    statusBarClass() {
      if (this.subscriptionData.state === 'trial') {
        return 'warning';
      }
      if (this.subscriptionData.state === 'cancelled') {
        return 'danger';
      }
      return '';
    },
    trialMessage() {
      return `${this.daysLeft} ${this.$t('APP_GLOBAL.TRIAL_MESSAGE')}`;
    },
  },
  mounted() {
    this.$store.dispatch('inboxes/get');
  },
  methods: {
    gravatarUrl() {
      const hash = md5(this.currentUser.email);
      return `${window.WootConstants.GRAVATAR_URL}${hash}?default=404`;
    },
    filterBillingRoutes(menuItems) {
      return menuItems.filter(
        menuItem => !menuItem.toState.includes('billing')
      );
    },
    filterMenuItemsByRole(menuItems) {
      const { role } = this.currentUser;
      return menuItems.filter(
        menuItem =>
          window.roleWiseRoutes[role].indexOf(menuItem.toStateName) > -1
      );
    },
    logout() {
      Auth.logout();
    },
    showOptions() {
      this.showOptionsMenu = !this.showOptionsMenu;
    },
  },
};
</script>
