<script setup>
import { ref, watch } from 'vue';
import Draggable from 'vuedraggable';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  preChatFields: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update', 'dragEnd']);

const preChatFieldOptions = ref(props.preChatFields);

const isFieldEditable = item => {
  return !item.enabled;
};

const handlePreChatFieldOptions = (event, type, item) => {
  emit('update', event, type, item);
};

const onDragEnd = () => {
  emit('dragEnd', preChatFieldOptions.value);
};

watch(
  () => props.preChatFields,
  newFields => {
    preChatFieldOptions.value = newFields;
  }
);
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
        <td class="py-4 ltr:pl-4 ltr:pr-3 rtl:pl-3 rtl:pr-4 text-body-main">
          <Icon
            icon="i-woot-drag-indicator"
            class="size-4 text-n-slate-11 mt-1 cursor-move"
          />
        </td>
        <td class="py-4 ltr:pr-3 rtl:pl-3 text-body-main">
          <ToggleSwitch
            :model-value="item['enabled']"
            @change="handlePreChatFieldOptions($event, 'enabled', item)"
          />
        </td>
        <td
          class="py-4 ltr:pr-3 rtl:pl-3 text-body-main"
          :class="{ 'text-n-slate-11': !item['enabled'] }"
        >
          {{ item.name }}
        </td>
        <td
          class="py-4 ltr:pr-3 rtl:pl-3 text-body-main"
          :class="{ 'text-n-slate-11': !item['enabled'] }"
        >
          {{ item.type }}
        </td>
        <td class="py-4 ltr:pr-3 rtl:pl-3 text-body-main">
          <input
            v-model="item['required']"
            type="checkbox"
            :value="`${item.name}-required`"
            :disabled="!item['enabled']"
            class="m-0"
            @click="handlePreChatFieldOptions($event, 'required', item)"
          />
        </td>
        <td
          class="py-4 ltr:pr-3 rtl:pl-3 text-body-main"
          :class="{ 'text-n-slate-11': !item['enabled'] }"
        >
          <input
            v-model="item.label"
            type="text"
            :disabled="isFieldEditable(item)"
            class="w-full text-sm !mb-0 px-2 py-1 border border-n-weak rounded"
          />
        </td>
        <td
          class="py-4 ltr:pr-4 rtl:pl-4 text-body-main"
          :class="{ 'text-n-slate-11': !item['enabled'] }"
        >
          <input
            v-model="item.placeholder"
            type="text"
            :disabled="isFieldEditable(item)"
            class="w-full text-sm !mb-0 px-2 py-1 border border-n-weak rounded"
          />
        </td>
      </tr>
    </template>
  </Draggable>
</template>
