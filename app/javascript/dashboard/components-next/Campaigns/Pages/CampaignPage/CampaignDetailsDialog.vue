<script setup>
import { computed, ref, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { messageStamp } from 'shared/helpers/timeHelper';
import { useMapGetter } from 'dashboard/composables/store';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TemplatePreview from 'dashboard/components-next/Templates/TemplateBuilder/TemplatePreview.vue';

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  campaign: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const dialogRef = ref(null);
const getLabelById = useMapGetter('labels/getLabelById');

watch(
  () => props.isOpen,
  async newVal => {
    if (newVal) {
      await nextTick();
      dialogRef.value?.open();
    } else {
      dialogRef.value?.close();
    }
  }
);

// Delivery Report
const deliveryReport = computed(() => props.campaign?.delivery_report);
const hasDeliveryReport = computed(() => !!deliveryReport.value);
const hasErrors = computed(() => deliveryReport.value?.errors?.length > 0);

// Status
const statusConfig = computed(() => {
  if (!hasDeliveryReport.value) {
    const isCompleted = props.campaign?.campaign_status === 'completed';
    return {
      text: isCompleted
        ? t('CAMPAIGN.SMS.CARD.STATUS.COMPLETED')
        : t('CAMPAIGN.SMS.CARD.STATUS.SCHEDULED'),
      color: isCompleted
        ? 'bg-n-slate-3 text-n-slate-11'
        : 'bg-n-teal-3 text-n-teal-11',
      icon: isCompleted ? 'i-lucide-check-circle' : 'i-lucide-clock',
    };
  }

  const status = deliveryReport.value?.status;
  if (status === 'completed') {
    return {
      text: t('CAMPAIGN.DETAILS.STATUS_SUCCESS'),
      color: 'bg-n-teal-3 text-n-teal-11',
      icon: 'i-lucide-check-circle',
    };
  }
  if (status === 'completed_with_errors') {
    return {
      text: t('CAMPAIGN.DETAILS.STATUS_WITH_ERRORS'),
      color: 'bg-n-ruby-3 text-n-ruby-11',
      icon: 'i-lucide-alert-circle',
    };
  }
  if (status === 'running') {
    return {
      text: t('CAMPAIGN.DETAILS.STATUS_RUNNING'),
      color: 'bg-n-amber-3 text-n-amber-11',
      icon: 'i-lucide-loader',
    };
  }
  return {
    text: status || t('CAMPAIGN.SMS.CARD.STATUS.SCHEDULED'),
    color: 'bg-n-slate-3 text-n-slate-11',
    icon: 'i-lucide-clock',
  };
});

// Audience Labels with names
const audienceLabels = computed(() => {
  if (!props.campaign?.audience) return [];
  return props.campaign.audience
    .filter(a => a.type === 'Label')
    .map(a => {
      const label = getLabelById.value(a.id);
      return {
        id: a.id,
        title: label?.title || `#${a.id}`,
        color: label?.color || '#6b7280',
      };
    });
});

// Template Info
const templateParams = computed(() => props.campaign?.template_params);
const templateName = computed(() => {
  const name = templateParams.value?.name;
  if (!name) return null;
  return name.replace(/_/g, ' ');
});

// Template Parameters for display
const templateVariables = computed(() => {
  const processedParams = templateParams.value?.processed_params;
  if (!processedParams) return [];

  const variables = [];

  // Header params
  if (processedParams.header?.length) {
    processedParams.header.forEach((param, idx) => {
      if (param.type === 'text' && param.text) {
        variables.push({
          section: 'Header',
          index: idx + 1,
          value: param.text,
        });
      } else if (param.type === 'image' && param.image?.link) {
        variables.push({
          section: 'Header',
          index: idx + 1,
          value: param.image.link,
          type: 'image',
        });
      }
    });
  }

  // Body params
  if (processedParams.body?.length) {
    processedParams.body.forEach((param, idx) => {
      if (param.type === 'text' && param.text) {
        variables.push({ section: 'Body', index: idx + 1, value: param.text });
      }
    });
  }

  // Button params
  if (processedParams.buttons?.length) {
    processedParams.buttons.forEach((btn, idx) => {
      if (btn.sub_type === 'url' && btn.parameters?.[0]?.text) {
        variables.push({
          section: 'Button',
          index: idx + 1,
          value: btn.parameters[0].text,
        });
      }
    });
  }

  return variables;
});

const formatDate = timestamp => {
  if (!timestamp) return '-';
  const date =
    typeof timestamp === 'number'
      ? new Date(timestamp * 1000)
      : new Date(timestamp);
  return messageStamp(date, 'LLL d, h:mm a');
};

// Map campaign template to preview props
const previewProps = computed(() => {
  const defaultProps = {
    headerFormat: null,
    headerText: '',
    headerTextExample: '',
    headerMediaUrl: '',
    headerMediaName: '',
    bodyText: props.campaign?.message || '',
    bodyExamples: [],
    footerText: '',
    buttons: [],
  };

  if (!props.campaign?.template_params) {
    return defaultProps;
  }

  const processedParams = templateParams.value?.processed_params || {};
  
  // Extract header info
  let headerFormat = null;
  let mediaUrl = '';
  let mediaName = '';

  if (processedParams.header?.media_url) {
    // Determine format from URL or type
    const url = processedParams.header.media_url;
    mediaUrl = url;
    mediaName = processedParams.header.media_name || '';
    
    // Try to detect media type from extension or content
    if (url.match(/\.(jpg|jpeg|png|gif|webp)($|\?)/i)) {
      headerFormat = 'IMAGE';
    } else if (url.match(/\.(mp4|mov|avi)($|\?)/i)) {
      headerFormat = 'VIDEO';
    } else if (url.match(/\.(pdf|doc|docx|xls|xlsx)($|\?)/i)) {
      headerFormat = 'DOCUMENT';
    } else {
      // Default to image if URL is present but type unknown
      headerFormat = 'IMAGE';
    }
  }

  // Use the message for body text (already processed with variables replaced)
  const bodyText = props.campaign?.message || '';

  return {
    ...defaultProps,
    headerFormat,
    headerMediaUrl: mediaUrl,
    headerMediaName: mediaName,
    bodyText,
  };
});

const handleClose = () => emit('close');
</script>

<template>
  <Dialog
    ref="dialogRef"
    :show-cancel-button="false"
    :show-confirm-button="false"
    width="5xl"
    @close="handleClose"
  >
    <div class="flex flex-col -mx-6 -my-6 max-h-[85vh]">
      <!-- Header -->
      <div class="flex-shrink-0 px-6 py-4 border-b border-n-weak">
        <div class="flex items-start justify-between gap-4">
          <div class="flex flex-col gap-1 min-w-0 flex-1">
            <h3 class="text-lg font-semibold text-n-slate-12 truncate">
              {{ campaign?.title }}
            </h3>
            <div class="flex items-center gap-2 text-sm text-n-slate-11">
              <Icon :icon="statusConfig.icon" class="size-4" />
              <span
                class="px-2 py-0.5 rounded-md text-xs font-medium"
                :class="statusConfig.color"
              >
                {{ statusConfig.text }}
              </span>
            </div>
          </div>
          <button
            class="p-1.5 rounded-lg hover:bg-n-alpha-2 transition-colors"
            @click="handleClose"
          >
            <Icon icon="i-lucide-x" class="size-5 text-n-slate-11" />
          </button>
        </div>
      </div>

      <!-- Content: Two columns -->
      <div class="flex-1 flex gap-6 p-6 overflow-hidden min-h-0">
        <!-- Left Panel: Campaign Info -->
        <div class="flex-1 min-w-0 overflow-y-auto pr-4 space-y-5">

          <!-- Info Grid -->
      <div class="grid grid-cols-2 gap-4">
        <!-- Template -->
        <div
          v-if="templateName"
          class="flex flex-col gap-1.5 p-3 rounded-xl bg-n-alpha-1"
        >
          <div class="flex items-center gap-2">
            <Icon icon="i-lucide-file-text" class="size-4 text-n-slate-10" />
            <span
              class="text-xs font-medium text-n-slate-11 uppercase tracking-wide"
            >
              {{ t('CAMPAIGN.DETAILS.TEMPLATE') }}
            </span>
          </div>
          <span class="text-sm font-medium text-n-slate-12 capitalize">
            {{ templateName }}
          </span>
        </div>

        <!-- Language -->
        <div
          v-if="templateParams?.language"
          class="flex flex-col gap-1.5 p-3 rounded-xl bg-n-alpha-1"
        >
          <div class="flex items-center gap-2">
            <Icon icon="i-lucide-globe" class="size-4 text-n-slate-10" />
            <span
              class="text-xs font-medium text-n-slate-11 uppercase tracking-wide"
            >
              {{ t('CAMPAIGN.DETAILS.LANGUAGE') }}
            </span>
          </div>
          <span class="text-sm font-medium text-n-slate-12">
            {{ templateParams.language }}
          </span>
        </div>

        <!-- Inbox -->
        <div
          v-if="campaign?.inbox"
          class="flex flex-col gap-1.5 p-3 rounded-xl bg-n-alpha-1"
        >
          <div class="flex items-center gap-2">
            <Icon icon="i-lucide-inbox" class="size-4 text-n-slate-10" />
            <span
              class="text-xs font-medium text-n-slate-11 uppercase tracking-wide"
            >
              {{ t('CAMPAIGN.DETAILS.INBOX') }}
            </span>
          </div>
          <span class="text-sm font-medium text-n-slate-12">
            {{ campaign.inbox.name }}
          </span>
        </div>

        <!-- Scheduled At -->
        <div
          v-if="campaign?.scheduled_at"
          class="flex flex-col gap-1.5 p-3 rounded-xl bg-n-alpha-1"
        >
          <div class="flex items-center gap-2">
            <Icon icon="i-lucide-calendar" class="size-4 text-n-slate-10" />
            <span
              class="text-xs font-medium text-n-slate-11 uppercase tracking-wide"
            >
              {{ t('CAMPAIGN.DETAILS.SCHEDULED_AT') }}
            </span>
          </div>
          <span class="text-sm font-medium text-n-slate-12">
            {{ formatDate(campaign.scheduled_at) }}
          </span>
        </div>
      </div>

      <!-- Audience Labels -->
      <div v-if="audienceLabels.length" class="flex flex-col gap-2">
        <div class="flex items-center gap-2">
          <Icon icon="i-lucide-users" class="size-4 text-n-slate-11" />
          <span
            class="text-xs font-medium text-n-slate-11 uppercase tracking-wide"
          >
            {{ t('CAMPAIGN.DETAILS.AUDIENCE') }}
          </span>
        </div>
        <div class="flex flex-wrap gap-2">
          <span
            v-for="label in audienceLabels"
            :key="label.id"
            class="inline-flex items-center gap-1.5 text-sm px-3 py-1.5 rounded-lg bg-n-alpha-2 text-n-slate-12 border border-n-weak"
          >
            <span
              class="size-2.5 rounded-full"
              :style="{ backgroundColor: label.color }"
            />
            {{ label.title }}
          </span>
        </div>
      </div>

      <!-- Template Variables -->
      <div v-if="templateVariables.length" class="flex flex-col gap-2">
        <div class="flex items-center gap-2">
          <Icon icon="i-lucide-variable" class="size-4 text-n-slate-11" />
          <span
            class="text-xs font-medium text-n-slate-11 uppercase tracking-wide"
          >
            {{ t('CAMPAIGN.DETAILS.TEMPLATE_PARAMS') }}
          </span>
        </div>
        <div
          class="flex flex-col gap-2 p-3 rounded-xl bg-n-alpha-1 border border-n-weak"
        >
          <div
            v-for="(variable, idx) in templateVariables"
            :key="idx"
            class="flex items-start gap-3 text-sm"
          >
            <span
              class="text-n-slate-11 font-mono text-xs px-1.5 py-0.5 rounded bg-n-alpha-2 whitespace-nowrap"
            >
              {{ variable.section }} {{ variable.index }}
            </span>
            <span
              v-if="variable.type === 'image'"
              class="text-n-blue-11 break-all"
            >
              {{ variable.value }}
            </span>
            <span v-else class="text-n-slate-12 break-all">
              {{ variable.value }}
            </span>
          </div>
        </div>
      </div>

      <!-- Delivery Report Section -->
      <div
        v-if="hasDeliveryReport"
        class="flex flex-col gap-4 pt-4 border-t border-n-weak"
      >
        <div class="flex items-center gap-2">
          <Icon icon="i-lucide-bar-chart-2" class="size-4 text-n-slate-11" />
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.DELIVERY_REPORT.TITLE') }}
          </span>
        </div>

        <!-- Stats Cards -->
        <div class="grid grid-cols-3 gap-3">
          <div
            class="flex flex-col items-center gap-1 p-4 rounded-xl bg-n-alpha-2 border border-n-weak"
          >
            <span class="text-3xl font-bold text-n-slate-12">
              {{ deliveryReport.total }}
            </span>
            <span class="text-xs text-n-slate-11 uppercase tracking-wide">
              {{ t('CAMPAIGN.DELIVERY_REPORT.TOTAL') }}
            </span>
          </div>
          <div
            class="flex flex-col items-center gap-1 p-4 rounded-xl bg-n-teal-2 border border-n-teal-6"
          >
            <span class="text-3xl font-bold text-n-teal-11">
              {{ deliveryReport.succeeded }}
            </span>
            <span class="text-xs text-n-teal-11 uppercase tracking-wide">
              {{ t('CAMPAIGN.DELIVERY_REPORT.SUCCEEDED') }}
            </span>
          </div>
          <div
            class="flex flex-col items-center gap-1 p-4 rounded-xl bg-n-ruby-2 border border-n-ruby-6"
          >
            <span class="text-3xl font-bold text-n-ruby-11">
              {{ deliveryReport.failed }}
            </span>
            <span class="text-xs text-n-ruby-11 uppercase tracking-wide">
              {{ t('CAMPAIGN.DELIVERY_REPORT.FAILED') }}
            </span>
          </div>
        </div>

        <!-- Timestamps -->
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div class="flex flex-col gap-1">
            <span class="text-xs text-n-slate-11 uppercase tracking-wide">
              {{ t('CAMPAIGN.DELIVERY_REPORT.STARTED_AT') }}
            </span>
            <span class="text-n-slate-12 font-medium">
              {{ formatDate(deliveryReport.started_at) }}
            </span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-n-slate-11 uppercase tracking-wide">
              {{ t('CAMPAIGN.DELIVERY_REPORT.COMPLETED_AT') }}
            </span>
            <span class="text-n-slate-12 font-medium">
              {{ formatDate(deliveryReport.completed_at) }}
            </span>
          </div>
        </div>

        <!-- Errors Section -->
        <div v-if="hasErrors" class="flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <Icon
              icon="i-lucide-alert-triangle"
              class="size-4 text-n-ruby-11"
            />
            <span class="text-sm font-medium text-n-ruby-11">
              {{ t('CAMPAIGN.DELIVERY_REPORT.ERRORS_TITLE') }}
            </span>
          </div>
          <div class="flex flex-col gap-1.5 max-h-40 overflow-y-auto">
            <div
              v-for="(error, index) in deliveryReport.errors"
              :key="index"
              class="flex items-center gap-2 px-3 py-2 rounded-lg bg-n-ruby-2 border border-n-ruby-6"
            >
              <span
                v-if="error.code"
                class="text-[10px] font-mono px-1.5 py-0.5 rounded bg-n-ruby-4 text-n-ruby-11 shrink-0"
              >
                {{ error.code }}
              </span>
              <div class="flex-1 min-w-0">
                <span class="text-xs text-n-slate-12 font-medium">
                  {{ error.message }}
                </span>
                <span v-if="error.details" class="text-xs text-n-slate-11 ml-1">
                  {{
                    $t('CAMPAIGN.DELIVERY_REPORT.ERROR_DETAILS_SEPARATOR', {
                      details: error.details,
                    })
                  }}
                </span>
              </div>
              <span
                class="text-[10px] text-n-ruby-11 bg-n-ruby-3 px-1.5 py-0.5 rounded shrink-0"
              >
                {{
                  $t('CAMPAIGN.DELIVERY_REPORT.ERROR_COUNT', {
                    count: error.count,
                  })
                }}
              </span>
            </div>
          </div>
        </div>
        </div>
        </div>

        <!-- Right Panel: WhatsApp Preview -->
        <div class="w-[360px] flex-shrink-0 overflow-y-auto">
          <div>
            <div class="flex items-center gap-2 mb-4">
              <Icon icon="i-lucide-smartphone" class="size-4 text-n-slate-11" />
              <span
                class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide"
              >
                {{ t('CAMPAIGN.WHATSAPP.CREATE_DIALOG.PREVIEW_TITLE') }}
              </span>
            </div>
            <TemplatePreview
              :header-format="previewProps.headerFormat"
              :header-text="previewProps.headerText"
              :header-text-example="previewProps.headerTextExample"
              :header-media-url="previewProps.headerMediaUrl"
              :header-media-name="previewProps.headerMediaName"
              :body-text="previewProps.bodyText"
              :body-examples="previewProps.bodyExamples"
              :footer-text="previewProps.footerText"
              :buttons="previewProps.buttons"
            />
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex-shrink-0 flex justify-end gap-3 px-6 py-4 border-t border-n-weak">
        <Button
          variant="faded"
          color="slate"
          :label="t('CAMPAIGN.DETAILS.CLOSE')"
          @click="handleClose"
        />
      </div>
    </div>
  </Dialog>
</template>
