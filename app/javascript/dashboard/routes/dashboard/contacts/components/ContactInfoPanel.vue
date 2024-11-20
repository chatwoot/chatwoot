<script>
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import ContactConversations from 'dashboard/routes/dashboard/conversation/ContactConversations.vue';
import ContactInfo from 'dashboard/routes/dashboard/conversation/contact/ContactInfo.vue';
import ContactLabel from 'dashboard/routes/dashboard/contacts/components/ContactLabels.vue';
import CustomAttributes from 'dashboard/routes/dashboard/conversation/customAttributes/CustomAttributes.vue';
import Draggable from 'vuedraggable';
import { useUISettings } from 'dashboard/composables/useUISettings';

export default {
  components: {
    AccordionItem,
    ContactConversations,
    ContactInfo,
    ContactLabel,
    CustomAttributes,
    Draggable,
  },
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
  setup() {
    const {
      updateUISettings,
      isContactSidebarItemOpen,
      contactSidebarItemsOrder,
      toggleSidebarUIState,
    } = useUISettings();

    return {
      updateUISettings,
      isContactSidebarItemOpen,
      contactSidebarItemsOrder,
      toggleSidebarUIState,
    };
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

<template>
  <div
    class="relative w-1/4 h-full min-h-screen overflow-y-auto text-sm bg-white dark:bg-slate-900 border-slate-50 dark:border-slate-800/50"
    :class="showAvatar ? 'border-l border-solid ' : 'border-r border-solid'"
  >
    <ContactInfo
      :show-close-button="showCloseButton"
      :show-avatar="showAvatar"
      :contact="contact"
      close-icon-name="dismiss"
      @panel-close="onClose"
      @toggle-panel="onClose"
    />
    <div class="list-group">
      <Draggable
        :list="contactSidebarItems"
        :disabled="!dragEnabled"
        ghost-class="ghost"
        item-key="name"
        @start="dragging = true"
        @end="onDragEnd"
      >
        <template #item="{ element }">
          <div :key="element.name" class="list-group-item">
            <div v-if="element.name === 'contact_attributes'">
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_ATTRIBUTES')"
                :is-open="isContactSidebarItemOpen('is_ct_custom_attr_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_ct_custom_attr_open', value)
                "
              >
                <CustomAttributes
                  :contact-id="contact.id"
                  attribute-type="contact_attribute"
                  attribute-from="contact_panel"
                  :custom-attributes="contact.custom_attributes"
                  :empty-state-message="
                    $t('CONTACT_PANEL.SIDEBAR_SECTIONS.NO_RECORDS_FOUND')
                  "
                />
              </AccordionItem>
            </div>
            <div v-if="element.name === 'contact_labels'">
              <AccordionItem
                :title="$t('CONTACT_PANEL.SIDEBAR_SECTIONS.CONTACT_LABELS')"
                :is-open="isContactSidebarItemOpen('is_ct_labels_open')"
                @toggle="
                  value => toggleSidebarUIState('is_ct_labels_open', value)
                "
              >
                <ContactLabel :contact-id="contact.id" class="contact-labels" />
              </AccordionItem>
            </div>
            <div v-if="element.name === 'previous_conversation'">
              <AccordionItem
                :title="
                  $t('CONTACT_PANEL.SIDEBAR_SECTIONS.PREVIOUS_CONVERSATIONS')
                "
                :is-open="isContactSidebarItemOpen('is_ct_prev_conv_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_ct_prev_conv_open', value)
                "
              >
                <ContactConversations
                  v-if="contact.id"
                  :contact-id="contact.id"
                  conversation-id=""
                />
              </AccordionItem>
            </div>
          </div>
        </template>
      </Draggable>
    </div>
  </div>
</template>

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
</style>
