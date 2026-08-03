<script setup>
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue';
import { useEventListener } from '@vueuse/core';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import {
  TemplateNormalizer,
  TemplatePreview,
} from 'dashboard/components-next/template-preview';
import { PLATFORMS } from 'dashboard/services/TemplateConstants';
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
    default: null,
  },
});

const emit = defineEmits(['close']);
const { t } = useI18n();
const META_TEMPLATE_MANAGER_URL =
  'https://business.facebook.com/latest/whatsapp_manager/message_templates';
const TWILIO_TEMPLATE_MANAGER_URL =
  'https://console.twilio.com/us1/develop/sms/content-editor';
const drawerRef = ref(null);
let previousActiveElement = null;

const isOpen = computed(() => Boolean(props.template));
const platform = computed(() => props.template?.platform || PLATFORMS.WHATSAPP);
const normalizedTemplate = computed(() =>
  props.template
    ? TemplateNormalizer.normalize(props.template, platform.value)
    : null
);
const variables = computed(() => normalizedTemplate.value?.variables || {});
const managementUrl = computed(() =>
  platform.value === PLATFORMS.TWILIO
    ? TWILIO_TEMPLATE_MANAGER_URL
    : META_TEMPLATE_MANAGER_URL
);
const managementLabel = computed(() =>
  platform.value === PLATFORMS.TWILIO
    ? t('WHATSAPP_TEMPLATE_MGMT.MANAGE_IN_TWILIO')
    : t('WHATSAPP_TEMPLATE_MGMT.MANAGE_IN_META')
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

const closeDrawer = () => {
  emit('close');
  if (previousActiveElement?.isConnected) previousActiveElement.focus();
  previousActiveElement = null;
};

useEventListener(document, 'keydown', event => {
  if (!isOpen.value || event.key !== 'Escape') return;

  event.preventDefault();
  closeDrawer();
});

watch(
  isOpen,
  open => {
    if (!open) return;

    previousActiveElement =
      document.activeElement instanceof HTMLElement
        ? document.activeElement
        : null;
    nextTick(() => drawerRef.value?.focus());
  },
  { immediate: true }
);

onBeforeUnmount(() => {
  if (previousActiveElement?.isConnected) previousActiveElement.focus();
});
</script>

<template>
  <TeleportWithDirection to="body">
    <div
      v-if="isOpen"
      class="fixed inset-0 z-50 bg-black/30"
      role="presentation"
      @click.self="closeDrawer"
    >
      <aside
        ref="drawerRef"
        class="fixed inset-y-0 end-0 flex w-full max-w-xl flex-col bg-n-solid-1 shadow-xl outline outline-1 outline-n-container"
        role="dialog"
        aria-modal="true"
        :aria-label="$t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.TITLE')"
        tabindex="-1"
      >
        <header
          class="flex items-start justify-between gap-4 border-b border-n-weak px-6 py-5"
        >
          <div class="min-w-0">
            <div class="flex min-w-0 items-center gap-2">
              <h2 class="truncate text-lg font-medium text-n-slate-12">
                {{ template.name }}
              </h2>
              <span
                class="inline-flex shrink-0 rounded-md px-2 py-0.5 text-xs font-medium"
                :class="templateStatusClasses(template.status)"
              >
                {{ formatTemplateLabel(template.status) }}
              </span>
            </div>
            <p class="mt-1 text-sm text-n-slate-11">
              {{ $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.DESCRIPTION') }}
            </p>
          </div>
          <Button
            icon="i-lucide-x"
            variant="ghost"
            color="slate"
            size="sm"
            :aria-label="$t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.CLOSE')"
            @click="closeDrawer"
          />
        </header>

        <div class="min-h-0 flex-1 overflow-y-auto">
          <div
            class="flex min-h-80 items-center justify-center border-b border-n-weak bg-n-alpha-1 px-6 py-10"
          >
            <TemplatePreview
              :template="template"
              :variables="variables"
              :platform="platform"
            />
          </div>

          <div class="px-6 py-5">
            <h3 class="text-sm font-medium text-n-slate-12">
              {{ $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.DETAILS') }}
            </h3>
            <dl class="mt-4 grid grid-cols-[8rem_1fr] gap-x-4 gap-y-3 text-sm">
              <dt class="text-n-slate-10">
                {{ $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.TYPE') }}
              </dt>
              <dd class="text-n-slate-12">
                {{ typeLabels[templateTypeKey(template)] }}
              </dd>
              <dt class="text-n-slate-10">
                {{ $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.CATEGORY') }}
              </dt>
              <dd class="text-n-slate-12">
                {{ formatTemplateLabel(template.category) }}
              </dd>
              <dt class="text-n-slate-10">
                {{ $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.LANGUAGE') }}
              </dt>
              <dd class="text-n-slate-12">
                {{ formatTemplateLanguage(template.language) }}
              </dd>
              <dt class="text-n-slate-10">
                {{ $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.INBOXES') }}
              </dt>
              <dd class="text-n-slate-12">{{ template.inboxNames }}</dd>
              <dt class="text-n-slate-10">
                {{ $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.LAST_SYNCED') }}
              </dt>
              <dd class="text-n-slate-12">
                {{ formatTemplateDate(template.lastUpdatedAt) }}
              </dd>
            </dl>
          </div>
        </div>

        <footer class="border-t border-n-weak px-6 py-4">
          <a :href="managementUrl" target="_blank" rel="noopener noreferrer">
            <Button
              class="w-full"
              :label="managementLabel"
              icon="i-lucide-external-link"
              trailing-icon
            />
          </a>
        </footer>
      </aside>
    </div>
  </TeleportWithDirection>
</template>
