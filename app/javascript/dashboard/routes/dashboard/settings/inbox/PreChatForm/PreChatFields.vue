<script>
import Draggable from 'vuedraggable';

export default {
  components: { Draggable },
  props: {
    preChatFields: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['update', 'dragEnd'],
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
      this.$emit('dragEnd', this.preChatFieldOptions);
    },
  },
};
</script>

<template>
  <Draggable
    v-model="preChatFieldOptions"
    tag="tbody"
    item-key="name"
    @end="onDragEnd"
  >
    <template #item="{ element: item }">
      <tr>
        <td class="pre-chat-field"><fluent-icon icon="drag" /></td>
        <td class="pre-chat-field">
          <woot-switch
            :model-value="item['enabled']"
            @input="handlePreChatFieldOptions($event, 'enabled', item)"
          />
        </td>
        <td
          class="pre-chat-field"
          :class="{ 'disabled-text': !item['enabled'] }"
        >
          {{ item.name }}
        </td>
        <td
          class="pre-chat-field"
          :class="{ 'disabled-text': !item['enabled'] }"
        >
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
        <td
          class="pre-chat-field"
          :class="{ 'disabled-text': !item['enabled'] }"
        >
          <input
            v-model="item.label"
            type="text"
            :disabled="isFieldEditable(item)"
          />
        </td>
        <td
          class="pre-chat-field"
          :class="{ 'disabled-text': !item['enabled'] }"
        >
          <input
            v-model="item.placeholder"
            type="text"
            :disabled="isFieldEditable(item)"
          />
        </td>
      </tr>
    </template>
  </Draggable>
</template>

<style scoped lang="scss">
.pre-chat-field {
  @apply py-4 px-2 text-slate-700 dark:text-slate-100;

  svg {
    @apply flex items-center;
  }
}
.disabled-text {
  @apply text-slate-500 dark:text-slate-400;
}

table {
  thead th {
    @apply normal-case;
  }
  input {
    @apply text-sm mb-0;
  }
}
checkbox {
  @apply m-0;
}
</style>
