<template>
  <div
    class="small-12 medium-3 bg-white contact--panel"
    :class="{ 'border-left': showAvatar }"
  >
    <span v-if="showAvatar" class="close-button" @click="onClose">
      <fluent-icon icon="dismiss" class="close-icon" />
    </span>
    <contact-info
      :show-avatar="showAvatar"
      :contact="contact"
      @panel-close="onClose"
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
                :custom-attributes="contact.custom_attributes"
                class="even"
              />
              <custom-attribute-selector
                attribute-type="contact_attribute"
                :contact-id="contact.id"
              />
            </accordion-item>
          </div>
          <div v-if="element.name === 'contact_labels'">
            <accordion-item
              :title="$t('CONTACT_PANEL.SIDEBAR_SECTIONS.CONTACT_LABELS')"
              :is-open="isContactSidebarItemOpen('is_ct_labels_open')"
              @click="value => toggleSidebarUIState('is_ct_labels_open', value)"
            >
              <contact-label :contact-id="contact.id" class="contact-labels" />
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
import AccordionItem from 'dashboard/components/Accordion/AccordionItem';
import ContactConversations from 'dashboard/routes/dashboard/conversation/ContactConversations';
import ContactInfo from 'dashboard/routes/dashboard/conversation/contact/ContactInfo';
import ContactLabel from 'dashboard/routes/dashboard/contacts/components/ContactLabels.vue';
import CustomAttributes from 'dashboard/routes/dashboard/conversation/customAttributes/CustomAttributes.vue';
import CustomAttributeSelector from 'dashboard/routes/dashboard/conversation/customAttributes/CustomAttributeSelector.vue';
import draggable from 'vuedraggable';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

export default {
  components: {
    AccordionItem,
    ContactConversations,
    ContactInfo,
    ContactLabel,
    CustomAttributes,
    CustomAttributeSelector,
    draggable,
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
    padding-bottom: var(--space-slab);
    margin-bottom: var(--space-normal);
  }
}
.contact--panel {
  height: 100%;
  background: white;
  font-size: var(--font-size-small);
  overflow-y: auto;
  overflow: auto;
  position: relative;
  border-right: 1px solid var(--color-border);
}

.list-group {
  .list-group-item {
    background-color: var(--white);
  }
}

.close-button {
  position: absolute;
  right: var(--space-normal);
  top: 3.6rem;
  font-size: var(--font-size-big);
  color: var(--s-500);
  z-index: 1;

  .close-icon {
    margin-right: var(--space-smaller);
  }
}

.conversation--details {
  padding: 0 var(--space-normal);
}

.contact--mute {
  color: var(--r-400);
  display: block;
  text-align: left;
}

.contact--actions {
  display: flex;
  flex-direction: column;
  justify-content: center;
}
</style>
