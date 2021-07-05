<template>
  <div class="medium-3 bg-white contact--panel">
    <span class="close-button" @click="onClose">
      <i class="ion-android-close close-icon" />
    </span>
    <contact-info show-new-message :contact="contact" />
    <contact-custom-attributes
      v-if="hasContactAttributes"
      :custom-attributes="contact.custom_attributes"
    />
    <contact-label :contact-id="contact.id" class="contact-labels" />
    <contact-conversations
      v-if="contact.id"
      :contact-id="contact.id"
      conversation-id=""
    />
  </div>
</template>

<script>
import ContactConversations from 'dashboard/routes/dashboard/conversation/ContactConversations';
import ContactInfo from 'dashboard/routes/dashboard/conversation/contact/ContactInfo';
import ContactCustomAttributes from 'dashboard/routes/dashboard/conversation/ContactCustomAttributes';
import ContactLabel from 'dashboard/routes/dashboard/contacts/components/ContactLabels.vue';

export default {
  components: {
    ContactCustomAttributes,
    ContactConversations,
    ContactInfo,
    ContactLabel,
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
  border-left: 1px solid var(--color-border);
  padding: var(--space-medium) var(--space-two);

  .contact-labels {
    padding-bottom: var(--space-normal);
  }
}

.close-button {
  position: absolute;
  right: var(--space-normal);
  top: var(--space-slab);
  font-size: var(--font-size-big);
  color: var(--color-heading);

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
