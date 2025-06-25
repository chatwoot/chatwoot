<script setup>
import { computed, onMounted, onUnmounted, reactive, ref } from 'vue';
import { BUS_EVENTS } from '../../../../shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import currency_codes from 'shared/constants/currency_codes';
import SimpleDivider from 'v3/components/Divider/SimpleDivider.vue';
import { useStore } from 'vuex';
import useVuelidate from '@vuelidate/core';
import { maxValue, minValue, required } from '@vuelidate/validators';
import QuantityField from './QuantityField.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const show = ref(false);

const store = useStore();

const reasons = [
  'Wrong item received',
  'Item was damaged or defective',
  'Item not as described',
  'Order arrived late',
  'Duplicate or accidental order',
];

const onClose = () => {
  emitter.emit(BUS_EVENTS.CANCEL_ORDER, null);
};

const currentOrder = ref(null);

const quantityStates = computed(() =>
  Object.fromEntries(
    currentOrder.value?.line_items.map(e => [e.id, e.quantity]) ?? []
  )
);

const formState = reactive({
  refundAmount: 0,
  refundReason: null,
  customRefundReason: null,
  restockItem: false,
  sendNotification: false,
  quantity: quantityStates,
  // quantity: {
  //   16632369250614: 4,
  // },
});

const rules = computed(() => {
  const quantityRules = {};

  currentOrder.value?.line_items.forEach(item => {
    quantityRules[item.id] = {
      required,
      minValue: minValue(0),
      maxValue: maxValue(item.quantity),
    };
  });

  return {
    refundAmount: { required },
    refundReason: { required },
    customRefundReason: {},
    quantity: {},
  };
});

const v$ = useVuelidate(rules, formState);

const refundableAmount = ref(0);

const item_total_price = item => {
  return (
    item.price_set.shop_money.amount * item.quantity -
    item.total_discount_set.shop_money.amount
  );
};

const setCancelledOrder = order => {
  show.value = order !== null && order !== undefined;
  currentOrder.value = order;
};

onMounted(() => {
  emitter.on(BUS_EVENTS.CANCEL_ORDER, setCancelledOrder);
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.CANCEL_ORDER, setCancelledOrder);
});

// Only allow numbers with up to 2 decimals
function onInput(e) {
  let val = e.target.value;

  // Remove all characters except digits and dot
  val = val.replace(/[^0-9.]/g, '');

  // Only allow one dot
  const parts = val.split('.');
  if (parts.length > 2) {
    val = parts[0] + '.' + parts.slice(1).join('');
  }

  // Limit to 2 decimal places
  if (parts[1]?.length > 2) {
    val = parts[0] + '.' + parts[1].slice(0, 2);
  }

  // Prevent leading dot (".5" -> "0.5")
  if (val.startsWith('.')) {
    val = '0' + val;
  }

  formState.refundAmount = val;
}

function onBlur() {
  // Format to 2 decimals if not empty
  if (formState.refundAmount && !isNaN(formState.refundAmount)) {
    formState.refundAmount = parseFloat(formState.refundAmount).toFixed(2);
  }
}

const cancelOrder = () => {
  v$.value.$touch();
};
</script>

<template>
  <woot-modal v-model:show="show" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.TITLE')"
      :header-content="$t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.DESC')"
    />
    <form>
      <div v-if="currentOrder" class="p-2">
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
            <tr v-for="item in [...currentOrder.line_items]" :key="item.id">
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
                <!-- <div>{{ item.quantity }}</div> -->
                <div class="inline-block">
                  <QuantityField
                    v-model="formState.quantity[item.id]"
                    :min="0"
                    :max="item.quantity"
                  ></QuantityField>
                </div>
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

        <div
          class="flex flex-row pr-11 items-start justify-start content-start"
        >
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

          <div class="flex-1 flex-row"></div>

          <div class="flex flex-col">
            <div class="flex flex-row justify-between items-center gap-10">
              <label>
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.SUBTOTAL') }}
              </label>
              <span class="text-sm"
                >{{ currency_codes[currentOrder.currency] }}
                {{ currentOrder.subtotal_price }}</span
              >
            </div>

            <div class="flex flex-row justify-between gap-10">
              <label>
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.DISCOUNT') }}
              </label>
              <span class="text-sm"
                >{{ currency_codes[currentOrder.currency] }}
                {{ currentOrder.total_discount ?? 0 }}</span
              >
            </div>

            <div class="flex flex-row justify-between gap-10">
              <label>
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.TAX') }}
              </label>
              <span class="text-sm"
                >{{ currency_codes[currentOrder.currency] }}
                {{ currentOrder.total_tax }}</span
              >
            </div>

            <div class="flex flex-row justify-between gap-10">
              <label>
                {{
                  $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.AMOUNT_REFUNDABLE')
                }}
              </label>
              <span class="text-sm"
                >{{ currency_codes[currentOrder.currency] }}
                {{ refundableAmount }}</span
              >
            </div>
          </div>
        </div>

        <div class="flex flex-row justify-start items-start gap-4 mt-4">
          <div class="flex flex-col gap-2">
            <h5>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.REFUND_AMOUNT') }}
              <!-- {{ add marker for manual }}  -->
            </h5>
            <input
              type="text"
              :value="
                currency_codes[currentOrder.currency] + formState.refundAmount
              "
              inputmode="decimal"
              placeholder="0.00"
              @input="onInput"
              @blur="onBlur"
              style="width: 200px; font-size: 1.1em"
              autocomplete="off"
            />
          </div>

          <div class="flex flex-col gap-1">
            <h5>
              {{
                $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.CANCELLATION_REASON')
              }}
              <!-- {{ add marker for manual }}  -->
            </h5>

            <select
              v-model="formState.refundReason"
              class="w-full p-2 mt-1 border-0 selectInbox"
              :class="{ 'border-red-500': v$.refundReason.$error }"
            >
              <option v-for="reason in reasons" :value="reason">
                {{ reason }}
              </option>
            </select>
          </div>
        </div>

        <div class="flex flex-row justify-end mt-4">
          <Button
            type="button"
            :disabled="v$.$error"
            variant="primary"
            @click="cancelOrder"
          >
            {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.CANCEL_ORDER') }}
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
