<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useConfig } from 'dashboard/composables/useConfig';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';

import Auth from 'dashboard/api/auth';
import Avatar from 'next/avatar/Avatar.vue';
import allLocales from 'shared/constants/locales';
import MobileSettingsHeader from './MobileSettingsHeader.vue';
import MobileAvailabilityToggle from './MobileAvailabilityToggle.vue';
import MobileBottomSheet from './MobileBottomSheet.vue';
import {
  hasPushPermissions,
  requestPushPermissions,
  unregisterSubscription,
  verifyServiceWorkerExistence,
} from 'dashboard/helper/pushHelper';

const store = useStore();
const { t, locale } = useI18n();
const { enabledLanguages } = useConfig();
const { currentAccount } = useAccount();
const { updateUISettings, uiSettings } = useUISettings();

const currentUser = useMapGetter('getCurrentUser');

const userName = computed(() => currentUser.value?.name || '');
const userEmail = computed(() => currentUser.value?.email || '');
const userAvatar = computed(() => currentUser.value?.avatar_url || '');
const userAvailability = computed(
  () => currentUser.value?.availability_status || 'online'
);
const currentUserAccounts = computed(() => currentUser.value?.accounts || []);
const canSwitchAccount = computed(() => currentUserAccounts.value.length > 1);
const currentLocale = computed(() => uiSettings.value?.locale ?? '');
const isLanguageSheetOpen = ref(false);
const isAccountSheetOpen = ref(false);

// Push notification state
const pushEnabled = ref(false);
const pushLoading = ref(false);
const pushDenied = ref(false);

const hasPushSupport = computed(
  () =>
    'serviceWorker' in navigator &&
    'PushManager' in window &&
    'Notification' in window
);

const isStandalone = computed(
  () =>
    window.matchMedia('(display-mode: standalone)').matches ||
    window.navigator.standalone === true
);

const showPushSection = computed(() => hasPushSupport.value);

const pushStatusText = computed(() => {
  if (pushDenied.value) return t('MOBILE.PUSH.DENIED');
  if (!isStandalone.value && /iPhone|iPad/.test(navigator.userAgent)) {
    return t('MOBILE.PUSH.IOS_INSTALL_REQUIRED');
  }
  if (pushEnabled.value) return t('MOBILE.PUSH.ENABLED');
  return t('MOBILE.PUSH.DISABLED');
});

const checkPushStatus = () => {
  if (!hasPushSupport.value) return;

  if (Notification.permission === 'denied') {
    pushDenied.value = true;
    pushEnabled.value = false;
    return;
  }

  if (hasPushPermissions()) {
    verifyServiceWorkerExistence(registration =>
      registration.pushManager
        .getSubscription()
        .then(subscription => {
          pushEnabled.value = !!subscription;
        })
        .catch(() => {
          pushEnabled.value = false;
        })
    );
  } else {
    pushEnabled.value = false;
  }
};

const togglePush = () => {
  if (pushDenied.value) return;
  if (pushLoading.value) return;

  if (pushEnabled.value) {
    // Disable push
    pushLoading.value = true;
    unregisterSubscription(() => {
      pushEnabled.value = false;
    })
      .catch(() => {
        useAlert(t('MOBILE.PUSH.UPDATE_ERROR'));
      })
      .finally(() => {
        pushLoading.value = false;
      });
  } else {
    // Enable push
    pushLoading.value = true;
    requestPushPermissions({
      onSuccess: () => {
        pushEnabled.value = true;
        pushLoading.value = false;
      },
    });
    // Handle case where permission prompt is dismissed or denied
    setTimeout(() => {
      if (pushLoading.value) {
        pushLoading.value = false;
        if (Notification.permission === 'denied') {
          pushDenied.value = true;
        }
      }
    }, 10000);
  }
};

onMounted(() => {
  checkPushStatus();
});

const onAvailabilityChange = status => {
  store.dispatch('updateAvailability', {
    availability: status,
    account_id: currentUser.value.account_id,
  });
};

const onLogout = () => {
  Auth.logout();
};

const accountDefaultLanguage = computed(() => {
  const accountLocale = currentAccount.value?.locale;
  return allLocales[accountLocale] || accountLocale || '';
});

const languageOptions = computed(() => [
  {
    name: t('MOBILE.SETTINGS.USE_ACCOUNT_DEFAULT'),
    iso_639_1_code: '',
  },
  ...(enabledLanguages ?? []),
]);

