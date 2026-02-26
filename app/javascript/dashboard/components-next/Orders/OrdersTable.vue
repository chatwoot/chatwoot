<script setup>
import { ref } from 'vue';
import { format } from 'date-fns';
import { useRouter } from 'vue-router';
import { usePaymentLinkStatus } from 'dashboard/composables/usePaymentLinkStatus';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  orders: { type: Array, required: true },
  noRecordsFound: { type: Boolean, default: false },
  searchValue: { type: String, default: '' },
});

const router = useRouter();
const expandedRows = ref(new Set());

const toggleExpand = orderId => {
  const newSet = new Set(expandedRows.value);
  if (newSet.has(orderId)) {
    newSet.delete(orderId);
  } else {
    newSet.add(orderId);
  }
  expandedRows.value = newSet;
};

const isExpanded = orderId => expandedRows.value.has(orderId);

const formatDate = dateString => {
  if (!dateString) return '-';
  return format(new Date(dateString), 'MMM d, yyyy h:mm a');
};

const copyToClipboard = async url => {
  try {
    await navigator.clipboard.writeText(url);
  } catch (err) {
    // Failed to copy
  }
};

const navigateToConversation = (accountId, conversationId) => {
  router.push({
    name: 'inbox_conversation',
    params: { accountId, conversation_id: conversationId },
  });
};

const navigateToContact = (accountId, contactId) => {
  router.push({
    name: 'contact_profile',
    params: { accountId, id: contactId },
  });
};

const navigateToOrder = orderId => {
  router.push({
    name: 'orders_show',
    params: {
      accountId: router.currentRoute.value.params.accountId,
      orderId,
    },
  });
};

const openPaymentLink = url => {
  window.open(url, '_blank', 'noopener,noreferrer');
};

const formatAddress = address => {
  if (!address || typeof address !== 'object') return '';
  return ['street', 'city', 'state', 'postal_code', 'country']
    .map(key => address[key])
    .filter(Boolean)
    .join(', ');
};

const getStatusBadgeClasses = status => {
  const { statusBadgeBg, statusBadgeText, iconName } =
    usePaymentLinkStatus(status);
  return {
    bg: statusBadgeBg.value,
    text: statusBadgeText.value,
    icon: iconName.value,
  };
};
</script>

