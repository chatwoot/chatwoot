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
  emits: [
    'close',
    'openKeyShortcutModal',
    'toggleAccounts',
    'showSupportChatWindow',
  ],
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
      this.$emit('openKeyShortcutModal');
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

<template>
  <transition name="menu-slide">
    <div
      v-if="show"
      v-on-clickaway="onClickAway"
      class="absolute z-30 w-64 px-2 py-2 bg-white border rounded-md shadow-xl left-3 rtl:left-auto rtl:right-3 bottom-16 dark:bg-slate-800 border-slate-25 dark:border-slate-700"
      :class="{ 'block visible': show }"
    >
      <AvailabilityStatus />
      <WootDropdownMenu>
        <WootDropdownItem v-if="showChangeAccountOption">
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="arrow-swap"
            @click="$emit('toggleAccounts')"
          >
            {{ $t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS') }}
          </woot-button>
        </WootDropdownItem>
        <WootDropdownItem v-if="globalConfig.chatwootInboxToken">
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="chat-help"
            @click="$emit('showSupportChatWindow')"
          >
            {{ $t('SIDEBAR_ITEMS.CONTACT_SUPPORT') }}
          </woot-button>
        </WootDropdownItem>
        <WootDropdownItem>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="keyboard"
            @click="handleKeyboardHelpClick"
          >
            {{ $t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS') }}
          </woot-button>
        </WootDropdownItem>
        <WootDropdownItem>
          <router-link
            v-slot="{ href, isActive, navigate }"
            :to="`/app/accounts/${accountId}/profile/settings`"
            custom
          >
            <a
              :href="href"
              class="h-8 bg-white button small clear secondary dark:bg-slate-800"
              :class="{ 'is-active': isActive }"
              @click="e => handleProfileSettingClick(e, navigate)"
            >
              <fluent-icon icon="person" size="14" class="icon icon--font" />
              <span class="button__content">
                {{ $t('SIDEBAR_ITEMS.PROFILE_SETTINGS') }}
              </span>
            </a>
          </router-link>
        </WootDropdownItem>
        <WootDropdownItem>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="appearance"
            @click="openAppearanceOptions"
          >
            {{ $t('SIDEBAR_ITEMS.APPEARANCE') }}
          </woot-button>
        </WootDropdownItem>
        <WootDropdownItem v-if="currentUser.type === 'SuperAdmin'">
          <a
            href="/super_admin"
            class="h-8 bg-white button small clear secondary dark:bg-slate-800"
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
        </WootDropdownItem>
        <WootDropdownItem>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="power"
            @click="logout"
          >
            {{ $t('SIDEBAR_ITEMS.LOGOUT') }}
          </woot-button>
        </WootDropdownItem>
      </WootDropdownMenu>
    </div>
  </transition>
</template>
