<script setup>
import Input from 'dashboard/components-next/input/Input.vue';
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue';
import { BUS_EVENTS } from '../../../../shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import currency_codes from 'shared/constants/currency_codes';
import SimpleDivider from 'v3/components/Divider/SimpleDivider.vue';
import useVuelidate from '@vuelidate/core';
import { maxValue, minValue, required, url } from '@vuelidate/validators';
import QuantityField from './QuantityField.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import OrdersAPI from 'dashboard/api/shopify/orders';
import { isAxiosError } from 'axios';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';

const store = useStore();

const currentChat = useMapGetter('getSelectedChat');
const currentUser = useMapGetter('getCurrentUser');

const sender = computed(() => {
  return {
    name: currentUser.value.name,
    thumbnail: currentUser.value.avatar_url,
  };
});

const props = defineProps({
  order: {
    type: Object,
    required: true,
  },
});

const genericCountries = [
  '4PX',
  'AGS',
  'Amazon',
  'Amazon Logistics UK',
  'An Post',
  'Anjun Logistics',
  'APC',
  'Asendia USA',
  'Australia Post',
  'Bonshaw',
  'BPost',
  'BPost International',
  'Canada Post',
  'Canpar',
  'CDL Last Mile',
  'China Post',
  'Chronopost',
  'Chukou1',
  'Colissimo',
  'Comingle',
  'Coordinadora',
  'Correios',
  'Correos',
  'CTT',
  'CTT Express',
  'Cyprus Post',
  'Delnext',
  'Deutsche Post',
  'DHL eCommerce',
  'DHL eCommerce Asia',
  'DHL Express',
  'DPD',
  'DPD Local',
  'DPD UK',
  'DTD Express',
  'DX',
  'Eagle',
  'Estes',
  'Evri',
  'FedEx',
  'First Global Logistics',
  'First Line',
  'FSC',
  'Fulfilla',
  'GLS',
  'Guangdong Weisuyi Information Technology (WSE)',
  'Heppner Internationale Spedition GmbH & Co.',
  'Iceland Post',
  'IDEX',
  'Israel Post',
  'Japan Post (EN)',
  'Japan Post (JA)',
  'La Poste',
  'Lasership',
  'Latvia Post',
  'Lietuvos Paštas',
  'Logisters',
  'Lone Star Overnight',
  'M3 Logistics',
  'Meteor Space',
  'Mondial Relay',
  'New Zealand Post',
  'NinjaVan',
  'North Russia Supply Chain (Shenzhen) Co.',
  'OnTrac',
  'Packeta',
  'Pago Logistics',
  'Ping An Da Tengfei Express',
  'Pitney Bowes',
  'Portal PostNord',
  'Poste Italiane',
  'PostNL',
  'PostNord DK',
  'PostNord NO',
  'PostNord SE',
  'Purolator',
  'Qxpress',
  'Qyun Express',
  'Royal Mail',
  'Royal Shipments',
  'Sagawa (EN)',
  'Sagawa (JA)',
  'Sendle',
  'SF Express',
  'SFC Fulfillment',
  'SHREE NANDAN COURIER',
  'Singapore Post',
  'Southwest Air Cargo',
  'StarTrack',
  'Step Forward Freight',
  'Swiss Post',
  'TForce Final Mile',
  'Tinghao',
  'TNT',
  'Toll IPEC',
  'United Delivery Service',
  'UPS',
  'USPS',
  'Venipak',
  'We Post',
  'Whistl',
  'Wizmo',
  'WMYC',
  'Xpedigo',
  'XPO Logistics',
  'Yamato (EN)',
  'Yamato (JA)',
  'YiFan Express',
  'YunExpress',
];

