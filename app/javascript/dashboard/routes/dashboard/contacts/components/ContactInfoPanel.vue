<template>
  <div class="medium-3 bg-white contact--panel">
    <span class="close-button" @click="onClose">
      <i class="ion-android-close close-icon" />
    </span>
    <contact-info :contact="contact" />
    <contact-custom-attributes
      v-if="hasContactAttributes"
      :custom-attributes="contact.custom_attributes"
    />
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

export default {
  components: {
    ContactCustomAttributes,
    ContactConversations,
    ContactInfo,
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
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.contact--panel {
  @include border-normal-left;

  background: white;
  font-size: var(--font-size-small);
  overflow-y: auto;
  overflow: auto;
  position: relative;
  padding: var(--space-one);
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
  border-top: 1px solid $color-border-light;
  padding: var(--space-normal);
}

.contact-conversation--panel {
  border-top: 1px solid $color-border-light;
  height: 100%;
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
