<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  formatTemplateDate,
  formatTemplateLabel,
  formatTemplateLanguage,
  templateStatusClasses,
  templateTypeKey,
} from './templateUtils';

const props = defineProps({
  template: {
    type: Object,
    required: true,
  },
});

defineEmits(['preview']);

const { t } = useI18n();

const visibleInboxes = computed(() => props.template.inboxes.slice(0, 2));
const remainingInboxCount = computed(() =>
  Math.max(props.template.inboxes.length - visibleInboxes.value.length, 0)
);
const typeLabels = computed(() => ({
  TEXT: t('WHATSAPP_TEMPLATE_MGMT.TYPES.TEXT'),
  IMAGE: t('WHATSAPP_TEMPLATE_MGMT.TYPES.IMAGE'),
  VIDEO: t('WHATSAPP_TEMPLATE_MGMT.TYPES.VIDEO'),
  DOCUMENT: t('WHATSAPP_TEMPLATE_MGMT.TYPES.DOCUMENT'),
  MEDIA: t('WHATSAPP_TEMPLATE_MGMT.TYPES.MEDIA'),
  QUICK_REPLY: t('WHATSAPP_TEMPLATE_MGMT.TYPES.QUICK_REPLY'),
  CALL_TO_ACTION: t('WHATSAPP_TEMPLATE_MGMT.TYPES.CALL_TO_ACTION'),
  CATALOG: t('WHATSAPP_TEMPLATE_MGMT.TYPES.CATALOG'),
  COPY_CODE: t('WHATSAPP_TEMPLATE_MGMT.TYPES.COPY_CODE'),
}));
const typeLabel = computed(
  () => typeLabels.value[templateTypeKey(props.template)]
);
const showStatus = computed(
  () => props.template.status?.toLowerCase() !== 'approved'
);
const isDisabled = computed(
  () => props.template.status?.toLowerCase() === 'disabled'
);
</script>

<template>
  <button
    type="button"
    class="group relative flex w-full items-start gap-8 rounded-2xl bg-n-alpha-2 px-6 py-5 text-start outline outline-1 -outline-offset-1 outline-transparent transition-[outline-color] hover:outline-n-slate-6 focus-visible:outline-2 focus-visible:outline-n-brand dark:bg-n-solid-2 dark:hover:outline-n-slate-6"
    :aria-label="
      $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.OPEN', { name: template.name })
    "
    @click="$emit('preview')"
  >
    <div class="flex min-w-0 flex-1 flex-col gap-3">
      <div class="flex min-w-0 items-center gap-3 pe-8">
        <span class="truncate text-base font-medium leading-6 text-n-slate-12">
          {{ template.name }}
        </span>
        <span
          v-if="showStatus"
          class="inline-flex shrink-0 rounded-md px-2 py-0.5 text-xs font-medium"
          :class="templateStatusClasses(template.status)"
        >
          {{ formatTemplateLabel(template.status) }}
        </span>
      </div>

      <div
        class="flex h-6 min-w-0 items-center justify-between gap-4 text-sm"
        :class="isDisabled ? 'text-n-slate-10' : 'text-n-slate-12'"
      >
        <div class="flex min-w-0 flex-wrap items-center gap-x-3 gap-y-2">
          <span class="inline-flex items-center gap-1.5">
            <Icon icon="i-lucide-gallery-vertical-end" class="size-4" />
            {{ typeLabel }}
          </span>
          <span class="inline-flex items-center gap-1.5">
            <Icon icon="i-lucide-languages" class="size-4" />
            {{ formatTemplateLanguage(template.language) }}
          </span>
          <span
            v-for="inbox in visibleInboxes"
            :key="inbox.id"
            class="inline-flex min-w-0 items-center gap-1.5"
          >
            <span
              class="inline-flex size-5 shrink-0 items-center justify-center rounded-full bg-n-alpha-2"
            >
              <ChannelIcon :inbox="inbox" use-brand-icon class="size-3.5" />
            </span>
            <span class="max-w-44 truncate">{{ inbox.name }}</span>
          </span>
          <span
            v-if="remainingInboxCount"
            class="inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-n-alpha-2 px-1 text-xs text-n-slate-11"
          >
            {{
              $t('WHATSAPP_TEMPLATE_MGMT.MORE_INBOXES', {
                n: remainingInboxCount,
              })
            }}
          </span>
        </div>

        <span class="hidden shrink-0 text-sm text-n-slate-11 lg:block">
          {{
            $t('WHATSAPP_TEMPLATE_MGMT.LAST_SYNCED', {
              date: formatTemplateDate(template.lastUpdatedAt),
            })
          }}
        </span>
      </div>
    </div>

    <Icon
      icon="i-lucide-ellipsis-vertical"
      class="absolute end-4 top-5 size-4 text-n-slate-11"
    />
  </button>
</template>
