<script>
import { mapGetters } from 'vuex';
import Auth from '../../../api/auth';
import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import AvailabilityStatus from 'dashboard/components/layout/AvailabilityStatus.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    WootDropdownMenu,
    WootDropdownItem,
    AvailabilityStatus,
    NextButton,
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
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    showChangeAccountOption() {
      if (this.globalConfig.createNewAccountFromDashboard) {
        return true;
      }

      const { accounts = [] } = this.currentUser;
      return accounts.length > 1;
    },
    showChatSupport() {
      return (
        this.isFeatureEnabledonAccount(
          this.accountId,
          FEATURE_FLAGS.CONTACT_CHATWOOT_SUPPORT_TEAM
        ) && this.globalConfig.chatwootInboxToken
      );
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
          <NextButton
            ghost
            sm
            slate
            icon="i-lucide-arrow-right-left"
            class="!w-full !justify-start"
            @click="$emit('toggleAccounts')"
          >
            <span class="min-w-0 truncate font-medium text-xs">
              {{ $t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS') }}
            </span>
          </NextButton>
        </WootDropdownItem>
        <WootDropdownItem v-if="showChatSupport">
          <NextButton
            ghost
            sm
            slate
            icon="i-lucide-message-circle-question"
            class="!w-full !justify-start"
            @click="$emit('showSupportChatWindow')"
          >
            <span class="min-w-0 truncate font-medium text-xs">
              {{ $t('SIDEBAR_ITEMS.CONTACT_SUPPORT') }}
            </span>
          </NextButton>
        </WootDropdownItem>
        <WootDropdownItem>
          <NextButton
            ghost
            sm
            slate
            icon="i-lucide-keyboard"
            class="!w-full !justify-start"
            @click="handleKeyboardHelpClick"
          >
            <span class="min-w-0 truncate font-medium text-xs">
              {{ $t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS') }}
            </span>
          </NextButton>
        </WootDropdownItem>
        <WootDropdownItem>
          <router-link
            v-slot="{ href, isActive, navigate }"
            :to="`/app/accounts/${accountId}/profile/settings`"
            custom
          >
            <a
              :href="href"
              :class="{ 'is-active': isActive }"
              @click="e => handleProfileSettingClick(e, navigate)"
            >
              <NextButton
                ghost
                sm
                slate
                icon="i-lucide-circle-user"
                class="!w-full !justify-start"
              >
                <span class="min-w-0 truncate font-medium text-xs">
                  {{ $t('SIDEBAR_ITEMS.PROFILE_SETTINGS') }}
                </span>
              </NextButton>
            </a>
          </router-link>
        </WootDropdownItem>
        <WootDropdownItem>
          <NextButton
            ghost
            sm
            slate
            icon="i-lucide-sun-moon"
            class="!w-full !justify-start"
            @click="openAppearanceOptions"
          >
            <span class="min-w-0 truncate font-medium text-xs">
              {{ $t('SIDEBAR_ITEMS.APPEARANCE') }}
            </span>
          </NextButton>
        </WootDropdownItem>
        <WootDropdownItem v-if="currentUser.type === 'SuperAdmin'">
          <a
            href="/super_admin"
            target="_blank"
            rel="noopener nofollow noreferrer"
            @click="$emit('close')"
          >
            <NextButton
              ghost
              sm
              slate
              icon="i-lucide-layout-dashboard"
              class="!w-full !justify-start"
            >
              <span class="min-w-0 truncate font-medium text-xs">
                {{ $t('SIDEBAR_ITEMS.SUPER_ADMIN_CONSOLE') }}
              </span>
            </NextButton>
          </a>
        </WootDropdownItem>
        <WootDropdownItem>
          <NextButton
            ghost
            sm
            slate
            icon="i-lucide-circle-power"
            class="!w-full !justify-start"
            @click="logout"
          >
            <span class="min-w-0 truncate font-medium text-xs">
              {{ $t('SIDEBAR_ITEMS.LOGOUT') }}
            </span>
          </NextButton>
        </WootDropdownItem>
      </WootDropdownMenu>
    </div>
  </transition>
</template>
