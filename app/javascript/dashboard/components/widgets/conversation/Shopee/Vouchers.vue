<script setup>
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';
import { useMapGetter } from 'dashboard/composables/store';
import {
  currencyFormatter,
  percentageFormatter,
  timeFormatter,
} from 'next/message/bubbles/Shopee/helper/formatter.js';
import LoadingState from 'components/widgets/LoadingState.vue';
import EmptyMessage from 'components/widgets/EmptyMessage.vue';

const { t } = useI18n();
const vouchers = useMapGetter('shopee/getVouchers');
</script>

<script>
export default {
  name: 'Vouchers',
  components: {
    LoadingState,
    EmptyMessage,
    Icon,
  },
  props: {
    currentChat: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      uiFlags: useMapGetter('shopee/getUIFlags'),
    };
  },
  mounted() {
    this.$store.dispatch('shopee/getVouchers', {
      conversationID: this.currentChat.id,
    });
  },
  methods: {
    sendVoucher(voucher) {
      this.$store.dispatch('shopee/sendVoucherMessage', {
        conversationId: this.currentChat.id,
        voucherId: voucher.voucherId,
        voucherCode: voucher.code,
      });
    },
  },
};
</script>

<template>
  <LoadingState v-if="uiFlags.isFetchingVouchers" />
  <EmptyMessage
    v-else-if="!vouchers.length"
    :message="t('CONVERSATION.SHOPEE.VOUCHERS.EMPTY_MESSAGE')"
  />
  <ul v-else class="bg-slate-50 dark:bg-slate-800 p-2">
    <li
      v-for="voucher in vouchers"
      :key="voucher.code"
      class="voucher w-full flex justify-between p-2 mb-2 bg-white rounded-md shadow-sm dark:bg-slate-900"
    >
      <div class="flex flex-col w-full">
        <div class="flex flex-row items-center">
          <div
            class="w-12 h-12 flex items-center justify-center rounded-full bg-orange-100 px-2 ms-2"
          >
            <Icon
              v-if="voucher.meta?.voucher_type === 1"
              icon="i-lucide-store"
              class="voucher-icon text-2xl text-orange-800"
            />
            <Icon
              v-else
              icon="i-lucide-shapes"
              class="voucher-icon text-2xl text-orange-600"
            />
          </div>
          <div
            class="flex-1 border-l-2 border-orange-700 pl-4 border-dashed ms-4 overflow-hidden"
          >
            <p class="mb-0 text-xs truncate">{{ voucher.code }}</p>
            <h3
              v-if="voucher.meta?.discount_amount > 0"
              class="font-semibold text-orange-700 dark:text-slate-100"
            >
              {{ currencyFormatter(voucher.meta.discount_amount) }}
            </h3>
            <h3
              v-if="voucher.meta?.percentage > 0"
              class="font-semibold flex items-center"
            >
              <span class="flex-1 text-orange-700 dark:text-slate-100">
                {{ percentageFormatter(0 - voucher.meta.percentage) }}
              </span>
              <span
                v-if="voucher.meta?.max_price > 0"
                class="flex text-xs text-slate-500 dark:text-slate-200"
              >
                {{
                  t('CONVERSATION.SHOPEE.VOUCHERS.MAX_DISCOUNT', {
                    value: currencyFormatter(voucher.meta.max_price),
                  })
                }}
              </span>
            </h3>
            <p class="text-grey text-xs mb-0 flex">
              <span class="field-label">
                {{ t('CONVERSATION.SHOPEE.VOUCHERS.MIN_BASKET') }}
              </span>
              <span class="field-value">
                {{ currencyFormatter(voucher.meta?.min_basket_price) }}
              </span>
            </p>
            <p class="text-grey text-xs mb-0 flex">
              <span class="field-label">
                {{ t('CONVERSATION.SHOPEE.VOUCHERS.VALID_UNTIL') }}
              </span>
              <span class="field-value">
                {{ timeFormatter(voucher.endTime) }}
              </span>
            </p>
          </div>
        </div>
        <div
          class="flex justify-between border-t border-slate-200 dark:border-slate-600 border-dashed mt-2 pt-2 text-xs"
        >
          <span class="flex-auto line-clamp-1">{{ voucher.name }}</span>
          <span class="flex-none">
            <a
              class="text-orange-700 border border-orange-700 rounded-md py-1 px-5 text-xs hover:bg-orange-700 hover:text-white cursor-pointer"
              @click="sendVoucher(voucher)"
            >
              {{ t('CONVERSATION.SHOPEE.SEND') }}
            </a>
          </span>
        </div>
      </div>
    </li>
  </ul>
</template>

<style lang="scss" scoped>
.voucher {
  @apply relative;

  .field-label {
    @apply flex-none text-slate-500 dark:text-slate-500 min-w-[60px];
  }
  .field-value {
    @apply text-end flex-1 text-slate-900 dark:text-slate-300;
  }

  button {
    @apply text-sm text-white bg-orange-600 rounded-md py-1 px-2 hover:bg-orange-700;
  }
}
</style>
