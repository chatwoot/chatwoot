<template>
  <div class="contact-fields">
    <h3 class="block-title title">Contact fields</h3>
    <attribute
      :label="$t('CONTACT_PANEL.EMAIL_ADDRESS')"
      icon="ion-email"
      emoji=""
      :value="contact.email"
      :show-edit="true"
      @update="onEmailUpdate"
    />
    <attribute
      :label="$t('CONTACT_PANEL.PHONE_NUMBER')"
      icon="ion-ios-telephone"
      emoji=""
      :value="contact.phone_number"
      :show-edit="true"
      @update="onPhoneUpdate"
    />
    <attribute
      v-if="additionalAttributes.location"
      :label="$t('CONTACT_PANEL.LOCATION')"
      icon="ion-map"
      emoji="🌍"
      :value="additionalAttributes.location"
      :show-edit="true"
      @update="onLocationUpdate"
    />
  </div>
</template>
<script>
import Attribute from './ContactAttribute';

export default {
  components: { Attribute },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
  },

  computed: {
    additionalAttributes() {
      return this.contact.additional_attributes || {};
    },
    company() {
      const { company = {} } = this.contact;
      return company;
    },
  },
  methods: {
    onEmailUpdate(value) {
      this.$emit('update', { email: value });
    },
    onPhoneUpdate(value) {
      this.$emit('update', { phone: value });
    },
    onLocationUpdate(value) {
      this.$emit('update', { location: value });
    },
  },
};
</script>

<style scoped lang="scss">
.contact-fields {
  margin-top: var(--space-medium);
}

.title {
  margin-bottom: var(--space-normal);
}
</style>
