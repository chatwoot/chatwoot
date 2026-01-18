<script setup>
import { ref } from 'vue';
import { format } from 'date-fns';
import { useRouter } from 'vue-router';
import { usePaymentLinkStatus } from 'dashboard/composables/usePaymentLinkStatus';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  carts: { type: Array, required: true },
  noRecordsFound: { type: Boolean, default: false },
  searchValue: { type: String, default: '' },
});

const router = useRouter();
const expandedRows = ref(new Set());

const toggleExpand = cartId => {
  const newSet = new Set(expandedRows.value);
  if (newSet.has(cartId)) {
    newSet.delete(cartId);
  } else {
    newSet.add(cartId);
  }
  expandedRows.value = newSet;
};

const isExpanded = cartId => expandedRows.value.has(cartId);

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

const openPaymentLink = url => {
  window.open(url, '_blank', 'noopener,noreferrer');
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
          {{ $t('CARTS_LIST.TABLE.CART_ID') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('CARTS_LIST.TABLE.CONTACT') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('CARTS_LIST.TABLE.ITEMS') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('CARTS_LIST.TABLE.TOTAL') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('CARTS_LIST.TABLE.STATUS') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('CARTS_LIST.TABLE.CREATED_BY') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('CARTS_LIST.TABLE.CONVERSATION') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('CARTS_LIST.TABLE.ACTIONS') }}
        </th>
      </tr>
    </thead>
    <tbody class="divide-y divide-n-weak text-n-slate-12">
      <!-- Empty State Row -->
      <tr v-if="noRecordsFound && searchValue">
        <td colspan="8" class="py-10 text-center">
          <span class="text-base text-n-slate-11">
            {{ $t('CARTS_LIST.TABLE.NO_RESULTS_SEARCH') }}
          </span>
        </td>
      </tr>
      <template v-for="cart in carts" :key="cart.id">
        <tr>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <div class="flex flex-col gap-0.5">
              <span class="font-medium">{{ cart.external_payment_id }}</span>
              <span class="text-xs text-n-slate-11">{{
                formatDate(cart.created_at)
              }}</span>
            </div>
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <button
              v-if="cart.contact"
              class="text-n-iris-9 hover:text-n-iris-10 hover:underline"
              @click="
                navigateToContact(
                  $store.state.auth.currentAccountId,
                  cart.contact.id
                )
              "
            >
              {{
                cart.contact.name ||
                cart.contact.email ||
                cart.contact.phone_number
              }}
            </button>
            <span v-else class="text-n-slate-11">-</span>
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <button
              v-if="cart.items_count > 0"
              class="flex items-center gap-1.5 text-n-slate-11 hover:text-n-slate-12 transition-colors"
              @click="toggleExpand(cart.id)"
            >
              <Icon
                icon="i-lucide-chevron-right"
                class="text-sm transition-transform"
                :class="{ 'rotate-90': isExpanded(cart.id) }"
              />
              <span>
                {{ cart.items_count }}
                {{
                  cart.items_count === 1
                    ? $t('CARTS_LIST.TABLE.ITEM')
                    : $t('CARTS_LIST.TABLE.ITEMS_COUNT')
                }}
              </span>
            </button>
            <span v-else class="text-n-slate-11">-</span>
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4 font-medium">
            {{ cart.total }} {{ cart.currency }}
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <span
              class="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium"
              :class="[
                getStatusBadgeClasses(cart.status).bg,
                getStatusBadgeClasses(cart.status).text,
              ]"
            >
              <Icon
                :icon="getStatusBadgeClasses(cart.status).icon"
                class="text-sm"
              />
              <span>{{
                $t(`CARTS_LIST.STATUS.${cart.status.toUpperCase()}`)
              }}</span>
            </span>
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4 text-n-slate-11">
            {{ cart.created_by?.name || '-' }}
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <button
              v-if="cart.conversation"
              class="text-n-iris-9 hover:text-n-iris-10 hover:underline"
              @click="
                navigateToConversation(
                  $store.state.auth.currentAccountId,
                  cart.conversation.display_id
                )
              "
            >
              #{{ cart.conversation.display_id }}
            </button>
            <span v-else class="text-n-slate-11">-</span>
          </td>
          <td class="py-4 ltr:pr-4 rtl:pl-4">
            <div class="flex items-center gap-2">
              <Button
                v-if="cart.preview_url"
                v-tooltip.top="$t('CARTS_LIST.TABLE.COPY_URL')"
                icon="i-lucide-copy"
                slate
                xs
                faded
                @click="copyToClipboard(cart.preview_url)"
              />
              <Button
                v-if="cart.preview_url"
                v-tooltip.top="$t('CARTS_LIST.TABLE.VIEW_PAYMENT')"
                icon="i-lucide-external-link"
                slate
                xs
                faded
                @click="openPaymentLink(cart.preview_url)"
              />
            </div>
          </td>
        </tr>
        <!-- Expanded Items Row -->
        <tr v-if="isExpanded(cart.id)" class="bg-n-alpha-1">
          <td colspan="8" class="py-4 px-4">
            <div class="ltr:ml-4 rtl:mr-4">
              <table class="min-w-full">
                <thead>
                  <tr class="text-xs text-n-slate-11">
                    <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
                      {{ $t('CARTS_LIST.TABLE.EXPANDED_ITEMS.PRODUCT') }}
                    </th>
                    <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
                      {{ $t('CARTS_LIST.TABLE.EXPANDED_ITEMS.QUANTITY') }}
                    </th>
                    <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
                      {{ $t('CARTS_LIST.TABLE.EXPANDED_ITEMS.UNIT_PRICE') }}
                    </th>
                    <th class="py-2 ltr:pr-4 rtl:pl-4 text-left font-medium">
                      {{ $t('CARTS_LIST.TABLE.EXPANDED_ITEMS.TOTAL') }}
                    </th>
                  </tr>
                </thead>
                <tbody class="text-sm text-n-slate-12">
                  <tr v-for="item in cart.items" :key="item.id">
                    <td class="py-2 ltr:pr-4 rtl:pl-4">
                      {{ item.product?.title_en || '-' }}
                    </td>
                    <td class="py-2 ltr:pr-4 rtl:pl-4">
                      {{ item.quantity }}
                    </td>
                    <td class="py-2 ltr:pr-4 rtl:pl-4">
                      {{ item.unit_price }} {{ cart.currency }}
                    </td>
                    <td class="py-2 ltr:pr-4 rtl:pl-4">
                      {{ item.total_price }} {{ cart.currency }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </td>
        </tr>
      </template>
    </tbody>
  </table>
</template>
