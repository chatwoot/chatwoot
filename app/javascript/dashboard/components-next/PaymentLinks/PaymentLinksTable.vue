<script setup>
import { format } from 'date-fns';
import { useRouter } from 'vue-router';
import { usePaymentLinkStatus } from 'dashboard/composables/usePaymentLinkStatus';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  paymentLinks: { type: Array, required: true },
  noRecordsFound: { type: Boolean, default: false },
  searchValue: { type: String, default: '' },
  hasAppliedFilters: { type: Boolean, default: false },
});

const router = useRouter();

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
    v-show="!noRecordsFound || searchValue || hasAppliedFilters"
    class="min-w-full divide-y divide-n-weak"
  >
    <thead>
      <tr>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('PAYMENT_LINKS.TABLE.PAYMENT_ID') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('PAYMENT_LINKS.TABLE.CONTACT') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('PAYMENT_LINKS.TABLE.AMOUNT') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('PAYMENT_LINKS.TABLE.STATUS') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('PAYMENT_LINKS.TABLE.CREATED_BY') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('PAYMENT_LINKS.TABLE.CONVERSATION') }}
        </th>
        <th
          class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
        >
          {{ $t('PAYMENT_LINKS.TABLE.ACTIONS') }}
        </th>
      </tr>
    </thead>
    <tbody class="divide-y divide-n-weak text-n-slate-12">
      <!-- Empty State Row -->
      <tr v-if="noRecordsFound && (searchValue || hasAppliedFilters)">
        <td colspan="7" class="py-10 text-center">
          <span class="text-base text-n-slate-11">
            {{
              searchValue
                ? $t('PAYMENT_LINKS.TABLE.NO_RESULTS_SEARCH')
                : $t('PAYMENT_LINKS.TABLE.NO_RESULTS_FILTER')
            }}
          </span>
        </td>
      </tr>
      <tr v-for="paymentLink in paymentLinks" :key="paymentLink.id">
        <td class="py-4 ltr:pr-4 rtl:pl-4">
          <div class="flex flex-col gap-0.5">
            <span class="font-medium">{{
              paymentLink.external_payment_id
            }}</span>
            <span class="text-xs text-n-slate-11">{{
              formatDate(paymentLink.created_at)
            }}</span>
          </div>
        </td>
        <td class="py-4 ltr:pr-4 rtl:pl-4">
          <button
            v-if="paymentLink.contact"
            class="text-n-iris-9 hover:text-n-iris-10 hover:underline"
            @click="
              navigateToContact(
                $store.state.auth.currentAccountId,
                paymentLink.contact.id
              )
            "
          >
            {{
              paymentLink.contact.name ||
              paymentLink.contact.email ||
              paymentLink.contact.phone_number
            }}
          </button>
          <span v-else class="text-n-slate-11">-</span>
        </td>
        <td class="py-4 ltr:pr-4 rtl:pl-4 font-medium">
          {{ paymentLink.amount }} {{ paymentLink.currency }}
        </td>
        <td class="py-4 ltr:pr-4 rtl:pl-4">
          <span
            class="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium"
            :class="[
              getStatusBadgeClasses(paymentLink.status).bg,
              getStatusBadgeClasses(paymentLink.status).text,
            ]"
          >
            <Icon
              :icon="getStatusBadgeClasses(paymentLink.status).icon"
              class="text-sm"
            />
            <span>{{
              $t(`PAYMENT_LINKS.STATUS.${paymentLink.status.toUpperCase()}`)
            }}</span>
          </span>
        </td>
        <td class="py-4 ltr:pr-4 rtl:pl-4 text-n-slate-11">
          {{ paymentLink.created_by?.name || '-' }}
        </td>
        <td class="py-4 ltr:pr-4 rtl:pl-4">
          <button
            v-if="paymentLink.conversation"
            class="text-n-iris-9 hover:text-n-iris-10 hover:underline"
            @click="
              navigateToConversation(
                $store.state.auth.currentAccountId,
                paymentLink.conversation.display_id
              )
            "
          >
            #{{ paymentLink.conversation.display_id }}
          </button>
          <span v-else class="text-n-slate-11">-</span>
        </td>
        <td class="py-4 ltr:pr-4 rtl:pl-4">
          <div class="flex items-center gap-2">
            <Button
              v-tooltip.top="$t('PAYMENT_LINKS.TABLE.COPY_URL')"
              icon="i-lucide-copy"
              slate
              xs
              faded
              @click="copyToClipboard(paymentLink.payment_url)"
            />
            <Button
              v-tooltip.top="$t('PAYMENT_LINKS.TABLE.VIEW_PAYMENT')"
              icon="i-lucide-external-link"
              slate
              xs
              faded
              @click="openPaymentLink(paymentLink.payment_url)"
            />
          </div>
        </td>
      </tr>
    </tbody>
  </table>
</template>