const companyMaps = {
  Other: ['Other'],
  Worldwide: genericCountries,
  Australia: [
    'Australia Post',
    'Sendle',
    'Aramex Australia',
    'TNT Australia',
    'Hunter Express',
    'Couriers Please',
    'Bonds',
    'Allied Express',
    'Direct Couriers',
    'Northline',
    'GO Logistics',
  ],
  Austria: ['Österreichische Post'],
  Bulgaria: ['Speedy'],
  Canada: ['Intelcom', 'BoxKnight', 'Loomis', 'GLS'],
  China: [
    'China Post',
    'DHL eCommerce Asia',
    'WanbExpress',
    'YunExpress',
    'Anjun Logistics',
    'SFC Fulfillment',
    'FSC',
  ],
  Czechia: ['Zásilkovna'],
  Germany: [
    'Deutsche Post (DE)',
    'Deutsche Post (EN)',
    'DHL',
    'DHL Express',
    'Swiship',
    'Hermes',
    'GLS',
  ],
  Spain: ['SEUR'],
  France: ['Colissimo', 'Mondial Relay', 'Colis Privé', 'GLS'],
  'United Kingdom': [
    'Evri',
    'DPD UK',
    'Parcelforce',
    'Yodel',
    'DHL Parcel',
    'Tuffnells',
  ],
  Greece: ['ACS Courier'],
  'Hong Kong SAR': ['SF Express'],
  Ireland: ['Fastway', 'DPD Ireland'],
  India: [
    'DTDC',
    'India Post',
    'Delhivery',
    'Gati KWE',
    'Professional Couriers',
    'XpressBees',
    'Ecom Express',
    'Ekart',
    'Shadowfax',
    'Bluedart',
  ],
  Italy: ['BRT', 'GLS Italy'],
  Japan: [
    'エコ配',
    '西濃運輸',
    '西濃スーパーエキスプレス',
    '福山通運',
    '日本通運',
    '名鉄運輸',
    '第一貨物',
  ],
  Netherlands: ['DHL Parcel', 'DPD'],
  Norway: ['Bring'],
  Poland: ['Inpost'],
  Turkey: ['PTT', 'Yurtiçi Kargo', 'Aras Kargo', 'Sürat Kargo'],
  'United States': [
    'GLS',
    'Alliance Air Freight',
    'Pilot Freight',
    'LSO',
    'Old Dominion',
    'Pandion',
    'R+L Carriers',
    'Southwest Air Cargo',
  ],
  'South Africa': ['Fastway', 'Skynet'],
};

const onClose = () => {
  emitter.emit(BUS_EVENTS.FULFILL_ORDER, null);
};

const unfulfilledQuantityLimits = ref({});

const unfulfilledQuantityStates = ref({});

const trackingCompanyCategory = ref(null);

const initialFormState = {
  sendNotification: true,
  trackingCompany: null,
  trackingNumber: [],
  trackingUrl: [],
  unfulfilledQuantity: computed(() => unfulfilledQuantityStates.value),
};

const formState = reactive(initialFormState);

const rules = computed(() => {
  const unfulfilledQuantitiesRules = {};

  Object.entries(unfulfilledQuantityStates.value).forEach(([id, quant]) => {
    unfulfilledQuantitiesRules[id] = {
      required,
      minValue: minValue(0),
      maxValue: maxValue(quant),
    };
  });

  const trackingNumberRules = [];
  const trackingURLRules = [];

  if (formState.trackingCompany) {
    for (var t_num of formState.trackingNumber) {
      trackingNumberRules.push({
        required,
      });
      if (formState.trackingCompany === 'Other') {
        trackingURLRules.push({
          required,
          url,
        });
      }
    }
  }

  return {
    trackingNumber: trackingNumberRules,
    trackingUrl: trackingURLRules,
    unfulfilledQuantity: unfulfilledQuantitiesRules,
  };
});

const v$ = useVuelidate(rules, formState);

/**
 * @typedef {Object} FulfillmentOrderLineItem
 * @property {string} id - The unique Shopify FulfillmentOrderLineItem GID.
 * @property {number} remainingQuantity - The quantity of this item remaining to be fulfilled.
 * @property {Object} lineItem
 * @property {string} lineItem.id - The Shopify LineItem GID this fulfillment line item refers to.
 */

/**
 * @typedef {Object} FulfillmentOrder
 * @property {string} id - The unique Shopify FulfillmentOrder GID.
 * @property {string} orderName - The order name (e.g., "#1040").
 * @property {{ nodes: FulfillmentOrderLineItem[] }} lineItems - The fulfillment order's line items in nodes array.
 */

/**
 * @type {import('vue').Ref<FulfillmentOrder[]>}
 */
const fulfillmentOrders = ref([]);
const fulfillmentOrderLineItems = ref([]);

const assignedLocation = ref(null);