const currentLanguageLabel = computed(() => {
  if (!currentLocale.value) {
    return (
      accountDefaultLanguage.value || t('MOBILE.SETTINGS.USE_ACCOUNT_DEFAULT')
    );
  }

  const selectedLanguage = languageOptions.value.find(
    option => option.iso_639_1_code === currentLocale.value
  );

  return (
    selectedLanguage?.name ||
    allLocales[currentLocale.value] ||
    currentLocale.value
  );
});

const sortedAccounts = computed(() => {
  return [...currentUserAccounts.value].sort((firstAccount, secondAccount) =>
    firstAccount.name.localeCompare(secondAccount.name)
  );
});

const currentAccountLabel = computed(() => currentAccount.value?.name || '');

const onOpenLanguageSheet = () => {
  isLanguageSheetOpen.value = true;
};

const onOpenAccountSheet = () => {
  if (!canSwitchAccount.value) return;
  isAccountSheetOpen.value = true;
};

const updateLanguage = async languageCode => {
  try {
    if (!languageCode) {
      await updateUISettings({ locale: null });
      locale.value =
        currentAccount.value?.locale || window.chatwootConfig.selectedLocale;
      useAlert(t('MOBILE.SETTINGS.LANGUAGE_UPDATED'));
      isLanguageSheetOpen.value = false;
      return;
    }

    const isValidLanguage = (enabledLanguages || []).some(
      option => option.iso_639_1_code === languageCode
    );

    if (!isValidLanguage) {
      throw new Error(`Invalid language code: ${languageCode}`);
    }

    await updateUISettings({ locale: languageCode });
    locale.value = languageCode;
    useAlert(t('MOBILE.SETTINGS.LANGUAGE_UPDATED'));
    isLanguageSheetOpen.value = false;
  } catch (error) {
    useAlert(t('MOBILE.SETTINGS.LANGUAGE_UPDATE_ERROR'));
  }
};

const changeAccount = accountId => {
  if (!accountId || accountId === currentAccount.value?.id) {
    isAccountSheetOpen.value = false;
    return;
  }

  window.location.href = `/app/accounts/${accountId}/dashboard`;
};

