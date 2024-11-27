<script>
import Attribute from './ContactAttribute.vue';

export default {
  components: { Attribute },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['update', 'createAttribute'],

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
      this.$emit('createAttribute');
    },
    onCustomAttributeUpdate(key, value) {
      this.$emit('update', { custom_attributes: { [key]: value } });
    },
  },
};
</script>

<template>
  <div class="contact-fields">
    <h3 class="text-lg title">
      {{ $t('CONTACTS_PAGE.FIELDS') }}
    </h3>
    <Attribute
      :label="$t('CONTACT_PANEL.EMAIL_ADDRESS')"
      icon="mail"
      emoji=""
      :value="contact.email"
      show-edit
      @update="onEmailUpdate"
    />
    <Attribute
      :label="$t('CONTACT_PANEL.PHONE_NUMBER')"
      icon="call"
      emoji=""
      :value="contact.phone_number"
      show-edit
      @update="onPhoneUpdate"
    />
    <Attribute
      v-if="additionalAttributes.location"
      :label="$t('CONTACT_PANEL.LOCATION')"
      icon="map"
      emoji="🌍"
      :value="additionalAttributes.location"
      show-edit
      @update="onLocationUpdate"
    />
    <div
      v-for="attribute in customAttributekeys"
      :key="attribute"
      class="custom-attribute--row"
    >
      <Attribute
        :label="attribute"
        icon="chevron-right"
        :value="customAttributes[attribute]"
        show-edit
        @update="value => onCustomAttributeUpdate(attribute, value)"
      />
    </div>
    <woot-button
      size="small"
      variant="link"
      icon="add"
      @click="handleCustomCreate"
    >
      {{ $t('CUSTOM_ATTRIBUTES.ADD.TITLE') }}
    </woot-button>
  </div>
</template>

<style scoped lang="scss">
.contact-fields {
  margin-top: var(--space-medium);
}

.title {
  margin-bottom: var(--space-normal);
}
</style>
