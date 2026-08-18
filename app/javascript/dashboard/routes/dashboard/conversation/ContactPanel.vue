<script setup>
import { computed, watch, onMounted, ref } from 'vue';
import {
  useMapGetter,
  useFunctionGetter,
  useStore,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import ContactConversations from './ContactConversations.vue';
import ConversationAction from './ConversationAction.vue';
import ConversationParticipant from './ConversationParticipant.vue';
import ContactInfo from './contact/ContactInfo.vue';
import ContactNotes from './contact/ContactNotes.vue';
import ConversationInfo from './ConversationInfo.vue';
import CustomAttributes from './customAttributes/CustomAttributes.vue';
import SharedFiles from './SharedFiles.vue';
import Draggable from 'vuedraggable';
import MacrosList from './Macros/List.vue';
import ShopifyOrdersList from 'dashboard/components/widgets/conversation/ShopifyOrdersList.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';
import SidebarVisibilityMenu from './SidebarVisibilityMenu.vue';
import LinearIssuesList from 'dashboard/components/widgets/conversation/linear/IssuesList.vue';
import LinearSetupCTA from 'dashboard/components/widgets/conversation/linear/LinearSetupCTA.vue';
import ConversationTasksPanel from 'dashboard/components-next/InternalTasks/ConversationTasksPanel.vue';
import CalendarEventsList from 'dashboard/components/widgets/conversation/CalendarEventsList.vue';

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
  conversationSidebarVisibleItems,
  toggleSidebarUIState,
} = useUISettings();

const dragging = ref(false);
const conversationSidebarItems = ref(conversationSidebarItemsOrder.value);

const isVisible = name => conversationSidebarVisibleItems.value.includes(name);

const hasVisibleItems = computed(() =>
  conversationSidebarItems.value.some(item => isVisible(item.name))
);

watch(
  conversationSidebarItemsOrder,
  newOrder => {
    if (!dragging.value) {
      conversationSidebarItems.value = newOrder;
    }
  },
  { deep: true }
);

const shopifyIntegration = useFunctionGetter(
  'integrations/getIntegration',
  'shopify'
);

const isShopifyFeatureEnabled = computed(
  () => shopifyIntegration.value.enabled
);

const { isCloudFeatureEnabled } = useAccount();

const accountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const hasInternalTasks = computed(() =>
  isFeatureEnabledonAccount.value(accountId.value, FEATURE_FLAGS.INTERNAL_TASKS)
);

const isLinearFeatureEnabled = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.LINEAR)
);

const linearIntegration = useFunctionGetter(
  'integrations/getIntegration',
  'linear'
);

const isLinearClientIdConfigured = computed(() => {
  return !!linearIntegration.value?.id;
});

const isLinearConnected = computed(
  () => linearIntegration.value?.enabled || false
);

const calendarIntegration = useFunctionGetter(
  'integrations/getIntegration',
  'calendars'
);

const isCalendarFeatureEnabled = computed(() =>
  isFeatureEnabledonAccount.value(accountId.value, FEATURE_FLAGS.CALENDAR)
);

const isCalendarConnected = computed(
  () => calendarIntegration.value?.enabled || false
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

const contactId = computed(() => currentChat.value.meta?.sender?.id);
const contact = useFunctionGetter('contacts/getContactById', contactId);
const contactAdditionalAttributes = computed(
  () =>
    contact.value.additionalAttributes ||
    contact.value.additional_attributes ||
    {}
);

const getContactDetails = () => {
  if (contactId.value) {
    store.dispatch('contacts/show', { id: contactId.value });
  }
};

watch(contactId, (newContactId, prevContactId) => {
  if (newContactId && newContactId !== prevContactId) {
    getContactDetails();
  }
});

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
  // Load integrations so Shopify/Linear gates (panel + visibility menu) are accurate
  store.dispatch('integrations/get');
});
</script>

