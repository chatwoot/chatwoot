<template>
  <div
    class="small-12 medium-3 bg-white contact--panel"
    :class="{ 'border-left': showAvatar }"
  >
    <span v-if="showAvatar" class="close-button" @click="onClose">
      <i class="ion-android-close close-icon" />
    </span>
    <contact-info
      :show-avatar="showAvatar"
      show-new-message
      :contact="contact"
      @panel-close="onClose"
    />
    <accordion-item
      :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_ATTRIBUTES')"
      :is-open="isContactSidebarItemOpen('is_ct_custom_attr_open')"
      compact
      @click="value => toggleSidebarUIState('is_ct_custom_attr_open', value)"
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
    <accordion-item
      :title="$t('CONTACT_PANEL.SIDEBAR_SECTIONS.CONTACT_LABELS')"
      :is-open="isContactSidebarItemOpen('is_ct_labels_open')"
      @click="value => toggleSidebarUIState('is_ct_labels_open', value)"
    >
      <contact-label :contact-id="contact.id" class="contact-labels" />
    </accordion-item>
    <accordion-item
      :title="$t('CONTACT_PANEL.SIDEBAR_SECTIONS.PREVIOUS_CONVERSATIONS')"
      :is-open="isContactSidebarItemOpen('is_ct_prev_conv_open')"
      @click="value => toggleSidebarUIState('is_ct_prev_conv_open', value)"
    >
      <contact-conversations
        v-if="contact.id"
        :contact-id="contact.id"
        conversation-id=""
      />
    </accordion-item>
  </div>
</template>

<script>
import AccordionItem from 'dashboard/components/Accordion/AccordionItem';
import ContactConversations from 'dashboard/routes/dashboard/conversation/ContactConversations';
import ContactInfo from 'dashboard/routes/dashboard/conversation/contact/ContactInfo';
import ContactLabel from 'dashboard/routes/dashboard/contacts/components/ContactLabels.vue';
import CustomAttributes from 'dashboard/routes/dashboard/conversation/customAttributes/CustomAttributes.vue';
import CustomAttributeSelector from 'dashboard/routes/dashboard/conversation/customAttributes/CustomAttributeSelector.vue';

import uiSettingsMixin from 'dashboard/mixins/uiSettings';

export default {
  components: {
    AccordionItem,
    ContactConversations,
    ContactInfo,
    ContactLabel,
    CustomAttributes,
    CustomAttributeSelector,
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
  computed: {
    hasContactAttributes() {
      const { custom_attributes: customAttributes } = this.contact;
      return customAttributes && Object.keys(customAttributes).length;
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