const getOrderInfo = async () => {
  const result = await OrdersAPI.fulfillmentOrders({ orderId: props.order.id });

  assignedLocation.value =
    result.data.order.fulfillmentOrders.nodes[0].assignedLocation;

  const flis = result.data.order.fulfillmentOrders.nodes.flatMap(
    e => e.lineItems.nodes
  );

  for (const oli of flis) {
    unfulfilledQuantityLimits.value[oli.id] = oli.remainingQuantity;
    unfulfilledQuantityStates.value[oli.id] = 0;
  }

  fulfillmentOrders.value = result.data.order.fulfillmentOrders.nodes;

  for (const fo of fulfillmentOrders.value) {
    for (const fli of fo.lineItems.nodes) {
      const li = props.order.line_items.find(
        e => `gid://shopify/LineItem/${e.id}` == fli.lineItem.id
      );

      if (!li) continue;

      const { id, quantity, ...rest } = li;
      Object.assign(fli, rest);
    }
  }
};

onMounted(() => {
  getOrderInfo();
});

const cancellationState = ref(null);

const createFulfillMessage = fulfillLineItems => {
  const messagePayload = {
    order_id: props.order.id,
    line_items: fulfillLineItems.map(rli => ({
      id: rli.id,
      name: rli.name,
      qty: rli.quantity,
    })),
    sender: sender.value,
    chat_id: currentChat.value.id,
    status_url: props.order.order_status_url,
  };

  store.dispatch('fulfillOrder', messagePayload);
};