<template>
  <div class="flex flex-col w-full h-full min-h-0">
    <SidebarActionsHeader
      :title="$t('CONVERSATION.SIDEBAR.CONTACT')"
      @close="closeContactPanel"
    >
      <template #actions>
        <SidebarVisibilityMenu />
      </template>
    </SidebarActionsHeader>
    <div class="flex-1 min-h-0 overflow-y-auto">
      <ContactInfo :contact="contact" :channel-type="channelType" />
      <div class="px-3 pb-6 list-group">
        <div
          v-if="!hasVisibleItems"
          class="flex flex-col items-center justify-center gap-2 py-8 text-center"
        >
          <span class="i-lucide-eye-off text-2xl text-n-slate-10" />
          <p class="text-sm text-n-slate-11">
            {{ $t('CONVERSATION.SIDEBAR.EMPTY_STATE') }}
          </p>
          <SidebarVisibilityMenu />
        </div>
        <Draggable
          v-else
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
            <div
              v-if="
                element.name === 'conversation_actions' &&
                isVisible('conversation_actions')
              "
              class="conversation--actions"
            >
              <AccordionItem
                :title="
                  $t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_ACTIONS')
                "
                icon="i-lucide-bolt"
                :is-open="isContactSidebarItemOpen('is_conv_actions_open')"
                compact
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
              v-else-if="
                element.name === 'conversation_participants' &&
                isVisible('conversation_participants')
              "
              class="conversation--actions"
            >
              <AccordionItem
                :title="$t('CONVERSATION_PARTICIPANTS.SIDEBAR_TITLE')"
                icon="i-lucide-users"
                :is-open="isContactSidebarItemOpen('is_conv_participants_open')"
                compact
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
            <div
              v-else-if="
                element.name === 'conversation_info' &&
                isVisible('conversation_info')
              "
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_INFO')"
                icon="i-lucide-messages-square"
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
            <div
              v-else-if="
                element.name === 'contact_attributes' &&
                isVisible('contact_attributes')
              "
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_ATTRIBUTES')"
                icon="i-lucide-contact"
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
            <div
              v-else-if="
                element.name === 'previous_conversation' &&
                isVisible('previous_conversation') &&
                contact.id
              "
            >
              <AccordionItem
                :title="
                  $t('CONVERSATION_SIDEBAR.ACCORDION.PREVIOUS_CONVERSATION')
                "
                icon="i-lucide-history"
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
              v-else-if="element.name === 'macros' && isVisible('macros')"
              feature-key="macros"
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.MACROS')"
                icon="i-lucide-toy-brick"
                :is-open="isContactSidebarItemOpen('is_macro_open')"
                compact
                @toggle="value => toggleSidebarUIState('is_macro_open', value)"
              >
                <MacrosList :conversation-id="conversationId" />
              </AccordionItem>
            </woot-feature-toggle>
            <div
              v-else-if="
                element.name === 'linear_issues' &&
                isVisible('linear_issues') &&
                isLinearFeatureEnabled &&
                isLinearClientIdConfigured
              "
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.LINEAR_ISSUES')"
                icon="i-lucide-circle-dot"
                :is-open="isContactSidebarItemOpen('is_linear_issues_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_linear_issues_open', value)
                "
              >
                <LinearSetupCTA v-if="!isLinearConnected" />
                <LinearIssuesList v-else :conversation-id="conversationId" />
              </AccordionItem>
            </div>
            <div
              v-else-if="
                element.name === 'calendar_events' &&
                isVisible('calendar_events') &&
                isCalendarFeatureEnabled
              "
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CALENDAR_EVENTS')"
                icon="i-lucide-calendar"
                :is-open="isContactSidebarItemOpen('is_calendar_events_open')"
                compact
                @toggle="
                  value =>
                    toggleSidebarUIState('is_calendar_events_open', value)
                "
              >
                <CalendarEventsList
                  v-if="isCalendarConnected"
                  :conversation-id="conversationId"
                  :contact-id="contactId"
                  :contact-name="contact.name"
                />
                <p v-else class="px-4 py-3 text-sm text-n-slate-11">
                  {{ $t('CONVERSATION_SIDEBAR.CALENDAR.NOT_CONNECTED') }}
                </p>
              </AccordionItem>
            </div>
            <div
              v-else-if="
                element.name === 'shopify_orders' &&
                isVisible('shopify_orders') &&
                isShopifyFeatureEnabled
              "
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.SHOPIFY_ORDERS')"
                icon="i-lucide-shopping-bag"
                :is-open="isContactSidebarItemOpen('is_shopify_orders_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_shopify_orders_open', value)
                "
              >
                <ShopifyOrdersList :contact-id="contactId" />
              </AccordionItem>
            </div>
            <div
              v-else-if="
                element.name === 'contact_notes' && isVisible('contact_notes')
              "
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_NOTES')"
                icon="i-lucide-notebook-pen"
                :is-open="isContactSidebarItemOpen('is_contact_notes_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_contact_notes_open', value)
                "
              >
                <ContactNotes :contact-id="contactId" />
              </AccordionItem>
            </div>
            <div
              v-else-if="
                element.name === 'internal_tasks' &&
                isVisible('internal_tasks') &&
                hasInternalTasks
              "
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.INTERNAL_TASKS')"
                icon="i-lucide-list-checks"
                :is-open="isContactSidebarItemOpen('is_internal_tasks_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_internal_tasks_open', value)
                "
              >
                <ConversationTasksPanel :conversation-id="conversationId" />
              </AccordionItem>
            </div>
            <div
              v-else-if="
                element.name === 'shared_files' && isVisible('shared_files')
              "
            >
              <AccordionItem
                :title="$t('CONVERSATION_SIDEBAR.ACCORDION.SHARED_FILES')"
                icon="i-lucide-paperclip"
                :is-open="isContactSidebarItemOpen('is_shared_files_open')"
                compact
                @toggle="
                  value => toggleSidebarUIState('is_shared_files_open', value)
                "
              >
                <SharedFiles />
              </AccordionItem>
            </div>
          </template>
        </Draggable>
      </div>
    </div>
  </div>
</template>
