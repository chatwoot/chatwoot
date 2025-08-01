<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" :on-close="onCancel">
    <div class="overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="'Resolve Conversation'"
        :header-content="'Add custom attributes to resolve the conversation'"
      />
      <div class="w-full form-container">
        <custom-attributes
          attribute-class="conversation--attribute"
          attribute-from="conversation_panel"
          attribute-type="conversation_attribute"
          :for-conversation-resolve="true"
        />
        <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
          <woot-button :disabled="!isAttributeValuesFilled" @click="onSubmit">
            Submit
          </woot-button>
          <button class="button clear" @click.prevent="onCancel">
            {{ $t('EMAIL_TRANSCRIPT.CANCEL') }}
          </button>
        </div>
      </div>
    </div>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import CustomAttributes from '../../../routes/dashboard/conversation/customAttributes/CustomAttributes.vue';
import attributeMixin from '../../../mixins/attributeMixin';

export default {
  name: 'CustomAttributesForm',
  components: {
    CustomAttributes,
  },
  mixins: [attributeMixin],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      attributeType: 'conversation_attribute',
    };
  },
  computed: {
    ...mapGetters({ currentChat: 'getSelectedChat' }),
    isAttributeValuesFilled() {
      // Get all attributes that are required before resolve
      const requiredAttributes = this.attributes.filter(
        attribute => attribute.required_before_resolve
      );

      // Check if all required attributes have values in custom_attributes
      return requiredAttributes.every(attribute => {
        const attributeValue =
          this.currentChat?.custom_attributes?.[attribute.attribute_key];
        return attributeValue && attributeValue.toString().trim() !== '';
      });
    },
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSubmit() {
      this.onCancel();
      this.$emit('submit');
    },
  },
};
</script>

<style>
.form-container {
  align-self: center;
  padding-left: 2rem;
  padding-right: 2rem;
  padding-top: 1rem;
  padding-bottom: 2rem;
}
</style>
