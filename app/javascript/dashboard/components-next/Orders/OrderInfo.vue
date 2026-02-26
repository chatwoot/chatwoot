<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { format } from 'date-fns';
import { usePaymentLinkStatus } from 'dashboard/composables/usePaymentLinkStatus';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  order: {
    type: Object,
    required: true,
  },
});

const router = useRouter();

const statusBadge = computed(() => {
  const { statusBadgeBg, statusBadgeText, iconName } = usePaymentLinkStatus(
    props.order.status
  );
  return {
    bg: statusBadgeBg.value,
    text: statusBadgeText.value,
    icon: iconName.value,
  };
});

const formatDate = dateString => {
  if (!dateString) return '-';
  return format(new Date(dateString), 'MMM d, yyyy h:mm a');
};

const formatAddress = address => {
  if (!address || typeof address !== 'object') return '';
  return ['street', 'city', 'state', 'postal_code', 'country']
    .map(key => address[key])
    .filter(Boolean)
    .join(', ');
};

const hasDeliveryAddress = computed(
  () => !!formatAddress(props.order.delivery_address)
);

const copyToClipboard = async url => {
  try {
    await navigator.clipboard.writeText(url);
  } catch {
    // Failed to copy
  }
};

const openPaymentLink = url => {
  window.open(url, '_blank', 'noopener,noreferrer');
};

const navigateToContact = () => {
  if (!props.order.contact?.id) return;
  router.push({
    name: 'contact_profile',
    params: {
      accountId: router.currentRoute.value.params.accountId,
      id: props.order.contact.id,
    },
  });
};

const navigateToConversation = () => {
  if (!props.order.conversation?.display_id) return;
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: router.currentRoute.value.params.accountId,
      conversation_id: props.order.conversation.display_id,
    },
  });
};
</script>

