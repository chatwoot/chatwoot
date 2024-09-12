<template>
  <div
    class="relative w-1/4 h-full overflow-y-auto text-sm bg-white dark:bg-slate-900 border-slate-50 dark:border-slate-800/50"
    :class="showAvatar ? 'border-l border-solid ' : 'border-r border-solid'"
  >
    <order-general-info
      :show-close-button="true"
      :order="order"
      close-icon-name="dismiss"
      @panel-close="onClose"
      @toggle-panel="onClose"
    />

    <draggable
      :list="orderSidebarItems"
      :disabled="!dragEnabled"
      class="list-group"
      ghost-class="ghost"
      @start="dragging = true"
      @end="onDragEnd"
    >
      <transition-group>
        <div
          v-for="element in orderSidebarItems"
          :key="element.name"
          class="list-group-item"
        >
          <div v-if="element.name === 'contact'">
            <accordion-item
              :title="$t('ORDER_PANEL.LABELS.CUSTOMER.TITLE')"
              :is-open="isOrderSidebarItemOpen('is_ct_customer_open')"
              compact
              @click="
                value => toggleSidebarUIState('is_ct_customer_open', value)
              "
            >
              <contact-info
                :show-close-button="false"
                :show-avatar="true"
                :contact="contact"
              />
            </accordion-item>
          </div>
          <div v-if="element.name === 'items' && order.order_items">
            <accordion-item
              :title="$t('ORDER_PANEL.LABELS.ITEMS.TITLE')"
              :is-open="isOrderSidebarItemOpen('is_ct_items_open')"
              compact
              @click="value => toggleSidebarUIState('is_ct_items_open', value)"
            >
              <div v-for="item in order.order_items">
                <div class="conversation--attribute">
                  <ContactDetailsItem
                    v-if="item.name"
                    :title="$t('ORDER_PANEL.LABELS.ITEMS.NAME')"
                    :value="item.name"
                  />
                  <ContactDetailsItem
                    v-if="item.quantity"
                    :title="$t('ORDER_PANEL.LABELS.ITEMS.QUANTITY')"
                    :value="item.quantity"
                  />
                  <ContactDetailsItem
                    v-if="item.price"
                    :title="$t('ORDER_PANEL.LABELS.ITEMS.PRICE')"
                    :value="`R$${item.price}`"
                  />
                  <ContactDetailsItem
                    v-if="item.subtotal"
                    :title="$t('ORDER_PANEL.LABELS.ITEMS.SUBTOTAL')"
                    :value="`R$${item.subtotal}`"
                  />
                  <ContactDetailsItem
                    v-if="item.sku"
                    :title="$t('ORDER_PANEL.LABELS.ITEMS.SKU')"
                    :value="item.sku"
                  />
                  <ContactDetailsItem
                    v-if="item.variation_id"
                    :title="$t('ORDER_PANEL.LABELS.ITEMS.VARIANT')"
                    :value="item.variation_id"
                  />
                </div>
              </div>
            </accordion-item>
          </div>
          <div v-if="element.name === 'shipping'">
            <accordion-item
              :title="$t('ORDER_PANEL.LABELS.SHIPPING.TITLE')"
              :is-open="isOrderSidebarItemOpen('is_ct_shipping_open')"
              compact
              @click="
                value => toggleSidebarUIState('is_ct_shipping_open', value)
              "
            >
              <ContactDetailsItem
                v-if="order.contact.custom_attributes.shipping_address"
                :title="$t('ORDER_PANEL.LABELS.SHIPPING.ADDRESS')"
                :value="order.contact.custom_attributes.shipping_address"
              />
              <ContactDetailsItem
                v-if="order.shipping_total"
                :title="$t('ORDER_PANEL.LABELS.SHIPPING.TOTAL')"
                :value="`R$${order.shipping_total}`"
              />
              <ContactDetailsItem
                v-if="order.shipping_tax"
                :title="$t('ORDER_PANEL.LABELS.SHIPPING.TAX')"
                :value="`R$${order.shipping_tax}`"
              />
            </accordion-item>
          </div>
          <div v-if="element.name === 'values'">
            <accordion-item
              :title="$t('ORDER_PANEL.LABELS.VALUES.TITLE')"
              :is-open="isOrderSidebarItemOpen('is_ct_values_open')"
              compact
              @click="value => toggleSidebarUIState('is_ct_values_open', value)"
            >
              <ContactDetailsItem
                v-if="order.total"
                :title="$t('ORDER_PANEL.LABELS.VALUES.TOTAL')"
                :value="`R$${order.total}`"
              />
              <ContactDetailsItem
                v-if="order.discount_coupon"
                :title="$t('ORDER_PANEL.LABELS.VALUES.DISCOUNT_COUPON')"
                :value="`${order.discount_coupon}`"
              />
              <ContactDetailsItem
                v-if="order.discount_total"
                :title="$t('ORDER_PANEL.LABELS.VALUES.TOTAL_DISCOUNT')"
                :value="`R$${order.discount_total}`"
              />
              <ContactDetailsItem
                v-if="order.discount_tax"
                :title="$t('ORDER_PANEL.LABELS.VALUES.DISCOUNT_TAX')"
                :value="`R$${order.discount_tax}`"
              />
              <ContactDetailsItem
                v-if="order.cart_tax"
                :title="$t('ORDER_PANEL.LABELS.VALUES.CART_TAX')"
                :value="`R$${order.cart_tax}`"
              />
            </accordion-item>
          </div>
          <div v-if="element.name === 'payment'">
            <accordion-item
              :title="$t('ORDER_PANEL.LABELS.PAYMENT.TITLE')"
              :is-open="isOrderSidebarItemOpen('is_ct_payment_open')"
              compact
              @click="
                value => toggleSidebarUIState('is_ct_payment_open', value)
              "
            >
              <ContactDetailsItem
                v-if="order.payment_method"
                :title="$t('ORDER_PANEL.LABELS.PAYMENT.METHOD')"
                :value="order.payment_method"
              />

              <ContactDetailsItem
                v-if="order.payment_status"
                :title="$t('ORDER_PANEL.LABELS.PAYMENT.STATUS')"
                :value="order.payment_status"
              />
              <ContactDetailsItem
                v-if="order.date_paid"
                :title="$t('ORDER_PANEL.LABELS.PAYMENT.DATE_PAID')"
                :value="getDateMessage(order.date_paid)"
              />
              <ContactDetailsItem
                v-if="order.transaction_id"
                :title="$t('ORDER_PANEL.LABELS.PAYMENT.TRANSACTION_ID')"
                :value="order.transaction_id"
              />
            </accordion-item>
          </div>
        </div>
      </transition-group>
    </draggable>
  </div>
