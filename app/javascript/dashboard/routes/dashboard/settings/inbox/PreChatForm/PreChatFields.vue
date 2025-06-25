<template>
  <draggable v-model="preChatFieldOptions" tag="tbody" @end="onDragEnd">
    <tr v-for="(item, index) in preChatFieldOptions" :key="index">
      <td class="pre-chat-field"><fluent-icon icon="drag" /></td>
      <td class="pre-chat-field">
        <woot-switch
          :value="item['enabled']"
          @input="handlePreChatFieldOptions($event, 'enabled', item)"
        />
      </td>
      <td class="pre-chat-field" :class="{ 'disabled-text': !item['enabled'] }">
        {{ item.name }}
      </td>
      <td class="pre-chat-field" :class="{ 'disabled-text': !item['enabled'] }">
        {{ item.type }}
      </td>
      <td class="pre-chat-field">
        <input
          v-model="item['required']"
          type="checkbox"
          :value="`${item.name}-required`"
          :disabled="!item['enabled']"
          @click="handlePreChatFieldOptions($event, 'required', item)"
        />
      </td>
      <td class="pre-chat-field" :class="{ 'disabled-text': !item['enabled'] }">
        <input
          v-model.trim="item.label"
          type="text"
          :disabled="isFieldEditable(item)"
        />
      </td>
      <td class="pre-chat-field" :class="{ 'disabled-text': !item['enabled'] }">
        <input
          v-model.trim="item.placeholder"
          type="text"
          :disabled="isFieldEditable(item)"
        />
      </td>
    </tr>
  </draggable>
</template>

<script>
import draggable from 'vuedraggable';
export default {
  components: { draggable },
  props: {
    preChatFields: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      preChatFieldOptions: this.preChatFields,
    };
  },
  watch: {
    preChatFields() {
      this.preChatFieldOptions = this.preChatFields;
    },
  },
  methods: {
    isFieldEditable(item) {
      return !item.enabled;
    },
    handlePreChatFieldOptions(event, type, item) {
      this.$emit('update', event, type, item);
    },
    onDragEnd() {
      this.$emit('drag-end', this.preChatFieldOptions);
    },
  },
};
</script>
<style scoped lang="scss">
.pre-chat-field {
  padding: var(--space-normal) var(--space-small);

  svg {
    display: flex;
    align-items: center;
  }
}
.disabled-text {
  color: var(--s-500);
}

table {
  thead th {
    text-transform: none;
  }
  input {
    font-size: var(--font-size-small);
    margin-bottom: 0;
  }
}
checkbox {
  margin: 0;
}
</style>
