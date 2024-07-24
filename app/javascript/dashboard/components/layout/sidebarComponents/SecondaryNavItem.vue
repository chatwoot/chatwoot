<template>
  <li v-show="isMenuItemVisible" class="mt-1">
    <div v-if="hasSubMenu" class="flex justify-between">
      <span
        class="px-2 pt-1 my-2 text-sm font-semibold text-slate-700 dark:text-slate-200"
      >
        {{ $t(`SIDEBAR.${menuItem.label}`) }}
      </span>
      <div v-if="menuItem.showNewButton" class="flex items-center">
        <woot-button
          size="tiny"
          variant="clear"
          color-scheme="secondary"
          icon="add"
          class="p-0 ml-2"
          @click="onClickOpen"
        />
      </div>
    </div>
    <router-link
      v-else
      class="flex items-center p-2 m-0 text-sm font-medium leading-4 rounded-lg text-slate-700 dark:text-slate-100 hover:bg-slate-25 dark:hover:bg-slate-800"
      :class="computedClass"
      :to="menuItem && menuItem.toState"
    >
      <fluent-icon
        :icon="menuItem.icon"
        class="min-w-[1rem] mr-1.5 rtl:mr-0 rtl:ml-1.5"
        size="14"
      />
      {{ $t(`SIDEBAR.${menuItem.label}`) }}
      <span
        v-if="showChildCount(menuItem.count)"
        class="px-1 py-0 mx-1 font-medium rounded-md text-xxs"
        :class="{
          'text-slate-300 dark:text-slate-600': isCountZero && !isActiveView,
          'text-slate-600 dark:text-slate-50': !isCountZero && !isActiveView,
          'bg-woot-75 dark:bg-woot-200 text-woot-600 dark:text-woot-600':
            isActiveView,
          'bg-slate-50 dark:bg-slate-700': !isActiveView,
        }"
      >
        {{ `${menuItem.count}` }}
      </span>
      <span
        v-if="menuItem.beta"
        data-view-component="true"
        label="Beta"
        class="inline-block px-1 mx-1 font-medium leading-4 text-green-500 border border-green-400 rounded-lg text-xxs"
      >
        {{ $t('SIDEBAR.BETA') }}
      </span>
    </router-link>

    <ul v-if="hasSubMenu" class="mb-0 ml-0 list-none">
      <secondary-child-nav-item
        v-for="child in menuItem.children"
        :key="child.id"
        :to="child.toState"
        :label="child.label"
        :label-color="child.color"
        :should-truncate="child.truncateLabel"
        :icon="computedInboxClass(child)"
        :warning-icon="computedInboxErrorClass(child)"
        :show-child-count="showChildCount(child.count)"
        :child-item-count="child.count"
      />
      <Policy :permissions="['administrator']">
        <router-link
          v-if="menuItem.newLink"
          v-slot="{ href, navigate }"
          :to="menuItem.toState"
          custom
        >
          <li class="pl-1">
            <a :href="href">
              <woot-button
                size="tiny"
                variant="clear"
                color-scheme="secondary"
                icon="add"
                :data-testid="menuItem.dataTestid"
                @click="e => newLinkClick(e, navigate)"
              >
                {{ $t(`SIDEBAR.${menuItem.newLinkTag}`) }}
              </woot-button>
            </a>
          </li>
        </router-link>
      </Policy>
    </ul>
  </li>
</template>

<script>
import { mapGetters } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';
import configMixin from 'shared/mixins/configMixin';
import {
  getInboxClassByType,
  getInboxWarningIconClass,
} from 'dashboard/helper/inbox';

import SecondaryChildNavItem from './SecondaryChildNavItem.vue';
import {
  isOnMentionsView,
  isOnUnattendedView,
} from '../../../store/modules/conversations/helpers/actionHelpers';
import Policy from '../../policy.vue';

export default {
  components: { SecondaryChildNavItem, Policy },
  mixins: [configMixin],
  props: {
    menuItem: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
  computed: {
    ...mapGetters({
      activeInbox: 'getSelectedInbox',
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      globalConfig: 'globalConfig/get',
    }),
    isCountZero() {
      return this.menuItem.count === 0;
    },
    isActiveView() {
      return this.computedClass.includes('active-view');
    },
    hasSubMenu() {
      return !!this.menuItem.children;
    },
    isMenuItemVisible() {
      if (this.menuItem.globalConfigFlag) {
        // this checks for the `csmlEditorHost` flag in the global config
        // if this is present, we toggle the CSML editor menu item
        // TODO: This is very specific, and can be handled better, fix it
        return !!this.globalConfig[this.menuItem.globalConfigFlag];
      }

      let isFeatureEnabled = true;
      if (this.menuItem.featureFlag) {
        isFeatureEnabled = this.isFeatureEnabledonAccount(
          this.accountId,
          this.menuItem.featureFlag
        );
      }

      if (this.menuItem.isEnterpriseOnly) {
        if (!this.isEnterprise) return false;
        return isFeatureEnabled || this.globalConfig.displayManifest;
      }

      if (this.menuItem.featureFlag) {
        return this.isFeatureEnabledonAccount(
          this.accountId,
          this.menuItem.featureFlag
        );
      }

      return isFeatureEnabled;
    },
    isAllConversations() {
      return (
        this.$store.state.route.name === 'inbox_conversation' &&
        this.menuItem.toStateName === 'home'
      );
    },
    isMentions() {
      return (
        isOnMentionsView({ route: this.$route }) &&
        this.menuItem.toStateName === 'conversation_mentions'
      );
    },
    isUnattended() {
      return (
        isOnUnattendedView({ route: this.$route }) &&
        this.menuItem.toStateName === 'conversation_unattended'
      );
    },
    isTeamsSettings() {
      return (
        this.$store.state.route.name === 'settings_teams_edit' &&
        this.menuItem.toStateName === 'settings_teams_list'
      );
    },
    isInboxSettings() {
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
    isCurrentRoute() {
      return this.$store.state.route.name.includes(this.menuItem.toStateName);
    },

    computedClass() {
      // If active inbox is present, do not highlight conversations
      if (this.activeInbox) return ' ';
      if (
        this.isAllConversations ||
        this.isMentions ||
        this.isUnattended ||
        this.isCurrentRoute
      ) {
        return 'bg-woot-25 dark:bg-slate-800 text-woot-500 dark:text-woot-500 hover:text-woot-500 dark:hover:text-woot-500 active-view';
      }
      if (this.hasSubMenu) {
        if (
          this.isTeamsSettings ||
          this.isInboxSettings ||
          this.isIntegrationsSettings ||
          this.isApplicationsSettings
        ) {
          return 'bg-woot-25 dark:bg-slate-800 text-woot-500 dark:text-woot-500 hover:text-woot-500 dark:hover:text-woot-500 active-view';
        }
        return 'hover:text-slate-700 dark:hover:text-slate-100';
      }

      return 'hover:text-slate-700 dark:hover:text-slate-100';
    },
  },
  methods: {
    computedInboxClass(child) {
      const { type, phoneNumber } = child;
      if (!type) return '';
      const classByType = getInboxClassByType(type, phoneNumber);
      return classByType;
    },
    computedInboxErrorClass(child) {
      const { type, reauthorizationRequired } = child;
      if (!type) return '';
      const warningClass = getInboxWarningIconClass(
        type,
        reauthorizationRequired
      );
      return warningClass;
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
      return this.isAdmin && !!item.newLink;
    },
    onClickOpen() {
      this.$emit('open');
    },
    showChildCount(count) {
      return Number.isInteger(count);
    },
  },
};
</script>
