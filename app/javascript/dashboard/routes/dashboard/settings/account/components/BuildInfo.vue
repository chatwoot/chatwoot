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
    <div v-if="hasAnUpdateAvailable && globalConfig.displayManifest">
      {{
        t('GENERAL_SETTINGS.UPDATE_CHATWOOT', {
          latestChatwootVersion: latestChatwootVersion,
        })
      }}
    </div>
    <div class="divide-x divide-n-slate-9">
      <span class="px-2">{{ `v${globalConfig.appVersion}` }}</span>
      <span
        v-tooltip="t('COMPONENTS.CODE.BUTTON_TEXT')"
        class="px-2 build-id cursor-pointer"
        @click="copyGitSha"
      >
        {{ `Build ${gitSha}` }}
      </span>
    </div>
  </div>
</template>
