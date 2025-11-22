<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseBubble from 'next/message/bubbles/Base.vue';
import Icon from 'next/icon/Icon.vue';
import { useMessageContext } from '../provider.js';
import { usePaymentLinkStatus } from 'dashboard/composables/usePaymentLinkStatus';
import { useAlert } from 'dashboard/composables';

const { contentAttributes, isBotOrAgentMessage, content, sender } =
  useMessageContext();
const { t } = useI18n();

const senderName = computed(() => {
  return sender?.value?.name || '';
});

const data = computed(() => contentAttributes.value?.data || {});

const paymentUrl = computed(() => data.value?.paymentUrl);
const amount = computed(() => data.value?.amount);
const currency = computed(() => data.value?.currency || 'KWD');
const status = computed(() => data.value?.status || 'pending');
const externalPaymentId = computed(() => data.value?.externalPaymentId);

// Smart format: show decimals only when needed
const formattedAmount = computed(() => {
  const amt = parseFloat(amount.value);
  if (Number.isNaN(amt)) return '0';
  // Remove unnecessary trailing zeros
  return amt.toString();
});

const { iconName, iconBgColor, labelKey, statusBadgeBg, statusBadgeText } =
  usePaymentLinkStatus(status);

// Amount display
const amountDisplay = computed(() => {
  return `${formattedAmount.value} ${currency.value}`;
});

// Copy link functionality
const copyPaymentLink = async () => {
  if (!paymentUrl.value) return;

  try {
    await navigator.clipboard.writeText(paymentUrl.value);
    useAlert(t('PAYMENT_LINK.LINK_COPIED'));
  } catch (error) {
    // Fallback for older browsers
    const textArea = document.createElement('textarea');
    textArea.value = paymentUrl.value;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try {
      document.execCommand('copy');
      useAlert(t('PAYMENT_LINK.LINK_COPIED'));
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('Failed to copy payment link:', err);
    }
    document.body.removeChild(textArea);
  }
};
</script>

<template>
  <!-- Agent View: Rich Card with payment details -->
  <BaseBubble
    v-if="isBotOrAgentMessage"
    class="overflow-hidden !p-0"
    data-bubble-name="payment-link"
  >
    <div class="min-w-64 mb-1">
      <!-- Header: Icon + Title -->
      <div class="flex items-center gap-3 p-3 border-b border-n-alpha-3">
        <div
          class="size-8 rounded-lg grid place-content-center flex-shrink-0"
          :class="iconBgColor"
        >
          <Icon icon="i-lucide-credit-card" class="text-white size-4" />
        </div>
        <div class="font-medium text-n-slate-12">
          {{ $t('PAYMENT_LINK.PAYMENT_REQUEST') }}
        </div>
      </div>

      <!-- Info Section: Payment ID, Sender, Amount -->
      <div class="p-3 space-y-2">
        <div class="flex gap-2">
          <span class="text-xs text-n-slate-11 font-medium min-w-fit"
            >{{ $t('PAYMENT_LINK.EXTERNAL_ID') }}:</span
          >
          <span class="text-xs text-n-slate-12 font-mono">{{
            externalPaymentId
          }}</span>
        </div>
        <div class="flex gap-2">
          <span class="text-xs text-n-slate-11 font-medium min-w-fit"
            >{{ $t('PAYMENT_LINK.SENDER') }}:</span
          >
          <span class="text-xs text-n-slate-12">{{ senderName }}</span>
        </div>
        <div class="flex gap-2">
          <span class="text-xs text-n-slate-11 font-medium min-w-fit"
            >{{ $t('PAYMENT_LINK.AMOUNT') }}:</span
          >
          <span class="text-xs text-n-slate-12 font-medium">{{
            amountDisplay
          }}</span>
        </div>
      </div>

      <!-- Footer: Status + Copy Button -->
      <div
        class="flex items-center justify-between p-3 border-t border-n-alpha-3"
      >
        <div
          class="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium"
          :class="[statusBadgeBg, statusBadgeText]"
        >
          <span :class="iconName" class="text-sm" />
          <span>{{ $t(labelKey) }}</span>
        </div>
        <button
          v-if="paymentUrl"
          type="button"
          class="inline-flex items-center gap-1.5 px-2 py-1 text-xs font-medium text-n-iris-9 hover:text-n-iris-10 hover:bg-n-iris-3 rounded-md transition-colors"
          @click="copyPaymentLink"
        >
          <span class="i-lucide-copy text-sm" />
          <span>{{ $t('PAYMENT_LINK.COPY_LINK') }}</span>
        </button>
      </div>
    </div>
  </BaseBubble>

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
