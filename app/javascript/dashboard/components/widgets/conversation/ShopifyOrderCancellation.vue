<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, onUnmounted, reactive, ref } from 'vue';
import { BUS_EVENTS } from '../../../../shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import currency_codes from 'shared/constants/currency_codes';
import SimpleDivider from 'v3/components/Divider/SimpleDivider.vue';
import { useStore } from 'vuex';
import useVuelidate from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import Button from 'dashboard/components-next/button/Button.vue';
import OrdersAPI from 'dashboard/api/orders';
import { AxiosError } from 'axios';
import { isAxiosError } from 'axios';

const props = defineProps({
  order: {
    type: Object,
    required: true
  }
})

const reasons = {
  CUSTOMER: 'The customer wanted to cancel the order.',
  DECLINED: 'Payment was declined.',
  FRAUD: 'The order was fraudulent.',
  INVENTORY: 'There was insufficient inventory.',
  OTHER: 'The order was canceled for an unlisted reason.',
  STAFF: 'Staff made an error.',
};

const reasonOptions = Object.entries(reasons).map(([key, value]) => ({
  key,
  value,
}));

const cancellationState = ref(null);

const onClose = () => {
  emitter.emit(BUS_EVENTS.CANCEL_ORDER, null);
};

let cancellationTimeout = null;

const formState = reactive({
  cancellationReason: null,
  // customCancellationReason: null,
  // customReason: false,
  restockItem: true,
  refundOrder: true,
  sendNotification: true,
});

const rules = computed(() => {
  return {
    cancellationReason: { required },
  };
});

const v$ = useVuelidate(rules, formState);

const item_total_price = item => {
  return (
    item.price_set.shop_money.amount * item.quantity -
    item.total_discount_set.shop_money.amount
  );
};

const onOrderUpdate = data => {
  if (data.order.id != props.order.id) return;

  onClose();
  emitter.emit('newToastMessage', {
    message: "Order cancelled successfully",
    action: null,
  });

  clearTimeout(cancellationTimeout);
};

onMounted(() => {
  emitter.on(BUS_EVENTS.ORDER_UPDATE, onOrderUpdate);
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.ORDER_UPDATE, onOrderUpdate);
  clearTimeout(cancellationTimeout);
});

const cancelOrder = async $t => {
  v$.value.$touch();

  if (v$.value.$invalid) {
    return;
  }

  try {
    cancellationState.value = 'processing';

    await OrdersAPI.cancelOrder({
      orderId: props.order.id,
      reason: formState.cancellationReason,
      refund: formState.refundOrder,
      restock: formState.restockItem,
      notifyCustomer: formState.sendNotification,
    });

    cancellationTimeout = setTimeout(() => {
      emitter.emit(BUS_EVENTS.CANCEL_ORDER, null);
      useAlert($t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.API_TIMEOUT'));
    }, 30 * 1000);
  } catch (e) {
    cancellationState.value = null;
    let message = $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.API_FAILURE');
    if (isAxiosError(e)) {
      const errors = e.response.data.errors;
      if (errors && errors[0].message) {
        message = errors[0].message;
      }
    }
    useAlert(message);
  }
};

const buttonText = () => {
  if (cancellationState.value === 'processing')
    return 'CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.PROCESSING';
  return 'CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.CANCEL_ORDER';
};
</script>

<template>
  <woot-modal :show="true" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.TITLE')"
      :header-content="$t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.DESC')"
    />
    <form>
      <div v-if="order" class="">
        <table class="woot-table items-table overflow-auto max-h-2">
          <thead>
            <tr>
              <th>
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.TABLE.PRODUCT') }}
              </th>
              <th>
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.TABLE.ITEM_PRICE') }}
              </th>
              <th>
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.TABLE.QUANTITY') }}
              </th>
              <th>
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.TABLE.TOTAL') }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in [...order.line_items]" :key="item.id">
              <td>
                <div>{{ item.name }}</div>
              </td>
              <td>
                <div>
                  {{
                    currency_codes[
                      item.price_set.presentment_money.currency_code
                    ]
                  }}
                  {{ item.price_set.shop_money.amount }}
                </div>
              </td>
              <td class="text-center align-middle">
                <div>{{ item.quantity }}</div>
              </td>
              <td>
                <div>
                  {{ currency_codes[item.price_set.shop_money.currency_code] }}
                  {{ item_total_price(item) }}
                </div>
              </td>
            </tr>
          </tbody>
        </table>
        <SimpleDivider></SimpleDivider>
        <div class="h-4"></div>

        <div class="flex flex-row items-start justify-between content-start">
          <div
            class="flex flex-col items-start justify-start content-start gap-2"
          >
            <div
              class="select-visible-checkbox gap-2"
              :style="selectVisibleCheckboxStyle"
            >
              <input
                type="checkbox"
                :checked="formState.restockItem"
                @change="formState.restockItem = !formState.restockItem"
              />
              <span>
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.RESTOCK_ITEMS') }}
              </span>
            </div>
            <div
              class="select-visible-checkbox gap-2"
              :style="selectVisibleCheckboxStyle"
            >
              <input
                type="checkbox"
                :checked="formState.refundOrder"
                @change="formState.refundOrder = !formState.refundOrder"
              />

              <span>
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.REFUND_ORDER') }}
              </span>
            </div>

            <div
              class="select-visible-checkbox gap-2"
              :style="selectVisibleCheckboxStyle"
            >
              <input
                type="checkbox"
                :checked="formState.sendNotification"
                @change="
                  formState.sendNotification = !formState.sendNotification
                "
              />

              <span>
                {{
                  $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.SEND_NOTIFICATION')
                }}
              </span>
            </div>
          </div>

          <div class="flex flex-col justify-start items-start gap-4 ml-4">
            <div class="flex flex-col gap-1">
              <label class="">
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.REASON') }}
                <!-- {{ add marker for manual }}  -->
              </label>

              <select
                v-model="formState.cancellationReason"
                class="w-full p-2 mt-1 border-0"
                :class="{ 'border-red-500': v$.cancellationReason.$error }"
              >
                <option
                  v-for="reason in reasonOptions"
                  :key="reason.key"
                  :value="reason.key"
                >
                  {{ reason.value }}
                </option>
              </select>
            </div>
          </div>
        </div>

        <div class="flex flex-row justify-end mt-4">
          <Button
            type="button"
            :disabled="v$.$error || cancellationState === null"
            variant="primary"
            @click="() => cancelOrder($t)"
          >
            {{ $t(buttonText()) }}
          </Button>
        </div>
      </div>
    </form>
  </woot-modal>
</template>

<style lang="scss">
.items-table {
  > tbody {
    > tr {
      @apply cursor-pointer;

      &:hover {
        @apply bg-slate-50 dark:bg-slate-800;
      }

      &.is-active {
        @apply bg-slate-100 dark:bg-slate-700;
      }

      > td {
        &.conversation-count-item {
          @apply pl-6 rtl:pl-0 rtl:pr-6;
        }
      }

      &:last-child {
        @apply border-b-0;
      }
    }
  }
}

.select-visible-checkbox {
  @apply flex items-center text-sm text-slate-700 dark:text-white;

  input[type='checkbox'] {
    @apply w-4 h-4 cursor-pointer accent-black-600;
  }
}
</style>
