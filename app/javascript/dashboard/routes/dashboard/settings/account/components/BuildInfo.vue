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
  <div
    class="p-6 bg-surface-container-low rounded-xl border border-outline-variant/5 text-[10px] text-on-primary-container leading-relaxed"
  >
    <div
      v-if="hasAnUpdateAvailable && globalConfig.displayManifest"
      class="mb-3 text-xs text-amber-400 text-left"
    >
      {{
        t('GENERAL_SETTINGS.UPDATE_CHATWOOT', {
          latestChatwootVersion: latestChatwootVersion,
        })
      }}
    </div>
    <div class="space-y-1 font-medium uppercase tracking-wide">
      <p class="mb-0">
        {{ `v${globalConfig.appVersion}` }}
      </p>
      <p class="mb-0">
        <button
          v-tooltip="t('COMPONENTS.CODE.BUTTON_TEXT')"
          type="button"
          class="text-left w-full hover:text-on-surface-variant transition-colors cursor-pointer bg-transparent border-0 p-0 font-inherit"
          @click="copyGitSha"
        >
          {{ `Build ${gitSha}` }}
        </button>
      </p>
    </div>
  </div>
</template>
