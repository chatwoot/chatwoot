<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const globalConfig = useMapGetter('globalConfig/get');

const gitSha = computed(() => {
  return globalConfig.value.gitSha.substring(0, 7);
});

const copyGitSha = () => {
  copyTextToClipboard(globalConfig.value.gitSha);
};
</script>

<template>
  <div class="p-4 text-sm text-center">
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
