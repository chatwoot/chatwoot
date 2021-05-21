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
    <div
      v-for="attribute in customAttributekeys"
      :key="attribute"
      class="custom-attribute--row"
    >
      <attribute
        :label="attribute"
        icon="ion-arrow-right-c"
        :value="customAttributes[attribute]"
        :show-edit="true"
        @update="value => onCustomAttributeUpdate(attribute, value)"
      />
    </div>
    <woot-button
      size="small"
      variant="link"
      icon="ion-plus"
      @click="handleCustomCreate"
    >
      {{ $t('CUSTOM_ATTRIBUTES.ADD.TITLE') }}
    </woot-button>
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
    customAttributes() {
      const { custom_attributes: customAttributes = {} } = this.contact;
      return customAttributes;
    },
    customAttributekeys() {
      return Object.keys(this.customAttributes).filter(key => {
        const value = this.customAttributes[key];
        return value !== null && value !== undefined;
      });
    },
  },
  methods: {
    onEmailUpdate(value) {
      this.$emit('update', { email: value });
    },
    onPhoneUpdate(value) {
      this.$emit('update', { phone_number: value });
    },
    onLocationUpdate(value) {
      this.$emit('update', { location: value });
    },
    handleCustomCreate() {
      this.$emit('create-attribute');
    },
    onCustomAttributeUpdate(key, value) {
      this.$emit('update', { custom_attributes: { [key]: value } });
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
