<template>
  <aside class="sidebar animated shrink columns">
    <div class="logo">
      <router-link :to="dashboardPath" replace>
        <img src="~assets/images/woot-logo.svg" alt="Woot-logo" />
      </router-link>
    </div>

    <div class="main-nav">
      <transition-group name="menu-list" tag="ul" class="menu vertical">
        <sidebar-item
          v-for="item in accessibleMenuItems"
          :key="item.toState"
          :menu-item="item"
        />
      </transition-group>
    </div>
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
            <!-- <li><a href="#">Help & Support</a></li> -->
            <li><a href="#" @click.prevent="logout()">Logout</a></li>
          </ul>
        </div>
      </transition>
      <div class="current-user" @click.prevent="showOptions()">
        <img class="current-user--thumbnail" :src="gravatarUrl()" />
        <div class="current-user--data">
          <h3 class="current-user--name">
            {{ currentUser.name }}
          </h3>
          <h5 class="current-user--role">
            {{ currentUser.role }}
          </h5>
        </div>
        <span
          class="current-user--options icon ion-android-more-vertical"
        ></span>
      </div>
      <!-- <router-link class="icon ion-arrow-graph-up-right" tag="span" to="/settings/reports" active-class="active"></router-link> -->
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

export default {
  mixins: [clickaway, adminMixin],
  props: {
    route: {
      type: String,
    },
  },
  data() {
    return {
      showOptionsMenu: false,
    };
  },
  mounted() {
    // this.$store.dispatch('fetchLabels');
    this.$store.dispatch('fetchInboxes');
  },
  computed: {
    ...mapGetters({
      sidebarList: 'getMenuItems',
      daysLeft: 'getTrialLeft',
      subscriptionData: 'getSubscription',
    }),
    accessibleMenuItems() {
      const currentRoute = this.$store.state.route.name;
      // get all keys in menuGroup
      const groupKey = Object.keys(this.sidebarList);

      let menuItems = [];
      // Iterate over menuGroup to find the correct group
      for (let i = 0; i < groupKey.length; i += 1) {
        const groupItem = this.sidebarList[groupKey[i]];
        // Check if current route is included
        const isRouteIncluded = groupItem.routes.indexOf(currentRoute) > -1;
        if (isRouteIncluded) {
          menuItems = Object.values(groupItem.menuItems);
        }
      }

      const { role } = this.currentUser;
      return menuItems.filter(
        menuItem =>
          window.roleWiseRoutes[role].indexOf(menuItem.toStateName) > -1
      );
    },
    dashboardPath() {
      return frontendURL('dashboard');
    },
    currentUser() {
      return Auth.getCurrentUser();
    },
    trialMessage() {
      return `${this.daysLeft} ${this.$t('APP_GLOBAL.TRIAL_MESSAGE')}`;
    },
    shouldShowStatusBox() {
      return (
        this.subscriptionData.state === 'trial' ||
        this.subscriptionData.state === 'cancelled'
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
  },

  methods: {
    logout() {
      Auth.logout();
    },
    gravatarUrl() {
      const hash = md5(this.currentUser.email);
      return `${window.WootConstants.GRAVATAR_URL}${hash}?d=monsterid`;
    },
    showOptions() {
      this.showOptionsMenu = !this.showOptionsMenu;
    },
  },

  components: {
    SidebarItem,
    WootStatusBar,
  },
};
</script>
