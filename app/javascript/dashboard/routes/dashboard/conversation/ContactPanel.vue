<script setup>
import { computed, watch, onMounted, ref } from 'vue';
import {
  useMapGetter,
  useFunctionGetter,
  useStore,
} from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import ContactConversations from './ContactConversations.vue';
import ConversationAction from './ConversationAction.vue';
import ConversationParticipant from './ConversationParticipant.vue';
import ContactInfo from './contact/ContactInfo.vue';
import ContactNotes from './contact/ContactNotes.vue';
import ConversationInfo from './ConversationInfo.vue';
import CustomAttributes from './customAttributes/CustomAttributes.vue';
import Draggable from 'vuedraggable';
import MacrosList from './Macros/List.vue';
import ShopifyOrdersList from 'dashboard/components/widgets/conversation/ShopifyOrdersList.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  inboxId: {
    type: Number,
    default: undefined,
  },
});

const {
  updateUISettings,
  isContactSidebarItemOpen,
  conversationSidebarItemsOrder,
  toggleSidebarUIState,
} = useUISettings();

const dragging = ref(false);
const conversationSidebarItems = ref([]);
const shopifyIntegration = useFunctionGetter(
  'integrations/getIntegration',
  'shopify'
);

const isShopifyFeatureEnabled = computed(
  () => shopifyIntegration.value.enabled
);

const store = useStore();
const currentChat = useMapGetter('getSelectedChat');
const conversationId = computed(() => props.conversationId);
const conversationMetadataGetter = useMapGetter(
  'conversationMetadata/getConversationMetadata'
);
const currentConversationMetaData = computed(() =>
  conversationMetadataGetter.value(conversationId.value)
);
const conversationAdditionalAttributes = computed(
  () => currentConversationMetaData.value.additional_attributes || {}
);

const channelType = computed(() => currentChat.value.meta?.channel);

const contactGetter = useMapGetter('contacts/getContact');
const contactId = computed(() => currentChat.value.meta?.sender?.id);
const contact = computed(() => contactGetter.value(contactId.value));
const contactAdditionalAttributes = computed(
  () => contact.value.additional_attributes || {}
);

const getContactDetails = () => {
  if (contactId.value) {
    store.dispatch('contacts/show', { id: contactId.value });
  }
};

watch(conversationId, (newConversationId, prevConversationId) => {
  if (newConversationId && newConversationId !== prevConversationId) {
    getContactDetails();
  }
});

watch(contactId, getContactDetails);

const onDragEnd = () => {
  dragging.value = false;
  updateUISettings({
    conversation_sidebar_items_order: conversationSidebarItems.value,
  });
};

const closeContactPanel = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: false,
  });
};

onMounted(() => {
  conversationSidebarItems.value = conversationSidebarItemsOrder.value;
  getContactDetails();
  store.dispatch('attributes/get', 0);
});
</script>

<template>
  <div class="w-full">
    <SidebarActionsHeader
      :title="$t('CONVERSATION.SIDEBAR.CONTACT')"
      @close="closeContactPanel"
    />
    <ContactInfo :contact="contact" :channel-type="channelType" />
    <div class="list-group pb-8">
      <Draggable
        :list="conversationSidebarItems"
        animation="200"
        ghost-class="ghost"
        handle=".drag-handle"
        item-key="name"
        class="flex flex-col gap-3"
        @start="dragging = true"
        @end="onDragEnd"
      >
        <template #item="{ element }">
          <div :key="element.name" class="px-2">
            <div
              v-if="element.name === 'conversation_actions'"
              class="conversation--actions"
            >
              <AccordionItem
                :title="
                  $t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_ACTIONS')
                "
                :is-open="isContactSidebarItemOpen('is_conv_actions_open')"
                @toggle="
                  value => toggleSidebarUIState('is_conv_actions_open', value)
                "
              >
                <ConversationAction
                  :conversation-id="conversationId"
                  :inbox-id="inboxId"
                />
              </AccordionItem>
            </div>
            <div
              v-else-if="element.name === 'conversation_participants'"
              class="conversation--actions"
            >
              <AccordionItem
                :title="$t('CONVERSATION_PARTICIPANTS.SIDEBAR_TITLE')"
                :is-open="isContactSidebarItemOpen('is_conv_participants_open')"
                @toggle="
                  value =>
                    toggleSidebarUIState('is_conv_participants_open', value)
                "
              >
                <ConversationParticipant
                  :conversation-id="conversationId"
                  :inbox-id="inboxId"
                />
              </AccordionItem>
            </div>
            <div v-else-if="element.name === 'conversation_info'">
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_INFO')"
                :is-open="isContactSidebarItemOpen('is_conv_details_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_conv_details_open', value)
                "
              >
                <ConversationInfo
                  :conversation-attributes="conversationAdditionalAttributes"
                  :contact-attributes="contactAdditionalAttributes"
                />
              </AccordionItem>
            </div>
            <div v-else-if="element.name === 'contact_attributes'">
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_ATTRIBUTES')"
                :is-open="
                  isContactSidebarItemOpen('is_contact_attributes_open')
                "
                compact
                @toggle="
                  value =>
                    toggleSidebarUIState('is_contact_attributes_open', value)
                "
              >
                <CustomAttributes
                  attribute-type="contact_attribute"
                  attribute-from="conversation_contact_panel"
                  :contact-id="contact.id"
                  :empty-state-message="
                    $t('CONVERSATION_CUSTOM_ATTRIBUTES.NO_RECORDS_FOUND')
                  "
                />
              </AccordionItem>
            </div>
            <div v-else-if="element.name === 'previous_conversation'">
              <AccordionItem
                v-if="contact.id"
                :title="
                  $t('CONVERSATION_SIDEBAR.ACCORDION.PREVIOUS_CONVERSATION')
                "
                :is-open="isContactSidebarItemOpen('is_previous_conv_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_previous_conv_open', value)
                "
              >
                <ContactConversations
                  :contact-id="contact.id"
                  :conversation-id="conversationId"
                />
              </AccordionItem>
            </div>
            <woot-feature-toggle
              v-else-if="element.name === 'macros'"
              feature-key="macros"
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.MACROS')"
                :is-open="isContactSidebarItemOpen('is_macro_open')"
                compact
                @toggle="value => toggleSidebarUIState('is_macro_open', value)"
              >
                <MacrosList :conversation-id="conversationId" />
              </AccordionItem>
            </woot-feature-toggle>
            <div
              v-else-if="
                element.name === 'shopify_orders' && isShopifyFeatureEnabled
              "
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.SHOPIFY_ORDERS')"
                :is-open="isContactSidebarItemOpen('is_shopify_orders_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_shopify_orders_open', value)
                "
              >
                <ShopifyOrdersList :contact-id="contactId" />
              </AccordionItem>
            </div>
            <div v-else-if="element.name === 'contact_notes'">
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_NOTES')"
                :is-open="isContactSidebarItemOpen('is_contact_notes_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_contact_notes_open', value)
                "
              >
                <ContactNotes :contact-id="contactId" />
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
    @apply pb-3 border-b border-solid border-slate-75 dark:border-slate-700;
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
}
</style>
