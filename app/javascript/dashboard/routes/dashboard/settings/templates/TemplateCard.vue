<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
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

const emit = defineEmits(['preview']);

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
  <CardLayout layout="row" @click="emit('preview')">
    <div class="flex flex-col flex-1 min-w-0 gap-2 cursor-pointer">
      <div class="flex items-center min-w-0 gap-2">
        <span class="text-base font-medium truncate text-n-slate-12">
          {{ template.name }}
        </span>
        <span
          v-if="showStatus"
          class="inline-flex items-center h-6 px-2 py-0.5 text-xs font-medium rounded-md shrink-0"
          :class="templateStatusClasses(template.status)"
        >
          {{ formatTemplateLabel(template.status) }}
        </span>
      </div>

      <div
        class="flex items-center justify-between h-6 min-w-0 gap-4 text-sm"
        :class="isDisabled ? 'text-n-slate-10' : 'text-n-slate-11'"
      >
        <div class="flex flex-wrap items-center min-w-0 gap-x-3 gap-y-2">
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
            class="inline-flex items-center min-w-0 gap-1.5"
          >
            <ChannelIcon :inbox="inbox" class="size-4 shrink-0" />
            <span class="truncate max-w-44">{{ inbox.name }}</span>
          </span>
          <span
            v-if="remainingInboxCount"
            class="inline-flex items-center justify-center h-5 px-1 text-xs rounded-full min-w-5 bg-n-alpha-2 text-n-slate-11"
          >
            {{
              $t('WHATSAPP_TEMPLATE_MGMT.MORE_INBOXES', {
                n: remainingInboxCount,
              })
            }}
          </span>
        </div>

        <span class="hidden text-sm shrink-0 text-n-slate-11 lg:block">
          {{
            $t('WHATSAPP_TEMPLATE_MGMT.LAST_SYNCED', {
              date: formatTemplateDate(template.lastUpdatedAt),
            })
          }}
        </span>
      </div>
    </div>
  </CardLayout>
</template>
