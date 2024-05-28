<template>
  <transition name="menu-slide">
    <div
      v-if="show"
      v-on-clickaway="onClickAway"
      class="left-3 rtl:left-auto rtl:right-3 bottom-16 w-64 absolute z-30 rounded-md shadow-xl bg-white dark:bg-slate-800 py-2 px-2 border border-slate-25 dark:border-slate-700"
      :class="{ 'block visible': show }"
    >
      <availability-status />
      <woot-dropdown-menu>
        <woot-dropdown-item v-if="showChangeAccountOption">
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="arrow-swap"
            @click="$emit('toggle-accounts')"
          >
            {{ $t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item v-if="globalConfig.chatwootInboxToken">
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="chat-help"
            @click="$emit('show-support-chat-window')"
          >
            {{ $t('SIDEBAR_ITEMS.CONTACT_SUPPORT') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="keyboard"
            @click="handleKeyboardHelpClick"
          >
            {{ $t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <router-link
            v-slot="{ href, isActive, navigate }"
            :to="`/app/accounts/${accountId}/profile/settings`"
            custom
          >
            <a
              :href="href"
              class="button small clear secondary bg-white dark:bg-slate-800 h-8"
              :class="{ 'is-active': isActive }"
              @click="e => handleProfileSettingClick(e, navigate)"
            >
              <fluent-icon icon="person" size="14" class="icon icon--font" />
              <span class="button__content">
                {{ $t('SIDEBAR_ITEMS.PROFILE_SETTINGS') }}
              </span>
            </a>
          </router-link>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="appearance"
            @click="openAppearanceOptions"
          >
            {{ $t('SIDEBAR_ITEMS.APPEARANCE') }}
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item v-if="currentUser.type === 'SuperAdmin'">
          <a
            href="/super_admin"
            class="button small clear secondary bg-white dark:bg-slate-800 h-8"
            target="_blank"
            rel="noopener nofollow noreferrer"
            @click="$emit('close')"
          >
            <fluent-icon
              icon="content-settings"
              size="14"
              class="icon icon--font"
            />
            <span class="button__content">
              {{ $t('SIDEBAR_ITEMS.SUPER_ADMIN_CONSOLE') }}
            </span>
          </a>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="power"
            @click="logout"
          >
            {{ $t('SIDEBAR_ITEMS.LOGOUT') }}
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
  </transition>
</template>

<script>
import { mapGetters } from 'vuex';
import Auth from '../../../api/auth';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import AvailabilityStatus from 'dashboard/components/layout/AvailabilityStatus.vue';

export default {
  components: {
    WootDropdownMenu,
    WootDropdownItem,
    AvailabilityStatus,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      accountId: 'getCurrentAccountId',
    }),
    showChangeAccountOption() {
      if (this.globalConfig.createNewAccountFromDashboard) {
        return true;
      }

      const { accounts = [] } = this.currentUser;
      return accounts.length > 1;
    },
  },
  methods: {
    handleProfileSettingClick(e, navigate) {
      this.$emit('close');
      navigate(e);
    },
    handleKeyboardHelpClick() {
      this.$emit('key-shortcut-modal');
      this.$emit('close');
    },
    logout() {
      Auth.logout();
    },
    onClickAway() {
      if (this.show) this.$emit('close');
    },
    openAppearanceOptions() {
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'appearance_settings' });
    },
  },
};
</script>
