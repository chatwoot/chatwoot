<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import {
  TemplateNormalizer,
  TemplatePreview,
} from 'dashboard/components-next/template-preview';
import { PLATFORMS } from 'dashboard/services/TemplateConstants';
import {
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

const { t } = useI18n();
const META_TEMPLATE_MANAGER_URL =
  'https://business.facebook.com/latest/whatsapp_manager/message_templates';
const TWILIO_TEMPLATE_MANAGER_URL =
  'https://console.twilio.com/us1/develop/sms/content-editor';

const panelRef = ref(null);

const platform = computed(() => props.template?.platform || PLATFORMS.WHATSAPP);
const normalizedTemplate = computed(() =>
  props.template
    ? TemplateNormalizer.normalize(props.template, platform.value)
    : null
);
const variables = computed(() => normalizedTemplate.value?.variables || {});
const managementUrl = computed(() => {
  if (platform.value === PLATFORMS.TWILIO) {
    return TWILIO_TEMPLATE_MANAGER_URL;
  }

  return props.template?.inboxes?.some(
    inbox => inbox.provider === 'whatsapp_cloud'
  )
    ? META_TEMPLATE_MANAGER_URL
    : null;
});
const managementLabel = computed(() =>
  platform.value === PLATFORMS.TWILIO
    ? t('WHATSAPP_TEMPLATE_MGMT.MANAGE_IN_TWILIO')
    : t('WHATSAPP_TEMPLATE_MGMT.MANAGE_IN_META')
);
const statusLabel = computed(() =>
  props.template?.status?.toLowerCase() === 'unsubmitted'
    ? t('WHATSAPP_TEMPLATE_MGMT.STATUSES.UNSUBMITTED')
    : formatTemplateLabel(props.template?.status)
);
const open = () => panelRef.value?.open();
const close = () => panelRef.value?.close();

defineExpose({ open, close });
</script>

<template>
  <SidePanel
    ref="panelRef"
    width="md"
    :title="template?.name"
    :description="$t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.DESCRIPTION')"
  >
    <div v-if="template" class="flex flex-col gap-6">
      <div
        class="flex items-center justify-center px-6 py-10 border rounded-xl min-h-80 border-n-weak bg-n-alpha-1"
      >
        <TemplatePreview
          :template="template"
          :variables="variables"
          :platform="platform"
        />
      </div>

      <div>
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.DETAILS') }}
        </h3>
        <dl class="grid grid-cols-[8rem_1fr] gap-x-4 gap-y-3 mt-4 text-sm">
          <dt class="text-n-slate-10">
            {{ $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.STATUS') }}
          </dt>
          <dd>
            <span
              class="inline-flex px-2 py-0.5 text-xs font-medium rounded-md"
              :class="templateStatusClasses(template.status)"
            >
              {{ statusLabel }}
            </span>
          </dd>
          <dt class="text-n-slate-10">
            {{ $t('WHATSAPP_TEMPLATE_MGMT.PREVIEW.TYPE') }}
          </dt>
          <dd class="text-n-slate-12">
            {{
              $t(`WHATSAPP_TEMPLATE_MGMT.TYPES.${templateTypeKey(template)}`)
            }}
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
        </dl>
      </div>
    </div>

    <template v-if="managementUrl" #footer>
      <a :href="managementUrl" target="_blank" rel="noopener noreferrer">
        <Button
          class="w-full"
          :label="managementLabel"
          icon="i-lucide-external-link"
          trailing-icon
        />
      </a>
    </template>
  </SidePanel>
</template>