</template>

<script>
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import ContactConversations from 'dashboard/routes/dashboard/conversation/ContactConversations.vue';
import ContactLabel from 'dashboard/routes/dashboard/contacts/components/ContactLabels.vue';
import ContactInfo from 'dashboard/routes/dashboard/conversation/contact/ContactInfo.vue';
import CustomAttributes from 'dashboard/routes/dashboard/conversation/customAttributes/CustomAttributes.vue';
import ContactDetailsItem from 'dashboard/routes/dashboard/conversation/ContactDetailsItem.vue';
import draggable from 'vuedraggable';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import orderGeneralInfo from './orderGeneralInfo.vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';

export default {
  components: {
    AccordionItem,
    ContactConversations,
    ContactLabel,
    CustomAttributes,
    ContactInfo,
    ContactDetailsItem,
    draggable,
    orderGeneralInfo,
  },
  mixins: [uiSettingsMixin],
  props: {
    order: {
      type: Object,
      default: () => {},
    },
    onClose: {
      type: Function,
      default: () => {},
    },
    showAvatar: {
      type: Boolean,
      default: true,
    },
    showCloseButton: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      dragEnabled: true,
      orderSidebarItems: [],
      dragging: false,
    };
  },

  computed: {
    hasContactAttributes() {
      const { custom_attributes: customAttributes } = this.order;
      return customAttributes && Object.keys(customAttributes).length;
    },

    orderItemsMap(attribute) {
      const mapper = {
        name: 'Name',
      };
      return mapper[attribute] || attribute;
    },

    contact() {
      const dateToTimestamp = date => {
        const timestampDate = new Date(date);
        const timestamp = Math.floor(timestampDate.getTime() / 1000);
        return timestamp;
      };
      const newContact = {
        ...this.order.contact,
        created_at: dateToTimestamp(this.order.contact.created_at),
        updated_at: dateToTimestamp(this.order.contact.updated_at),
      };
      return newContact;
    },
  },
  mounted() {
    this.orderSidebarItems = this.integrationOrderSidebarItemsOrder;
  },
  methods: {
    onDragEnd() {
      this.dragging = false;
      this.updateUISettings({
        order_sidebar_items_order: this.orderSidebarItems,
      });
    },
    getDateMessage(date) {
      const timestampDate = new Date(date);
      const timestamp = Math.floor(timestampDate.getTime() / 1000);

      return messageTimestamp(timestamp);
    },
  },
};
</script>

<style lang="scss" scoped>
::v-deep {
  .contact--profile {
    @apply pb-3 mb-4;
  }
}

.conversation--attribute {
  @apply border-slate-50 dark:border-slate-700/50 border-b border-solid;
  &:nth-child(2n) {
    @apply bg-slate-25 dark:bg-slate-800/50;
  }
}

.list-group {
  .list-group-item {
    @apply bg-white dark:bg-slate-900;
  }
}

.conversation--details {
  @apply py-0 px-4;
}
</style>