const fulfillOrder = async $t => {
  v$.value.$touch();

  if (v$.value.$invalid) {
    return;
  }

  try {
    const fulfillLineItems = fulfillmentOrders.value.map(fo => ({
      fulfillmentOrderId: fo.id,
      fulfillmentOrderLineItems: fo.lineItems.nodes
        .filter(foli => formState.unfulfilledQuantity[foli.id] > 0)
        .map(e => ({
          id: e.id,
          name: e.name, // NOTE: this field is only used in message
          quantity: formState.unfulfilledQuantity[e.id],
        })),
    }));

    let error = null;
    if (
      !fulfillLineItems.some(e =>
        e.fulfillmentOrderLineItems.some(e => e.quantity > 0)
      )
    ) {
      error = $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.ITEM_INSUFFICIENT');
    }
    if (
      formState.trackingCompany !== null &&
      formState.trackingNumber.length === 0
    ) {
      error = $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.TRACKING_INSUFFICIENT');
    }
    if (error != null) {
      useAlert(error);
      return;
    }
    cancellationState.value = 'processing';

    const payload = {
      orderId: props.order.id,
      originAddress: assignedLocation.value,
      notifyCustomer: formState.sendNotification,
      lineItemsByFulfillmentOrder: fulfillLineItems,

      trackingInfo:
        formState.trackingCompany === null
          ? null
          : {
              company: formState.trackingCompany,
              number:
                formState.trackingNumber.length === 1
                  ? formState.trackingNumber[0]
                  : null,
              numbers:
                formState.trackingNumber.length > 1
                  ? formState.trackingNumber
                  : null,
              url:
                formState.trackingUrl.length === 1
                  ? formState.trackingUrl[0]
                  : null,
              urls:
                formState.trackingUrl.length > 1 ? formState.trackingUrl : null,
            },
    };

    await OrdersAPI.fulfillmentCreate(payload);

    createFulfillMessage(
      fulfillLineItems.flatMap(e => e.fulfillmentOrderLineItems)
    );

    cancellationState.value = null;
    onClose();

    useAlert($t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.API_SUCCESS'));
  } catch (e) {
    cancellationState.value = null;
    let message = $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.API_FAILURE');
    if (isAxiosError(e)) {
      const errors = e.response.data.errors;
      if (errors && errors[0].message) {
        message = errors[0].message;
      }
    }
    useAlert(message);
  }
};

const addTrackingFields = () => {
  formState.trackingNumber.push('');
};

const removeTrackingFields = index => {
  formState.trackingNumber = formState.trackingNumber.filter(
    (elem, i) => index !== i
  );
};

const buttonText = () => {
  return cancellationState.value === 'processing'
    ? 'CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.PROCESSING'
    : 'CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.FULFILL_ORDER';
};
</script>

<template>
  <woot-modal :show="true" :on-close="onClose" size="w-[60.4rem] h-[50.4rem]">
    <woot-modal-header
      :header-title="$t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.TITLE')"
      :header-content="$t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.DESC')"
    />
    <form>
      <div class="h-[24.4rem] overflow-auto justify-between">
        <div v-for="fli in fulfillmentOrders" class="flex flex-col gap-2">
          <table
            class="woot-table items-table overflow-auto max-h-2 table-fixed"
          >
            <thead>
              <tr>
                <th class="overflow-auto max-w-xs">
                  {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.TABLE.PRODUCT') }}
                </th>
                <th>
                  {{
                    $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.TABLE.ITEM_PRICE')
                  }}
                </th>
                <th>
                  {{
                    $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.TABLE.QUANTITY')
                  }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in fli.lineItems.nodes" :key="item.id">
                <td>
                  <div class="overflow-auto max-w-xs">{{ item.name }}</div>
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
                      v-model="formState.unfulfilledQuantity[item.id]"
                      :min="0"
                      :max="unfulfilledQuantityLimits[item.id]"
                    ></QuantityField>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <SimpleDivider></SimpleDivider>
      </div>

      <div class="flex flex-col">
        <div class="flex flex-row justify-end items-start gap-4 mt-4">
          <div class="flex flex-col">
            <h5 class="pb-1">
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.TRACKING.CATEGORY') }}
            </h5>

            <select
              v-model="trackingCompanyCategory"
              class="w-full mt-1 border-0 selectInbox"
            >
              <option v-for="key in Object.keys(companyMaps)" :value="key">
                {{ key }}
              </option>
            </select>
          </div>

          <div class="flex flex-col">
            <h5 class="pb-1">
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.TRACKING.COMPANY') }}
              <!-- {{ add marker for manual }}  -->
            </h5>

            <select
              v-model="formState.trackingCompany"
              class="w-full mt-1 border-0 selectInbox"
            >
              <option
                v-for="value in companyMaps[trackingCompanyCategory]"
                :value="value"
              >
                {{ value }}
              </option>
            </select>
          </div>
        </div>
        <div class="flex flex-row gap-2 justify-between items-center">
          <h3>
            {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.TRACKING.NUMBERS') }}
          </h3>

          <NextButton
            type="button"
            :is-disabled="!formState.trackingCompany"
            variant="primary"
            @click="() => addTrackingFields()"
          >
            {{
              $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.TRACKING.ADD_TRACKING')
            }}
          </NextButton>
        </div>
        <SimpleDivider></SimpleDivider>
        <div
          class="flex flex-col"
          v-for="(item, index) in formState.trackingNumber"
        >
          <div class="flex flex-row gap-4">
            <NextButton
              icon="i-lucide-trash-2"
              type="button"
              variant="primary"
              @click="() => removeTrackingFields(index)"
            >
            </NextButton>
            <div class="flex flex-col mb-4">
              <Input
                type="text"
                v-model="formState.trackingNumber[index]"
                :message="v$.trackingNumber[index].$errors[0]?.$message || ''"
                :message-type="
                  v$.trackingNumber[index].$error ? 'error' : 'message'
                "
                style="width: 200px; font-size: 1.1em"
                autocomplete="off"
              />
            </div>

            <div class="flex flex-col">
              <Input
                v-if="formState.trackingCompany === 'Other'"
                type="text"
                :message="v$.trackingUrl[index].$errors[0]?.$message || ''"
                :message-type="
                  v$.trackingUrl[index].$error ? 'error' : 'message'
                "
                v-model="formState.trackingUrl[index]"
                style="width: 200px; font-size: 1.1em"
                autocomplete="off"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="flex flex-col items-start justify-center content-start gap-2">
        <div
          class="select-visible-checkbox gap-2"
          :style="selectVisibleCheckboxStyle"
        >
          <input
            type="checkbox"
            :checked="formState.sendNotification"
            @change="formState.sendNotification = !formState.sendNotification"
          />

          <span>
            {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.FULFILL.SEND_NOTIFICATION') }}
          </span>
        </div>
      </div>

      <div class="flex flex-row justify-end absolute bottom-4 right-4">
        <NextButton
          type="button"
          :disabled="v$.$error || cancellationState === 'processing'"
          variant="primary"
          @click="() => fulfillOrder($t)"
        >
          {{ $t(buttonText()) }}
        </NextButton>
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
