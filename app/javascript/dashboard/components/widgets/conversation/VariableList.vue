<script>
import { mapGetters } from 'vuex';
import { MESSAGE_VARIABLES } from 'shared/constants/messages';
import MentionBox from '../mentions/MentionBox.vue';

export default {
  components: { MentionBox },
  props: {
    searchKey: {
      type: String,
      default: '',
    },
  },
  emits: ['selectVariable'],
  computed: {
    ...mapGetters({
      customAttributes: 'attributes/getAttributes',
    }),
    items() {
      return [
        ...this.standardAttributeVariables,
        ...this.customAttributeVariables,
      ];
    },
    standardAttributeVariables() {
      return MESSAGE_VARIABLES.filter(variable => {
        return (
          variable.label.includes(this.searchKey) ||
          variable.key.includes(this.searchKey)
        );
      }).map(variable => ({
        label: variable.key,
        key: variable.key,
        description: variable.label,
      }));
    },
    customAttributeVariables() {
      return this.customAttributes.map(attribute => {
        const attributePrefix =
          attribute.attribute_model === 'conversation_attribute'
            ? 'conversation'
            : 'contact';

        return {
          label: `${attributePrefix}.custom_attribute.${attribute.attribute_key}`,
          key: `${attributePrefix}.custom_attribute.${attribute.attribute_key}`,
          description: attribute.attribute_description,
        };
      });
    },
  },
  methods: {
    handleVariableClick(item = {}) {
      this.$emit('selectVariable', item.key);
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <MentionBox
    v-if="items.length"
    type="variable"
    :items="items"
    @mention-select="handleVariableClick"
  />
</template>

<style scoped>
.variable--list-label {
  font-weight: var(--font-weight-bold);
}
</style>