<template>
  <table
    v-show="!noRecordsFound || searchValue"
    class="min-w-full divide-y divide-n-weak"
  >
    <thead>
      <tr>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('ORDERS_LIST.TABLE.ORDER_ID') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('ORDERS_LIST.TABLE.CONTACT') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('ORDERS_LIST.TABLE.ITEMS') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('ORDERS_LIST.TABLE.TOTAL') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('ORDERS_LIST.TABLE.STATUS') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('ORDERS_LIST.TABLE.CREATED_BY') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('ORDERS_LIST.TABLE.CONVERSATION') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('ORDERS_LIST.TABLE.ACTIONS') }}
        </th>
      </tr>
    </thead>
    <tbody class="divide-y divide-n-weak text-n-slate-12">
      <!-- Empty State Row -->
      <tr v-if="noRecordsFound && searchValue">
        <td colspan="8" class="py-10 text-center">
          <span class="text-base text-n-slate-11">
            {{ $t('ORDERS_LIST.TABLE.NO_RESULTS_SEARCH') }}
          </span>
        </td>
      </tr>
      <template v-for="order in orders" :key="order.id">
        <tr
          class="cursor-pointer hover:bg-n-alpha-1 transition-colors"
          @click="navigateToOrder(order.id)"
        >
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <div class="flex flex-col gap-0.5">
              <span class="font-medium">{{ order.external_payment_id }}</span>
              <span class="text-xs text-n-slate-11">{{
                formatDate(order.created_at)
              }}</span>
            </div>
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <button
              v-if="order.contact"
              class="text-n-iris-9 hover:text-n-iris-10 hover:underline"
              @click.stop="
                navigateToContact(
                  $store.state.auth.currentAccountId,
                  order.contact.id
                )
              "
            >
              {{
                order.contact.name ||
                order.contact.email ||
                order.contact.phone_number
              }}
            </button>
            <span v-else class="text-n-slate-11">-</span>
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <button
              v-if="order.items_count > 0"
              class="flex items-center gap-1.5 text-n-slate-11 hover:text-n-slate-12 transition-colors"
              @click.stop="toggleExpand(order.id)"
            >
              <Icon
                icon="i-lucide-chevron-right"
                class="text-sm transition-transform"
                :class="{ 'rotate-90': isExpanded(order.id) }"
              />
              <span>
                {{ order.items_count }}
                {{
                  order.items_count === 1
                    ? $t('ORDERS_LIST.TABLE.ITEM')
                    : $t('ORDERS_LIST.TABLE.ITEMS_COUNT')
                }}
              </span>
            </button>
            <span v-else class="text-n-slate-11">-</span>
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4 font-medium">
            {{ order.total }} {{ order.currency }}
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <span
              class="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium"
              :class="[
                getStatusBadgeClasses(order.status).bg,
                getStatusBadgeClasses(order.status).text,
              ]"
            >
              <Icon
                :icon="getStatusBadgeClasses(order.status).icon"
                class="text-sm"
              />
              <span>{{
                $t(`ORDERS_LIST.STATUS.${order.status.toUpperCase()}`)
              }}</span>
            </span>
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4 text-n-slate-11">
            {{ order.created_by?.name || '-' }}
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <button
              v-if="order.conversation"
              class="text-n-iris-9 hover:text-n-iris-10 hover:underline"
              @click.stop="
                navigateToConversation(
                  $store.state.auth.currentAccountId,
                  order.conversation.display_id
                )
              "
            >
              #{{ order.conversation.display_id }}
            </button>
            <span v-else class="text-n-slate-11">-</span>
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <div class="flex items-center gap-2" @click.stop>
              <Button
                v-if="order.preview_url"
                v-tooltip.top="$t('ORDERS_LIST.TABLE.COPY_URL')"
                icon="i-lucide-copy"
                slate
                xs
                faded
                @click="copyToClipboard(order.preview_url)"
              />
              <Button
                v-if="order.preview_url"
                v-tooltip.top="$t('ORDERS_LIST.TABLE.VIEW_PAYMENT')"
                icon="i-lucide-external-link"
                slate
                xs
                faded
                @click="openPaymentLink(order.preview_url)"
              />
            </div>
          </td>
        </tr>
        <!-- Expanded Items Row -->
        <tr v-if="isExpanded(order.id)" class="bg-n-alpha-1">
          <td colspan="8" class="py-4 px-4">
            <div class="ltr:ml-4 rtl:mr-4">
              <table class="min-w-full">
                <thead>
                  <tr class="text-xs text-n-slate-11">
                    <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
                      {{ $t('ORDERS_LIST.TABLE.EXPANDED_ITEMS.PRODUCT') }}
                    </th>
                    <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
                      {{ $t('ORDERS_LIST.TABLE.EXPANDED_ITEMS.QUANTITY') }}
                    </th>
                    <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
                      {{ $t('ORDERS_LIST.TABLE.EXPANDED_ITEMS.UNIT_PRICE') }}
                    </th>
                    <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
                      {{ $t('ORDERS_LIST.TABLE.EXPANDED_ITEMS.TOTAL') }}
                    </th>
                  </tr>
                </thead>
                <tbody class="text-sm text-n-slate-12">
                  <tr v-for="item in order.items" :key="item.id">
                    <td class="py-2 ltr:pr-4 rtl:pl-4">
                      {{ item.product?.title_en || '-' }}
                    </td>
                    <td class="py-2 ltr:pr-4 rtl:pl-4">
                      {{ item.quantity }}
                    </td>
                    <td class="py-2 ltr:pr-4 rtl:pl-4">
                      {{ item.unit_price }} {{ order.currency }}
                    </td>
                    <td class="py-2 ltr:pr-4 rtl:pl-4">
                      {{ item.total_price }} {{ order.currency }}
                    </td>
                  </tr>
                </tbody>
              </table>
              <div
                v-if="formatAddress(order.delivery_address)"
                class="mt-3 flex items-start gap-2 text-sm text-n-slate-11"
              >
                <Icon icon="i-lucide-map-pin" class="text-sm mt-0.5" />
                <div>
                  <span class="font-medium text-n-slate-12">
                    {{ $t('ORDERS_LIST.TABLE.DELIVERY_ADDRESS') }}:
                  </span>
                  {{ formatAddress(order.delivery_address) }}
                </div>
              </div>
            </div>
          </td>
        </tr>
      </template>
    </tbody>
  </table>
</template>
