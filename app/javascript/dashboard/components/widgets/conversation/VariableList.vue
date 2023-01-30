<template>
  <mention-box :items="items" @mention-select="handleVariableClick">
    <template slot-scope="{ item }">
      <span class="text-capitalize variable--list-label">
        {{ item.description }}
      </span>
      ({{ item.label }})
    </template>
  </mention-box>
</template>

<script>
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
  computed: {
    items() {
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
  },
  methods: {
    handleVariableClick(item = {}) {
      this.$emit('click', item.key);
    },
  },
};
</script>
<style scoped>
.variable--list-label {
  font-weight: var(--font-weight-bold);
}
</style>
