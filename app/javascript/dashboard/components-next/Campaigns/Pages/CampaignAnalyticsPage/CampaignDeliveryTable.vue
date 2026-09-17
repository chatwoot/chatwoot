<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import DeliveryStatusBadge from './DeliveryStatusBadge.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const props = defineProps({
  deliveries: {
    type: Array,
    default: () => [],
  },
  loading: {
    type: Boolean,
    default: false,
  },
  noDataMessage: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const route = useRoute();

const headers = computed(() => [
  t('CAMPAIGN.WHATSAPP.ANALYTICS.TABLE.CONTACT'),
  t('CAMPAIGN.WHATSAPP.ANALYTICS.TABLE.STATUS'),
  t('CAMPAIGN.WHATSAPP.ANALYTICS.TABLE.MESSAGE'),
  t('CAMPAIGN.WHATSAPP.ANALYTICS.TABLE.REASON'),
]);

const errorReason = delivery =>
  delivery.error_message || delivery.error_title || delivery.error_code || '';

const errorCode = delivery =>
  delivery.error_code &&
  String(delivery.error_code) !== String(errorReason(delivery))
    ? delivery.error_code
    : '';

const messageContent = delivery =>
  delivery.message_content ||
  t('CAMPAIGN.WHATSAPP.ANALYTICS.TABLE.MESSAGE_NOT_GENERATED');

const contactDetailsRoute = contactId => ({
  name: 'contacts_edit',
  params: {
    accountId: route.params.accountId,
    contactId,
  },
});

const isEmpty = computed(() => props.deliveries.length === 0);
</script>

<template>
  <div class="w-full border rounded-xl border-n-weak bg-n-solid-1">
    <div
      class="flex flex-col gap-3 px-5 py-4 sm:flex-row sm:items-center sm:justify-between sm:gap-4"
    >
      <span class="text-heading-2 text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP.ANALYTICS.TABLE.TITLE') }}
      </span>
      <div class="min-w-0 p-1 -m-1 overflow-x-auto no-scrollbar">
        <slot name="filters" />
      </div>
    </div>
    <div
      v-if="loading"
      class="flex items-center justify-center py-20 border-t text-n-slate-11 border-n-weak"
    >
      <Spinner />
    </div>
    <div
      v-else
      class="overflow-x-auto [&_th:first-child]:ps-5 [&_td:first-child]:ps-5 [&_th:last-child]:pe-5 [&_td:last-child]:pe-5"
      :class="{ 'border-t border-n-weak': isEmpty }"
    >
      <BaseTable
        :headers="headers"
        :items="deliveries"
        :no-data-message="noDataMessage"
      >
        <template #row="{ items }">
          <BaseTableRow
            v-for="delivery in items"
            :key="delivery.contact.id"
            :item="delivery"
          >
            <template #default>
              <BaseTableCell>
                <div class="flex flex-col gap-0.5 py-1">
                  <RouterLink
                    :to="contactDetailsRoute(delivery.contact.id)"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="inline-flex items-center max-w-full gap-1 transition-colors w-fit text-heading-3 text-n-slate-12 hover:text-n-blue-11 hover:underline underline-offset-2"
                    :title="t('CONTACTS_LAYOUT.CARD.VIEW_DETAILS')"
                  >
                    <span class="truncate">
                      {{ delivery.contact.name || '-' }}
                    </span>
                    <span
                      aria-hidden="true"
                      class="i-lucide-arrow-up-right size-3.5 shrink-0"
                    />
                  </RouterLink>
                  <span
                    class="tabular-nums truncate text-label-small text-n-slate-11"
                  >
                    {{ delivery.contact.phone_number || '-' }}
                  </span>
                </div>
              </BaseTableCell>
              <BaseTableCell>
                <DeliveryStatusBadge :status="delivery.status" />
              </BaseTableCell>
              <BaseTableCell>
                <span
                  class="block max-w-48 lg:max-w-md whitespace-pre-line line-clamp-2 text-body-main"
                  :class="
                    delivery.message_content
                      ? 'text-n-slate-11'
                      : 'italic text-n-slate-10'
                  "
                >
                  {{ messageContent(delivery) }}
                </span>
              </BaseTableCell>
              <BaseTableCell>
                <div
                  v-if="errorReason(delivery)"
                  class="flex flex-col gap-0.5 max-w-40 lg:max-w-56"
                >
                  <span class="line-clamp-2 text-body-main text-n-slate-11">
                    {{ errorReason(delivery) }}
                  </span>
                  <span
                    v-if="errorCode(delivery)"
                    class="tabular-nums text-label-small text-n-slate-10"
                  >
                    {{
                      t('CAMPAIGN.WHATSAPP.ANALYTICS.TABLE.ERROR_CODE', {
                        code: errorCode(delivery),
                      })
                    }}
                  </span>
                </div>
                <span v-else class="text-body-main text-n-slate-10">-</span>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
    </div>
    <slot name="footer" />
  </div>
</template>
