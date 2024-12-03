<script setup>
import { ref, computed, watch } from 'vue';
import { OnClickOutside } from '@vueuse/components';

import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
  placeholder: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue']);

const tags = ref(props.modelValue);
const newTag = ref('');
const isFocused = ref(false);

const showInput = computed(() => isFocused.value || tags.value.length === 0);

const addTag = () => {
  if (newTag.value.trim()) {
    tags.value.push(newTag.value.trim());
    newTag.value = '';
    emit('update:modelValue', tags.value);
  }
};

const removeTag = index => {
  tags.value.splice(index, 1);
  emit('update:modelValue', tags.value);
};

const handleFocus = () => {
  isFocused.value = true;
};

const handleClickOutside = () => {
  if (tags.value.length > 0) {
    isFocused.value = false;
  }
};

const handleKeydown = event => {
  if (event.key === ',') {
    event.preventDefault();
    addTag();
  }
};

watch(
  () => props.modelValue,
  newValue => {
    tags.value = newValue;
  }
);
</script>

<template>
  <OnClickOutside @trigger="handleClickOutside">
    <div
      class="flex flex-wrap w-full gap-2 border border-transparent focus:outline-none"
      tabindex="0"
      @focus="handleFocus"
      @click="handleFocus"
    >
      <div
        v-for="(tag, index) in tags"
        :key="index"
        class="flex items-center justify-center max-w-full gap-1 px-3 py-1 rounded-lg h-7 bg-n-alpha-2"
      >
        <span class="flex-grow min-w-0 text-sm truncate text-n-slate-12">
          {{ tag }}
        </span>
        <span
          class="flex-shrink-0 cursor-pointer i-lucide-x size-3.5 text-n-slate-11"
          @click.stop="removeTag(index)"
        />
      </div>
      <InlineInput
        v-if="showInput"
        v-model="newTag"
        :placeholder="placeholder"
        custom-input-class="flex-grow"
        @enter-press="addTag"
        @keydown="handleKeydown"
      />
    </div>
  </OnClickOutside>
</template>
