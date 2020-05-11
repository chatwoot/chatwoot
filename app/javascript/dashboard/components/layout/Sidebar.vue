<template>
  <aside class="sidebar animated shrink columns">
    <div class="logo">
      <router-link :to="dashboardPath" replace>
        <img :src="globalConfig.logo" :alt="globalConfig.installationName" />
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
            <li>
              <router-link :to="`/app/accounts/${accountId}/profile/settings`">
                {{ $t('SIDEBAR_ITEMS.PROFILE_SETTINGS') }}
              </router-link>
            </li>
            <li>
              <a href="#" @click.prevent="logout()">
                {{ $t('SIDEBAR_ITEMS.LOGOUT') }}
              </a>
            </li>
          </ul>
        </div>
      </transition>
      <div class="current-user" @click.prevent="showOptions()">
        <thumbnail :src="currentUser.avatar_url" :username="currentUser.name" />
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
      currentUser: 'getCurrentUser',
      daysLeft: 'getTrialLeft',
      globalConfig: 'globalConfig/get',
      inboxes: 'inboxes/getInboxes',
      subscriptionData: 'getSubscription',
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
        label: 'INBOXES',
        hasSubMenu: true,
        newLink: true,
        key: 'inbox',
        cssClass: 'menu-title align-justify',
        toState: frontendURL(`accounts/${this.accountId}/settings/inboxes`),
        toStateName: 'settings_inbox_list',
        children: this.inboxes.map(inbox => ({
          id: inbox.id,
          label: inbox.name,
          toState: frontendURL(`accounts/${this.accountId}/inbox/${inbox.id}`),
          type: inbox.channel_type,
        })),
      };
    },
    dashboardPath() {
      return frontendURL(`accounts/${this.accountId}/dashboard`);
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
    accountId() {
      return this.currentUser.account_id;
    },
  },
  mounted() {
    this.$store.dispatch('inboxes/get');
  },
  methods: {
    filterBillingRoutes(menuItems) {
      return menuItems.filter(
        menuItem => !menuItem.toState.includes('billing')
      );
    },
    filterMenuItemsByRole(menuItems) {
      const { role } = this.currentUser;
      if (!role) {
        return [];
      }
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
