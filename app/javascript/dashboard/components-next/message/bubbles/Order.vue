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

const senderName = computed(() => sender?.value?.name || '');
const data = computed(() => contentAttributes.value?.data || {});

const paymentUrl = computed(
  () => data.value?.payment_url || data.value?.paymentUrl
);
const previewUrl = computed(
  () => data.value?.preview_url || data.value?.previewUrl
);
const total = computed(() => data.value?.total);
const currency = computed(() => data.value?.currency || 'KWD');
const status = computed(() => data.value?.status || 'pending');
const externalPaymentId = computed(
  () => data.value?.external_payment_id || data.value?.externalPaymentId
);
const items = computed(() => data.value?.items || []);

const { iconName, iconBgColor, labelKey, statusBadgeBg, statusBadgeText } =
  usePaymentLinkStatus(status);

const formattedTotal = computed(() => {
  const amt = parseFloat(total.value);
  if (Number.isNaN(amt)) return '0';
  return amt.toFixed(2);
});

const totalDisplay = computed(
  () => `${formattedTotal.value} ${currency.value}`
);

const copyPaymentLink = async () => {
  const urlToCopy = previewUrl.value || paymentUrl.value;
  if (!urlToCopy) return;

  try {
    await navigator.clipboard.writeText(urlToCopy);
    useAlert(t('ORDER.LINK_COPIED'));
  } catch (error) {
    const textArea = document.createElement('textarea');
    textArea.value = urlToCopy;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try {
      document.execCommand('copy');
      useAlert(t('ORDER.LINK_COPIED'));
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('Failed to copy payment link:', err);
    }
    document.body.removeChild(textArea);
  }
};

const formatPrice = price => {
  const amt = parseFloat(price);
  if (Number.isNaN(amt)) return '0';
  return amt.toFixed(2);
};
</script>

<template>
  <!-- Agent View: Rich Card with itemized invoice -->
  <BaseBubble
    v-if="isBotOrAgentMessage"
    class="overflow-hidden !p-0"
    data-bubble-name="order"
  >
    <div class="min-w-72 mb-1">
      <!-- Header -->
      <div class="flex items-center gap-3 p-3 border-b border-n-alpha-3">
        <div
          class="size-8 rounded-lg grid place-content-center flex-shrink-0"
          :class="iconBgColor"
        >
          <Icon icon="i-lucide-shopping-cart" class="text-white size-4" />
        </div>
        <div class="font-medium text-n-slate-12">
          {{ $t('ORDER.INVOICE_TITLE') }}
        </div>
      </div>

      <!-- Items List -->
      <div class="p-3 space-y-2 max-h-48 overflow-y-auto">
        <div
          v-for="(item, index) in items"
          :key="index"
          class="flex justify-between items-center text-xs"
        >
          <div class="flex-1">
            <span class="text-n-slate-12">{{
              item.title_en || item.titleEn
            }}</span>
            <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
            <span class="text-n-slate-11 ml-1">x{{ item.quantity }}</span>
          </div>
          <span class="text-n-slate-12 font-medium">
            {{ formatPrice(item.total_price || item.totalPrice) }}
          </span>
        </div>
      </div>

      <!-- Total Section -->
      <div class="px-3 py-2 border-t border-n-alpha-3 bg-n-alpha-1">
        <div class="flex justify-between items-center">
          <span class="text-sm font-medium text-n-slate-11">{{
            $t('ORDER.TOTAL')
          }}</span>
          <span class="text-sm font-semibold text-n-slate-12">{{
            totalDisplay
          }}</span>
        </div>
      </div>

      <!-- Info Section -->
      <div class="p-3 space-y-2 border-t border-n-alpha-3">
        <div class="flex gap-2">
          <span class="text-xs text-n-slate-11 font-medium min-w-fit"
            >{{ $t('ORDER.PAYMENT_ID') }}:</span
          >
          <span class="text-xs text-n-slate-12 font-mono">{{
            externalPaymentId
          }}</span>
        </div>
        <div class="flex gap-2">
          <span class="text-xs text-n-slate-11 font-medium min-w-fit"
            >{{ $t('ORDER.SENDER') }}:</span
          >
          <span class="text-xs text-n-slate-12">{{ senderName }}</span>
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
          v-if="previewUrl || paymentUrl"
          type="button"
          class="inline-flex items-center gap-1.5 px-2 py-1 text-xs font-medium text-n-iris-9 hover:text-n-iris-10 hover:bg-n-iris-3 rounded-md transition-colors"
          @click="copyPaymentLink"
        >
          <span class="i-lucide-copy text-sm" />
          <span>{{ $t('ORDER.COPY_LINK') }}</span>
        </button>
      </div>
    </div>
  </BaseBubble>

  <!-- Customer View: Simple Text Message -->
  <BaseBubble v-else>
    <div class="space-y-2">
      <p class="text-sm whitespace-pre-wrap">{{ content }}</p>
      <a
        v-if="previewUrl || paymentUrl"
        :href="previewUrl || paymentUrl"
        target="_blank"
        rel="noopener noreferrer"
        class="inline-flex items-center gap-2 text-sm font-medium text-n-iris-9 hover:text-n-iris-10"
      >
        <span>{{ $t('ORDER.PAY_NOW') }}</span>
        <span class="i-lucide-external-link text-base" />
      </a>
    </div>
  </BaseBubble>
</template>
