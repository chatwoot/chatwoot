<template>
  <div class="medium-3 bg-white contact--panel">
    <woot-button
      icon="chevron-right"
      class="close-button clear secondary"
      @click="onPanelToggle"
    />
    <contact-info :contact="contact" :channel-type="channelType" />
    <draggable
      :list="conversationSidebarItems"
      :disabled="!dragEnabled"
      class="list-group"
      ghost-class="ghost"
      @start="dragging = true"
      @end="onDragEnd"
    >
      <transition-group>
        <div
          v-for="element in conversationSidebarItems"
          :key="element.name"
          class="list-group-item"
        >
          <div
            v-if="element.name === 'conversation_actions'"
            class="conversation--actions"
          >
            <accordion-item
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_ACTIONS')"
              :is-open="isContactSidebarItemOpen('is_conv_actions_open')"
              @click="
                value => toggleSidebarUIState('is_conv_actions_open', value)
              "
            >
              <conversation-action
                :conversation-id="conversationId"
                :inbox-id="inboxId"
              />
            </accordion-item>
          </div>
          <div v-else-if="element.name === 'conversation_info'">
            <accordion-item
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_INFO')"
              :is-open="isContactSidebarItemOpen('is_conv_details_open')"
              compact
              @click="
                value => toggleSidebarUIState('is_conv_details_open', value)
              "
            >
              <conversation-info
                :conversation-attributes="conversationAdditionalAttributes"
                :contact-attributes="contactAdditionalAttributes"
              >
              </conversation-info>
            </accordion-item>
          </div>
          <div v-else-if="element.name === 'contact_attributes'">
            <accordion-item
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_ATTRIBUTES')"
              :is-open="isContactSidebarItemOpen('is_contact_attributes_open')"
              compact
              @click="
                value =>
                  toggleSidebarUIState('is_contact_attributes_open', value)
              "
            >
              <custom-attributes
                attribute-type="contact_attribute"
                attribute-class="conversation--attribute"
                class="even"
                :contact-id="contact.id"
              />
              <custom-attribute-selector
                attribute-type="contact_attribute"
                :contact-id="contact.id"
              />
            </accordion-item>
          </div>
          <div v-else-if="element.name === 'previous_conversation'">
            <accordion-item
              v-if="contact.id"
              :title="
                $t('CONVERSATION_SIDEBAR.ACCORDION.PREVIOUS_CONVERSATION')
              "
              :is-open="isContactSidebarItemOpen('is_previous_conv_open')"
              @click="
                value => toggleSidebarUIState('is_previous_conv_open', value)
              "
            >
              <contact-conversations
                :contact-id="contact.id"
                :conversation-id="conversationId"
              />
            </accordion-item>
          </div>
        </div>
      </transition-group>
    </draggable>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import AccordionItem from 'dashboard/components/Accordion/AccordionItem';
import ContactConversations from './ContactConversations.vue';
import ConversationAction from './ConversationAction.vue';

import ContactInfo from './contact/ContactInfo';
import ConversationInfo from './ConversationInfo';
import CustomAttributes from './customAttributes/CustomAttributes.vue';
import CustomAttributeSelector from './customAttributes/CustomAttributeSelector.vue';
import draggable from 'vuedraggable';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

export default {
  components: {
    AccordionItem,
    ContactConversations,
    ContactInfo,
    ConversationInfo,
    CustomAttributes,
    CustomAttributeSelector,
    ConversationAction,
    draggable,
  },
  mixins: [alertMixin, uiSettingsMixin],
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
      currentUser: 'getCurrentUser',
      uiFlags: 'inboxAssignableAgents/getUIFlags',
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

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';

.contact--panel {
  background: white;
  border-left: 1px solid var(--color-border);
  font-size: $font-size-small;
  overflow-y: auto;
  overflow: auto;
  position: relative;

  i {
    margin-right: $space-smaller;
  }
}

::v-deep {
  .contact--profile {
    padding-bottom: var(--space-slab);
    border-bottom: 1px solid var(--color-border);
  }
  .conversation--actions .multiselect-wrap--small {
    .multiselect {
      padding-left: var(--space-medium);
      box-sizing: border-box;
    }
    .multiselect__element {
      span {
        width: 100%;
      }
    }
  }
}

.close-button {
  position: absolute;
  right: $space-two;
  top: $space-slab;
  font-size: $font-size-default;
  color: $color-heading;
  z-index: 9989;
}

.conversation--labels {
  padding: $space-medium;

  .icon {
    margin-right: $space-micro;
    font-size: $font-size-micro;
    color: #fff;
  }

  .label {
    color: #fff;
    padding: 0.2rem;
  }
}

.contact--mute {
  color: $alert-color;
  display: block;
  text-align: left;
}

.contact--actions {
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.contact-info {
  margin-top: var(--space-two);
}
</style>
