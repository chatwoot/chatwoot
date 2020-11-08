<template>
  <div class="medium-3 bg-white contact--panel">
    <span class="close-button" @click="onPanelToggle">
      <i class="ion-chevron-right" />
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
import ContactConversations from 'dashboard/routes/dashboard/conversation/ContactConversations.vue';
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
    onToggle: {
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
  methods: {
    onPanelToggle() {
      this.onToggle();
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
  font-size: $font-size-small;
  overflow-y: auto;
  overflow: auto;
  position: relative;
  padding: $space-one;

  i {
    margin-right: $space-smaller;
  }
}

.close-button {
  position: absolute;
  right: $space-normal;
  top: $space-slab;
  font-size: $font-size-default;
  color: $color-heading;
}

.conversation--details {
  border-top: 1px solid $color-border-light;
  padding: $space-normal;
}

.contact-conversation--panel {
  border-top: 1px solid $color-border-light;
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
</style>
