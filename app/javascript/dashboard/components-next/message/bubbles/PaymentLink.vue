<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseBubble from 'next/message/bubbles/Base.vue';
import BaseAttachmentBubble from './BaseAttachment.vue';
import { useMessageContext } from '../provider.js';
import { usePaymentLinkStatus } from 'dashboard/composables/usePaymentLinkStatus';

const { contentAttributes, isBotOrAgentMessage, content } = useMessageContext();
const { t } = useI18n();

const data = computed(() => contentAttributes.value?.data || {});

const paymentUrl = computed(() => data.value?.payment_url);
const amount = computed(() => data.value?.amount);
const currency = computed(() => data.value?.currency || 'KWD');
const status = computed(() => data.value?.status || 'pending');

// Smart format: show decimals only when needed
const formattedAmount = computed(() => {
  const amt = parseFloat(amount.value);
  if (Number.isNaN(amt)) return '0';
  // Remove unnecessary trailing zeros
  return amt.toString();
});

const { iconName, iconBgColor, labelKey, statusBadgeBg, statusBadgeText } =
  usePaymentLinkStatus(status);

const action = computed(() => {
  if (!paymentUrl.value) return null;

  return {
    label: t('PAYMENT_LINK.VIEW_PAYMENT_PAGE'),
    href: paymentUrl.value,
  };
});

// Amount display for title
const amountDisplay = computed(() => {
  return `${formattedAmount.value} ${currency.value}`;
});
</script>

<template>
  <!-- Agent View: Rich Card using BaseAttachmentBubble -->
  <BaseAttachmentBubble
    v-if="isBotOrAgentMessage"
    icon="i-lucide-credit-card"
    :icon-bg-color="iconBgColor"
    sender-translation-key="PAYMENT_LINK.SENDER_MESSAGE"
    :title="amountDisplay"
    :action="action"
  >
    <template #default>
      <div class="space-y-2">
        <div class="text-sm text-n-slate-12 font-medium">
          {{ amountDisplay }}
        </div>
        <div
          class="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium"
          :class="[statusBadgeBg, statusBadgeText]"
        >
          <span :class="iconName" class="text-sm" />
          <span>{{ $t(labelKey) }}</span>
        </div>
      </div>
    </template>
  </BaseAttachmentBubble>

  <!-- Customer View: Simple Text Message -->
  <BaseBubble v-else>
    <div class="space-y-2">
      <p class="text-sm">{{ content }}</p>
      <a
        v-if="paymentUrl"
        :href="paymentUrl"
        target="_blank"
        rel="noopener noreferrer"
        class="inline-flex items-center gap-2 text-sm font-medium text-n-iris-9 hover:text-n-iris-10"
      >
        <span>{{ $t('PAYMENT_LINK.PAY_NOW') }}</span>
        <span class="i-lucide-external-link text-base" />
      </a>
    </div>
  </BaseBubble>
</template>