<template>
  <div class="flex flex-col gap-6">
    <!-- Status + Actions Header -->
    <div class="flex items-center justify-between">
      <span
        class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium"
        :class="[statusBadge.bg, statusBadge.text]"
      >
        <Icon :icon="statusBadge.icon" class="text-sm" />
        <span>{{
          $t(`ORDERS_LIST.STATUS.${order.status.toUpperCase()}`)
        }}</span>
      </span>
      <div class="flex items-center gap-2">
        <Button
          v-if="order.preview_url"
          v-tooltip.top="$t('ORDER_DETAILS.INFO.COPY_URL')"
          icon="i-lucide-copy"
          slate
          xs
          faded
          @click="copyToClipboard(order.preview_url)"
        />
        <Button
          v-if="order.preview_url"
          v-tooltip.top="$t('ORDER_DETAILS.INFO.VIEW_PAYMENT')"
          icon="i-lucide-external-link"
          slate
          xs
          faded
          @click="openPaymentLink(order.preview_url)"
        />
      </div>
    </div>

    <!-- Info Grid -->
    <div class="grid grid-cols-2 gap-4">
      <div>
        <span class="text-xs text-n-slate-11">{{
          $t('ORDER_DETAILS.INFO.ORDER_ID')
        }}</span>
        <p class="text-sm font-medium text-n-slate-12">
          {{ order.external_payment_id }}
        </p>
      </div>
      <div>
        <span class="text-xs text-n-slate-11">{{
          $t('ORDER_DETAILS.INFO.TOTAL')
        }}</span>
        <p class="text-sm font-medium text-n-slate-12">
          {{ order.total }} {{ order.currency }}
        </p>
      </div>
      <div>
        <span class="text-xs text-n-slate-11">{{
          $t('ORDER_DETAILS.INFO.CONTACT')
        }}</span>
        <p class="text-sm">
          <button
            v-if="order.contact"
            class="text-n-iris-9 hover:text-n-iris-10 hover:underline font-medium"
            @click="navigateToContact"
          >
            {{
              order.contact.name ||
              order.contact.email ||
              order.contact.phone_number
            }}
          </button>
          <span v-else class="text-n-slate-11">-</span>
        </p>
      </div>
      <div>
        <span class="text-xs text-n-slate-11">{{
          $t('ORDER_DETAILS.INFO.CONVERSATION')
        }}</span>
        <p class="text-sm">
          <button
            v-if="order.conversation"
            class="text-n-iris-9 hover:text-n-iris-10 hover:underline font-medium"
            @click="navigateToConversation"
          >
            #{{ order.conversation.display_id }}
          </button>
          <span v-else class="text-n-slate-11">-</span>
        </p>
      </div>
      <div>
        <span class="text-xs text-n-slate-11">{{
          $t('ORDER_DETAILS.INFO.CREATED_BY')
        }}</span>
        <p class="text-sm text-n-slate-12">
          {{ order.created_by?.name || '-' }}
        </p>
      </div>
      <div>
        <span class="text-xs text-n-slate-11">{{
          $t('ORDER_DETAILS.INFO.PROVIDER')
        }}</span>
        <p class="text-sm text-n-slate-12 capitalize">
          {{ order.provider || '-' }}
        </p>
      </div>
    </div>

    <!-- Items Table -->
    <div v-if="order.items?.length" class="flex flex-col gap-2">
      <h3 class="text-sm font-semibold text-n-slate-12">
        {{ $t('ORDER_DETAILS.INFO.ITEMS') }}
      </h3>
      <table class="min-w-full">
        <thead>
          <tr class="text-xs text-n-slate-11 border-b border-n-weak">
            <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
              {{ $t('ORDER_DETAILS.INFO.PRODUCT') }}
            </th>
            <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
              {{ $t('ORDER_DETAILS.INFO.QUANTITY') }}
            </th>
            <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
              {{ $t('ORDER_DETAILS.INFO.UNIT_PRICE') }}
            </th>
            <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
              {{ $t('ORDER_DETAILS.INFO.ITEM_TOTAL') }}
            </th>
          </tr>
        </thead>
        <tbody class="text-sm text-n-slate-12">
          <tr
            v-for="item in order.items"
            :key="item.id"
            class="border-b border-n-weak last:border-b-0"
          >
            <td class="py-2 ltr:pr-4 rtl:pl-4">
              {{ item.product?.title_en || '-' }}
            </td>
            <td class="py-2 ltr:pr-4 rtl:pl-4">{{ item.quantity }}</td>
            <td class="py-2 ltr:pr-4 rtl:pl-4">
              {{ item.unit_price }} {{ order.currency }}
            </td>
            <td class="py-2 ltr:pr-4 rtl:pl-4">
              {{ item.total_price }} {{ order.currency }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Delivery Address -->
    <div v-if="hasDeliveryAddress" class="flex flex-col gap-2">
      <h3 class="text-sm font-semibold text-n-slate-12">
        {{ $t('ORDER_DETAILS.INFO.DELIVERY_ADDRESS') }}
      </h3>
      <div class="flex items-start gap-2 text-sm text-n-slate-12">
        <Icon icon="i-lucide-map-pin" class="text-n-slate-11 mt-0.5" />
        <span>{{ formatAddress(order.delivery_address) }}</span>
      </div>
    </div>

    <!-- Simple Timeline -->
    <div class="flex flex-col gap-2">
      <h3 class="text-sm font-semibold text-n-slate-12">
        {{ $t('ORDER_DETAILS.TIMELINE.TITLE') }}
      </h3>
      <div class="flex flex-col gap-3 ltr:ml-2 rtl:mr-2">
        <!-- Created -->
        <div class="flex items-center gap-3">
          <div class="size-2.5 rounded-full bg-n-slate-9 shrink-0" />
          <div class="flex items-center gap-2 text-sm">
            <span class="text-n-slate-12">{{
              $t('ORDER_DETAILS.TIMELINE.CREATED')
            }}</span>
            <span class="text-n-slate-11">{{
              formatDate(order.created_at)
            }}</span>
          </div>
        </div>
        <!-- Paid -->
        <div v-if="order.paid_at" class="flex items-center gap-3">
          <div class="size-2.5 rounded-full bg-n-teal-9 shrink-0" />
          <div class="flex items-center gap-2 text-sm">
            <span class="text-n-slate-12">{{
              $t('ORDER_DETAILS.TIMELINE.PAID')
            }}</span>
            <span class="text-n-slate-11">
              {{ formatDate(order.paid_at) }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
