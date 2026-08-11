<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime, exactTimestamp } from 'shared/helpers/timeHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  suggestion: {
    type: Object,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['approve', 'dismiss', 'review']);
const { t } = useI18n();

const sourceLabel = computed(() =>
  t('CAPTAIN.FAQ_SUGGESTIONS.SOURCE_COUNT', {
    count: props.suggestion.source_count,
  })
);

const updatedAt = computed(() =>
  dynamicTime(props.suggestion.updated_at || props.suggestion.created_at)
);

const language = computed(() =>
  props.suggestion.language?.replace('_', '-').toUpperCase()
);
</script>

<template>
  <CardLayout>
    <div
      class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between"
    >
      <div class="min-w-0">
        <div class="mb-2 flex flex-wrap items-center gap-2">
          <span
            class="inline-flex items-center gap-1.5 rounded-full bg-n-brand/10 px-2.5 py-1 text-xs font-medium text-n-blue-11"
          >
            <Icon icon="i-lucide-messages-square" class="size-3.5" />
            {{ sourceLabel }}
          </span>
          <span
            v-if="language"
            class="rounded-full bg-n-alpha-2 px-2.5 py-1 text-xs font-medium text-n-slate-11"
          >
            {{ language }}
          </span>
        </div>
        <h3 class="text-base font-medium leading-6 text-n-slate-12">
          {{ suggestion.question }}
        </h3>
      </div>
      <Button
        :label="$t('CAPTAIN.FAQ_SUGGESTIONS.REVIEW')"
        icon="i-lucide-list-collapse"
        size="sm"
        variant="faded"
        color="slate"
        class="shrink-0"
        @click="emit('review', suggestion)"
      />
    </div>

    <p class="line-clamp-2 text-sm leading-5 text-n-slate-11">
      {{ suggestion.answer }}
    </p>

    <div
      class="flex flex-col gap-3 border-t border-n-weak pt-2.5 sm:flex-row sm:items-center sm:justify-between"
    >
      <div
        class="flex min-w-0 flex-wrap items-center gap-x-4 gap-y-2 text-xs text-n-slate-10"
      >
        <span class="inline-flex min-w-0 items-center gap-1.5">
          <Icon icon="i-woot-captain" class="size-3.5 shrink-0" />
          <span class="truncate">{{ suggestion.assistant?.name }}</span>
        </span>
        <span
          v-tooltip.top="{
            content: exactTimestamp(
              suggestion.updated_at || suggestion.created_at
            ),
            delay: { show: 500, hide: 0 },
          }"
          class="inline-flex items-center gap-1.5"
        >
          <Icon icon="i-lucide-clock-3" class="size-3.5" />
          {{ updatedAt }}
        </span>
      </div>

      <div class="flex items-center gap-2">
        <Button
          :label="$t('CAPTAIN.FAQ_SUGGESTIONS.DISMISS')"
          icon="i-lucide-circle-x"
          size="sm"
          variant="ghost"
          color="slate"
          :disabled="isLoading"
          @click="emit('dismiss', suggestion)"
        />
        <Button
          :label="$t('CAPTAIN.FAQ_SUGGESTIONS.APPROVE')"
          icon="i-lucide-circle-check-big"
          size="sm"
          :is-loading="isLoading"
          :disabled="isLoading"
          @click="emit('approve', suggestion)"
        />
      </div>
    </div>
  </CardLayout>
</template>
