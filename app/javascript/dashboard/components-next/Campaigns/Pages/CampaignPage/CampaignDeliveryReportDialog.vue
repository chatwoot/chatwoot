<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { messageStamp } from 'shared/helpers/timeHelper';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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

const deliveryReport = computed(() => props.campaign?.delivery_report);

const hasErrors = computed(() => deliveryReport.value?.errors?.length > 0);

const statusColor = computed(() => {
  const status = deliveryReport.value?.status;
  if (status === 'completed') return 'text-n-teal-11';
  if (status === 'completed_with_errors') return 'text-n-ruby-11';
  return 'text-n-slate-11';
});

const formatDate = timestamp => {
  if (!timestamp) return '-';
  return messageStamp(new Date(timestamp), 'LLL d, h:mm a');
};

const handleClose = () => emit('close');
</script>

<template>
  <Dialog :show="isOpen" @close="handleClose">
    <div class="flex flex-col gap-6 p-6 w-[32rem]">
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-medium text-n-slate-12">
          {{ t('CAMPAIGN.DELIVERY_REPORT.TITLE') }}
        </h3>
        <button class="p-1 rounded-md hover:bg-n-alpha-2" @click="handleClose">
          <Icon icon="i-lucide-x" class="size-5 text-n-slate-11" />
        </button>
      </div>

      <div v-if="campaign" class="flex flex-col gap-4">
        <!-- Campaign Title -->
        <div class="text-sm font-medium text-n-slate-12">
          {{ campaign.title }}
        </div>

        <!-- Delivery Stats -->
        <div
          v-if="deliveryReport"
          class="grid grid-cols-2 gap-4 p-4 rounded-lg bg-n-alpha-2"
        >
          <div class="flex flex-col gap-1">
            <span class="text-xs text-n-slate-11">
              {{ t('CAMPAIGN.DELIVERY_REPORT.STATUS') }}
            </span>
            <span class="text-sm font-medium capitalize" :class="statusColor">
              {{ deliveryReport.status?.replace(/_/g, ' ') }}
            </span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-n-slate-11">
              {{ t('CAMPAIGN.DELIVERY_REPORT.TOTAL') }}
            </span>
            <span class="text-sm font-medium text-n-slate-12">
              {{ deliveryReport.total }}
            </span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-n-slate-11">
              {{ t('CAMPAIGN.DELIVERY_REPORT.SUCCEEDED') }}
            </span>
            <span class="text-sm font-medium text-n-teal-11">
              {{ deliveryReport.succeeded }}
            </span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-n-slate-11">
              {{ t('CAMPAIGN.DELIVERY_REPORT.FAILED') }}
            </span>
            <span class="text-sm font-medium text-n-ruby-11">
              {{ deliveryReport.failed }}
            </span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-n-slate-11">
              {{ t('CAMPAIGN.DELIVERY_REPORT.STARTED_AT') }}
            </span>
            <span class="text-sm font-medium text-n-slate-12">
              {{ formatDate(deliveryReport.started_at) }}
            </span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-n-slate-11">
              {{ t('CAMPAIGN.DELIVERY_REPORT.COMPLETED_AT') }}
            </span>
            <span class="text-sm font-medium text-n-slate-12">
              {{ formatDate(deliveryReport.completed_at) }}
            </span>
          </div>
        </div>

        <!-- Errors Section -->
        <div v-if="hasErrors" class="flex flex-col gap-3">
          <h4 class="text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.DELIVERY_REPORT.ERRORS_TITLE') }}
          </h4>
          <div class="flex flex-col gap-2 max-h-60 overflow-y-auto">
            <div
              v-for="(error, index) in deliveryReport.errors"
              :key="index"
              class="p-3 rounded-lg bg-n-ruby-3 border border-n-ruby-6"
            >
              <div class="flex items-start justify-between gap-2">
                <div class="flex flex-col gap-1 min-w-0 flex-1">
                  <div class="flex items-center gap-2">
                    <span
                      v-if="error.code"
                      class="text-xs font-mono px-1.5 py-0.5 rounded bg-n-ruby-5 text-n-ruby-11"
                    >
                      {{ error.code }}
                    </span>
                    <span class="text-xs text-n-ruby-11">
                      {{
                        t('CAMPAIGN.DELIVERY_REPORT.ERROR_COUNT', {
                          count: error.count,
                        })
                      }}
                    </span>
                  </div>
                  <p class="text-sm text-n-slate-12 break-words">
                    {{ error.message }}
                  </p>
                  <p
                    v-if="error.details"
                    class="text-xs text-n-slate-11 break-words"
                  >
                    {{ error.details }}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div
          v-else-if="deliveryReport && deliveryReport.failed === 0"
          class="text-sm text-n-slate-11 text-center py-4"
        >
          {{ t('CAMPAIGN.DELIVERY_REPORT.NO_ERRORS') }}
        </div>
      </div>

      <div class="flex justify-end">
        <Button
          variant="faded"
          color="slate"
          :label="t('CAMPAIGN.DELIVERY_REPORT.CLOSE')"
          @click="handleClose"
        />
      </div>
    </div>
  </Dialog>
</template>