const settingsItems = computed(() => [
  {
    icon: 'i-lucide-globe',
    label: t('MOBILE.SETTINGS.LANGUAGE'),
    action: 'language',
    value: currentLanguageLabel.value,
    onClick: onOpenLanguageSheet,
  },
  {
    icon: 'i-lucide-refresh-cw',
    label: t('MOBILE.SETTINGS.SWITCH_ACCOUNT'),
    action: 'switch-account',
    value: currentAccountLabel.value,
    onClick: onOpenAccountSheet,
    disabled: !canSwitchAccount.value,
  },
]);
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-y-auto">
    <MobileSettingsHeader />

    <!-- User Profile Section -->
    <div class="flex items-center gap-3 px-4 py-5 border-b border-n-weak">
      <Avatar :src="userAvatar" :name="userName" :size="56" />
      <div class="flex flex-col min-w-0">
        <span class="text-base font-semibold text-n-slate-12 truncate">
          {{ userName }}
        </span>
        <span class="text-sm text-n-slate-10 truncate">
          {{ userEmail }}
        </span>
      </div>
    </div>

    <!-- Availability -->
    <div class="px-4 py-4 border-b border-n-weak">
      <span
        class="text-xs font-medium text-n-slate-10 uppercase tracking-wider mb-2 block"
      >
        {{ t('MOBILE.SETTINGS.AVAILABILITY') }}
      </span>
      <MobileAvailabilityToggle
        :current-status="userAvailability"
        @change="onAvailabilityChange"
      />
    </div>

    <!-- Push Notifications -->
    <div v-if="showPushSection" class="px-4 py-4 border-b border-n-weak">
      <span
        class="text-xs font-medium text-n-slate-10 uppercase tracking-wider mb-3 block"
      >
        {{ t('MOBILE.PUSH.TITLE') }}
      </span>
      <button
        class="flex items-center w-full gap-3 py-1"
        :class="{ 'opacity-50': pushDenied }"
        @click="togglePush"
      >
        <span class="i-lucide-bell size-5 text-n-slate-12" />
        <div class="flex flex-col items-start min-w-0 flex-1">
          <span class="text-sm text-n-slate-12">
            {{ t('MOBILE.PUSH.LABEL') }}
          </span>
          <span class="text-xs text-n-slate-10 truncate w-full text-left">
            {{ pushStatusText }}
          </span>
        </div>
        <div
          class="relative w-11 h-6 rounded-full transition-colors flex-shrink-0"
          :class="pushEnabled ? 'bg-n-brand' : 'bg-n-slate-7'"
        >
          <span
            v-if="pushLoading"
            class="absolute inset-0 flex items-center justify-center"
          >
            <span class="i-lucide-loader-2 size-3.5 text-white animate-spin" />
          </span>
          <span
            v-else
            class="absolute top-0.5 ltr:left-0.5 rtl:right-0.5 size-5 rounded-full bg-white shadow transition-transform"
            :class="
              pushEnabled
                ? 'ltr:translate-x-5 rtl:-translate-x-5'
                : 'translate-x-0'
            "
          />
        </div>
      </button>
      <p v-if="pushDenied" class="text-xs text-n-ruby-9 mt-2 px-8">
        {{ t('MOBILE.PUSH.DENIED_HELP') }}
      </p>
    </div>

    <!-- Settings List -->
    <div class="flex flex-col">
      <button
        v-for="item in settingsItems"
        :key="item.action"
        class="flex items-center gap-3 px-4 py-3.5 text-left text-n-slate-12 active:bg-n-alpha-1 border-b border-n-weak"
        :class="{ 'opacity-60': item.disabled }"
        :disabled="item.disabled"
        @click="item.onClick"
      >
        <span class="size-5" :class="item.icon" />
        <div class="min-w-0 flex-1">
          <span class="text-sm block">{{ item.label }}</span>
          <span
            v-if="item.value"
            class="text-xs text-n-slate-10 truncate block"
          >
            {{ item.value }}
          </span>
        </div>
        <span class="i-lucide-chevron-right size-4 ml-auto text-n-slate-10" />
      </button>
    </div>

    <!-- Logout -->
    <div class="px-4 py-4 mt-auto">
      <button
        class="flex items-center justify-center gap-2 w-full py-3 text-sm font-medium text-n-ruby-9 rounded-lg border border-n-weak active:bg-n-alpha-1"
        @click="onLogout"
      >
        <span class="i-lucide-log-out size-4" />
        {{ t('MOBILE.SETTINGS.LOGOUT') }}
      </button>
    </div>

    <MobileBottomSheet
      v-if="isLanguageSheetOpen"
      :title="t('MOBILE.SETTINGS.LANGUAGE')"
      @close="isLanguageSheetOpen = false"
    >
      <div class="flex flex-col gap-2">
        <button
          v-for="option in languageOptions"
          :key="option.iso_639_1_code || 'account-default'"
          class="flex items-center gap-3 w-full rounded-xl border border-n-weak px-4 py-3 text-left active:bg-n-alpha-1"
          @click="updateLanguage(option.iso_639_1_code)"
        >
          <span class="flex-1 min-w-0">
            <span class="text-sm text-n-slate-12 block truncate">{{
              option.name
            }}</span>
            <span
              v-if="!option.iso_639_1_code && accountDefaultLanguage"
              class="text-xs text-n-slate-10 block truncate"
            >
              {{ accountDefaultLanguage }}
            </span>
          </span>
          <span
            v-if="
              option.iso_639_1_code === currentLocale ||
              (!option.iso_639_1_code && !currentLocale)
            "
            class="i-lucide-check size-4 text-n-brand flex-shrink-0"
          />
        </button>
      </div>
    </MobileBottomSheet>

    <MobileBottomSheet
      v-if="isAccountSheetOpen"
      :title="t('MOBILE.SETTINGS.SWITCH_ACCOUNT')"
      @close="isAccountSheetOpen = false"
    >
      <div class="flex flex-col gap-2">
        <button
          v-for="account in sortedAccounts"
          :key="account.id"
          class="flex items-center gap-3 w-full rounded-xl border border-n-weak px-4 py-3 text-left active:bg-n-alpha-1"
          @click="changeAccount(account.id)"
        >
          <span class="flex-1 min-w-0">
            <span class="text-sm text-n-slate-12 block truncate">{{
              account.name
            }}</span>
            <span class="text-xs text-n-slate-10 block truncate capitalize">{{
              account.custom_role_id ? account.custom_role.name : account.role
            }}</span>
          </span>
          <span
            v-if="account.id === currentAccount?.id"
            class="i-lucide-check size-4 text-n-brand flex-shrink-0"
          />
        </button>
      </div>
    </MobileBottomSheet>
  </div>
</template>
