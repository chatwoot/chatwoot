<template>
  <variable :items="items" @mention-select="handleVariableClick" />
</template>

<script>
import { MESSAGE_VARIABLES } from 'shared/constants/messages';
import Variable from '../variable/Variable.vue';

export default {
  components: { Variable },
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
      });
    },
  },
  methods: {
    handleVariableClick(item = {}) {
      this.$emit('click', item.key);
    },
  },
};
</script>
