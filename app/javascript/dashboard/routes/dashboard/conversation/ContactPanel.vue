<script>
import { mapGetters } from 'vuex';
import { useUISettings } from 'dashboard/composables/useUISettings';
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import ContactConversations from './ContactConversations.vue';
import ConversationAction from './ConversationAction.vue';
import ConversationParticipant from './ConversationParticipant.vue';

import ContactInfo from './contact/ContactInfo.vue';
import ConversationInfo from './ConversationInfo.vue';
import CustomAttributes from './customAttributes/CustomAttributes.vue';
import draggable from 'vuedraggable';
import MacrosList from './Macros/List.vue';
export default {
  components: {
    AccordionItem,
    ContactConversations,
    ContactInfo,
    ConversationInfo,
    CustomAttributes,
    ConversationAction,
    ConversationParticipant,
    Draggable: draggable,
    MacrosList,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
    inboxId: {
      type: Number,
      default: undefined,
    },
    onToggle: {
      type: Function,
      default: () => {},
    },
  },
  setup() {
    const {
      updateUISettings,
      isContactSidebarItemOpen,
      conversationSidebarItemsOrder,
      toggleSidebarUIState,
    } = useUISettings();

    return {
      updateUISettings,
      isContactSidebarItemOpen,
      conversationSidebarItemsOrder,
      toggleSidebarUIState,
    };
  },
  data() {
    return {
      dragEnabled: true,
      conversationSidebarItems: [],
      dragging: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    conversationAdditionalAttributes() {
      return this.currentConversationMetaData.additional_attributes || {};
    },
    channelType() {
      return this.currentChat.meta?.channel;
    },
    contact() {
      return this.$store.getters['contacts/getContact'](this.contactId);
    },
    contactAdditionalAttributes() {
      return this.contact.additional_attributes || {};
    },
    contactId() {
      return this.currentChat.meta?.sender?.id;
    },
    currentConversationMetaData() {
      return this.$store.getters[
        'conversationMetadata/getConversationMetadata'
      ](this.conversationId);
    },
    hasContactAttributes() {
      const { custom_attributes: customAttributes } = this.contact;
      return customAttributes && Object.keys(customAttributes).length;
    },
  },
  watch: {
    conversationId(newConversationId, prevConversationId) {
      if (newConversationId && newConversationId !== prevConversationId) {
        this.getContactDetails();
      }
    },
    contactId() {
      this.getContactDetails();
    },
  },
  mounted() {
    this.conversationSidebarItems = this.conversationSidebarItemsOrder;
    this.getContactDetails();
    this.$store.dispatch('attributes/get', 0);
  },
  methods: {
    onPanelToggle() {
      this.onToggle();
    },
    getContactDetails() {
      if (this.contactId) {
        this.$store.dispatch('contacts/show', { id: this.contactId });
      }
    },
    getAttributesByModel() {
      if (this.contactId) {
        this.$store.dispatch('contacts/show', { id: this.contactId });
      }
    },
    openTranscriptModal() {
      this.showTranscriptModal = true;
    },

    onDragEnd() {
      this.dragging = false;
      this.updateUISettings({
        conversation_sidebar_items_order: this.conversationSidebarItems,
      });
    },
  },
};
</script>

<template>
  <div
    class="overflow-y-auto bg-white border-l dark:bg-slate-900 text-slate-900 dark:text-slate-300 border-slate-50 dark:border-slate-800/50 rtl:border-l-0 rtl:border-r contact--panel"
  >
    <ContactInfo
      :contact="contact"
      :channel-type="channelType"
      @toggle-panel="onPanelToggle"
    />
    <Draggable
      :list="conversationSidebarItems"
      :disabled="!dragEnabled"
      animation="200"
      class="list-group"
      ghost-class="ghost"
      handle=".drag-handle"
      @start="dragging = true"
      @end="onDragEnd"
    >
      <transition-group>
        <div
          v-for="element in conversationSidebarItems"
          :key="element.name"
          class="bg-white dark:bg-gray-800"
        >
          <div
            v-if="element.name === 'conversation_actions'"
            class="conversation--actions"
          >
            <AccordionItem
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_ACTIONS')"
              :is-open="isContactSidebarItemOpen('is_conv_actions_open')"
              @click="
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
              @click="
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
              @click="
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
              :is-open="isContactSidebarItemOpen('is_contact_attributes_open')"
              compact
              @click="
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
              @click="
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
              @click="value => toggleSidebarUIState('is_macro_open', value)"
            >
              <MacrosList :conversation-id="conversationId" />
            </AccordionItem>
          </woot-feature-toggle>
        </div>
      </transition-group>
    </Draggable>
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
