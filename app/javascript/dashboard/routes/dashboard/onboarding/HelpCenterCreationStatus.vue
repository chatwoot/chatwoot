<script setup>
import { computed } from 'vue';
import { storeToRefs } from 'pinia';
import { useI18n } from 'vue-i18n';
import { useHelpCenterGenerationStore } from 'dashboard/stores/helpCenterGeneration';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const { t } = useI18n();

const { isCompleted, isSkipped, articlesCount } = storeToRefs(
  useHelpCenterGenerationStore()
);

const statusText = computed(() =>
  isCompleted.value || articlesCount.value > 0
    ? t(
        'ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_ARTICLES',
        { count: articlesCount.value },
        articlesCount.value
      )
    : t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_GENERATING')
);
</script>

<template>
  <div
    v-if="!isSkipped"
    class="flex items-center justify-between gap-3 px-3 py-3 border-t border-n-weak"
  >
    <div class="flex items-center gap-2 min-w-0">
      <Icon
        v-if="isCompleted"
        icon="i-lucide-check"
        class="size-4 text-n-teal-11 flex-shrink-0"
      />
      <Spinner v-else :size="16" class="text-n-slate-9 flex-shrink-0" />
      <span class="text-sm font-medium text-n-slate-12 flex-shrink-0">
        {{ t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER') }}
      </span>
      <span class="w-px h-4 bg-n-weak flex-shrink-0" />
      <span class="text-sm text-n-slate-11 truncate">
        {{
          t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_DESCRIPTION')
        }}
      </span>
    </div>
    <span class="text-sm text-n-slate-11 flex-shrink-0">
      {{ statusText }}
    </span>
  </div>
</template>
