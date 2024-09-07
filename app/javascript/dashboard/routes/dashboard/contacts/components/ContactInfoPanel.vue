<template>
  <div
    class="w-1/4 bg-white dark:bg-slate-900 border-slate-50 dark:border-slate-800/50 h-full text-sm overflow-y-auto relative"
    :class="showAvatar ? 'border-l border-solid ' : 'border-r border-solid'"
  >
    <contact-info
      :show-close-button="showCloseButton"
      :show-avatar="showAvatar"
      :contact="contact"
      close-icon-name="dismiss"
      @panel-close="onClose"
      @toggle-panel="onClose"
    />
    <draggable
      :list="contactSidebarItems"
      :disabled="!dragEnabled"
      class="list-group"
      ghost-class="ghost"
      @start="dragging = true"
      @end="onDragEnd"
    >
      <transition-group>
        <div
          v-for="element in contactSidebarItems"
          :key="element.name"
          class="list-group-item"
        >
          <div
            v-if="element.name === 'contact_sales_info'"
            class="conversation--actions"
          >
            <accordion-item
              :title="$t('CONTACT_PANEL.SIDEBAR_SECTIONS.CONTACT_SALES_INFO')"
              :is-open="isContactSidebarItemOpen('is_contact_actions_open')"
              @click="
                value => toggleSidebarUIState('is_contact_actions_open', value)
              "
            >
              <contact-sales-info
                :contact="contact"
                :show-assignee-info="true"
              />
            </accordion-item>
          </div>
          <div v-if="element.name === 'contact_attributes'">
            <accordion-item
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_ATTRIBUTES')"
              :is-open="isContactSidebarItemOpen('is_ct_custom_attr_open')"
              compact
              @click="
                value => toggleSidebarUIState('is_ct_custom_attr_open', value)
              "
            >
              <custom-attributes
                :contact-id="contact.id"
                attribute-type="contact_attribute"
                attribute-class="conversation--attribute"
                attribute-from="contact_panel"
                :custom-attributes="contact.custom_attributes"
                class="even"
              />
            </accordion-item>
          </div>
          <div v-if="element.name === 'contact_transactions'">
            <accordion-item
              :title="$t('CONTACT_PANEL.SIDEBAR_SECTIONS.CONTACT_TRANSACTIONS')"
              :is-open="isContactSidebarItemOpen('is_ct_cont_trans_open')"
              @click="
                value => toggleSidebarUIState('is_ct_cont_trans_open', value)
              "
            >
              <contact-transactions
                v-if="contact.id"
                :contact-id="contact.id"
              />
            </accordion-item>
          </div>
          <div v-if="element.name === 'previous_conversation'">
            <accordion-item
              :title="
                $t('CONTACT_PANEL.SIDEBAR_SECTIONS.PREVIOUS_CONVERSATIONS')
              "
              :is-open="isContactSidebarItemOpen('is_ct_prev_conv_open')"
              @click="
                value => toggleSidebarUIState('is_ct_prev_conv_open', value)
              "
            >
              <contact-conversations
                v-if="contact.id"
                :contact-id="contact.id"
                conversation-id=""
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
import ContactInfo from 'dashboard/routes/dashboard/conversation/contact/ContactInfo.vue';
import ContactSalesInfo from 'dashboard/routes/dashboard/contacts/components/ContactSalesInfo.vue';
import CustomAttributes from 'dashboard/routes/dashboard/conversation/customAttributes/CustomAttributes.vue';
import draggable from 'vuedraggable';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import ContactTransactions from './ContactTransactions.vue';

export default {
  components: {
    AccordionItem,
    ContactConversations,
    ContactInfo,
    ContactSalesInfo,
    CustomAttributes,
    draggable,
    ContactTransactions,
  },
  mixins: [uiSettingsMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
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
      contactSidebarItems: [],
      dragging: false,
    };
  },
  computed: {
    hasContactAttributes() {
      const { custom_attributes: customAttributes } = this.contact;
      return customAttributes && Object.keys(customAttributes).length;
    },
  },
  mounted() {
    this.contactSidebarItems = this.contactSidebarItemsOrder;
  },
  methods: {
    onDragEnd() {
      this.dragging = false;
      this.updateUISettings({
        contact_sidebar_items_order: this.contactSidebarItems,
      });
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

.list-group {
  .list-group-item {
    @apply bg-white dark:bg-slate-900;
  }
}

.conversation--details {
  @apply py-0 px-4;
}

.conversation--actions .multiselect-wrap--small {
  .multiselect {
    @apply box-border pl-6;
  }
  .multiselect__element {
    span {
      @apply w-full;
    }
  }
}
</style>
