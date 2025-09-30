<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useI18n } from 'vue-i18n';

import semver from 'semver';

const { t } = useI18n();
const { currentAccount } = useAccount();

const latestChatwootVersion = computed(() => {
  return currentAccount.value.latest_chatwoot_version;
});

const globalConfig = useMapGetter('globalConfig/get');

const hasAnUpdateAvailable = computed(() => {
  if (!semver.valid(latestChatwootVersion.value)) {
    return false;
  }

  return semver.lt(globalConfig.value.appVersion, latestChatwootVersion.value);
});

const gitSha = computed(() => {
  return globalConfig.value.gitSha.substring(0, 7);
});

const copyGitSha = () => {
  copyTextToClipboard(globalConfig.value.gitSha);
};
</script>

<template>
  <div class="p-4 text-sm text-center">
    <h3 class="text-lg font-medium text-n-dark-rock">
      {{ t('ACCOUNT_SETTINGS.BUILD_INFO.ABOUT_FLOW') }}
    </h3>
    <div
      v-if="hasAnUpdateAvailable && globalConfig.displayManifest"
      class="my-2"
    >
      {{
        t('GENERAL_SETTINGS.UPDATE_CHATWOOT', {
          latestChatwootVersion: latestChatwootVersion,
        })
      }}
    </div>
    <div class="divide-x divide-n-slate-9 my-2">
      <span class="px-2">{{
        t('ACCOUNT_SETTINGS.BUILD_INFO.VERSION', { version: '4.4.0' })
      }}</span>

      <span
        v-tooltip="t('COMPONENTS.CODE.BUTTON_TEXT')"
        class="px-2 build-id cursor-pointer"
        @click="copyGitSha"
      >
        {{ t('ACCOUNT_SETTINGS.BUILD_INFO.BUILD_ID', { gitSha }) }}
      </span>
    </div>
    <div class="mt-4">
      <p class="text-n-solid-slate">
        {{ t('ACCOUNT_SETTINGS.BUILD_INFO.BUILT_ON') }}
        <a
          href="https://www.chatwoot.com"
          target="_blank"
          rel="noopener noreferrer"
          class="text-woot-500"
        >
          {{ t('ACCOUNT_SETTINGS.BUILD_INFO.COMMUNITY_EDITION') }}
        </a>
        {{ t('ACCOUNT_SETTINGS.BUILD_INFO.MIT_LICENSE') }}
      </p>
    </div>
    <div class="mt-2 text-n-solid-slate divide-x divide-n-slate-9">
      <a href="#" class="px-2 hover:underline">{{
        t('ACCOUNT_SETTINGS.BUILD_INFO.PRIVACY_POLICY')
      }}</a>
      <a href="#" class="px-2 hover:underline">{{
        t('ACCOUNT_SETTINGS.BUILD_INFO.TERMS_OF_SERVICE')
      }}</a>
    </div>
  </div>
</template>
