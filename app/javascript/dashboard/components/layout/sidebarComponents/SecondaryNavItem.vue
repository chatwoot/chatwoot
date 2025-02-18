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
        v-if="!(menuItem.label === 'BOT_ANALYTICS')"
        :icon="menuItem.icon"
        class="min-w-[1rem] mr-1.5 rtl:mr-0 rtl:ml-1.5"
        size="14"
      />
      <svg
        v-if="menuItem.label === 'BOT_ANALYTICS'"
        class="max-w-[1rem] mr-1.5 rtl:mr-0 rtl:ml-1.5"
        width="20"
        height="20"
        viewBox="0 0 20 20"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <g clip-path="url(#clip0_1769_4268)">
          <path
            d="M15.625 4.375H4.375C3.33947 4.375 2.5 5.21447 2.5 6.25V15C2.5 16.0355 3.33947 16.875 4.375 16.875H15.625C16.6605 16.875 17.5 16.0355 17.5 15V6.25C17.5 5.21447 16.6605 4.375 15.625 4.375Z"
            stroke="currentColor"
            stroke-width="1.3"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M12.8125 11.25H7.1875C6.32456 11.25 5.625 11.9496 5.625 12.8125C5.625 13.6754 6.32456 14.375 7.1875 14.375H12.8125C13.6754 14.375 14.375 13.6754 14.375 12.8125C14.375 11.9496 13.6754 11.25 12.8125 11.25Z"
            stroke="currentColor"
            stroke-width="1.3"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M10 4.375V1.25"
            stroke="currentColor"
            stroke-width="1.3"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M6.5625 9.375C7.08027 9.375 7.5 8.95527 7.5 8.4375C7.5 7.91973 7.08027 7.5 6.5625 7.5C6.04473 7.5 5.625 7.91973 5.625 8.4375C5.625 8.95527 6.04473 9.375 6.5625 9.375Z"
            fill="currentColor"
          />
          <path
            d="M13.4375 9.375C13.9553 9.375 14.375 8.95527 14.375 8.4375C14.375 7.91973 13.9553 7.5 13.4375 7.5C12.9197 7.5 12.5 7.91973 12.5 8.4375C12.5 8.95527 12.9197 9.375 13.4375 9.375Z"
            fill="currentColor"
          />
        </g>
        <defs>
          <clipPath id="clip0_1769_4268">
            <rect width="20" height="20" fill="white" />
          </clipPath>
        </defs>
      </svg>

      {{
        menuItem.label === 'BOT_ANALYTICS'
          ? 'Whatsapp Chatbot'
          : menuItem.label === 'CALLING_NUDGES'
          ? 'Calling Nudges'
          : menuItem.label === 'MISSED_CALLS'
          ? 'Missed Calls'
          : menuItem.label === 'CALL_ANALYTICS'
          ? 'Call Analytics'
          : menuItem.label === 'CALLING_SETTINGS'
          ? 'Calling'
          : $t(`SIDEBAR.${menuItem.label}`)
      }}
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
      <router-link
        v-if="showItem(menuItem)"
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
    </ul>
  </li>
</template>

<script>
import { mapGetters } from 'vuex';

import adminMixin from '../../../mixins/isAdmin';
import configMixin from 'shared/mixins/configMixin';
import {
  getInboxClassByType,
  getInboxWarningIconClass,
} from 'dashboard/helper/inbox';

import SecondaryChildNavItem from './SecondaryChildNavItem.vue';
import {
  isOnMentionsView,
  isOnUnattendedView,
  isOnCallingNudgesView,
  isOnMissedCallsView,
} from '../../../store/modules/conversations/helpers/actionHelpers';

export default {
  components: { SecondaryChildNavItem },
  mixins: [adminMixin, configMixin],
  props: {
    menuItem: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    ...mapGetters({
      activeInbox: 'getSelectedInbox',
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      globalConfig: 'globalConfig/get',
      getAccount: 'accounts/getAccount',
    }),
    currentAccount() {
      return this.getAccount(this.accountId) || {};
    },
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
    isCallingNudges() {
      return (
        isOnCallingNudgesView({ route: this.$route }) &&
        this.menuItem.toStateName === 'conversation_calling_nudges'
      );
    },
    isMissedCalls() {
      return (
        isOnMissedCallsView({ route: this.$route }) &&
        this.menuItem.toStateName === 'conversation_missed_calls'
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
        this.isCallingNudges ||
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
      if (
        this.currentAccount?.custom_attributes?.show_label_to_agent &&
        !!item.newLink
      ) {
        return true;
      }
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
