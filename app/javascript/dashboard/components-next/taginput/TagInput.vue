<script setup>
import { ref, computed, watch } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';

import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  placeholder: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  type: { type: String, default: 'text' },
  isLoading: { type: Boolean, default: false },
  menuItems: {
    type: Array,
    default: () => [],
    validator: value =>
      value.every(
        ({ action, value: tagValue, label }) => action && tagValue && label
      ),
  },
  showDropdown: { type: Boolean, default: false },
  mode: {
    type: String,
    default: 'multiple',
    validator: value => ['single', 'multiple'].includes(value),
  },
  focusOnMount: { type: Boolean, default: false },
  allowCreate: { type: Boolean, default: false },
});

const emit = defineEmits([
  'update:modelValue',
  'input',
  'blur',
  'focus',
  'onClickOutside',
  'add',
  'remove',
]);

const modelValue = defineModel({
  type: Array,
  default: () => [],
});

const MODE = {
  SINGLE: 'single',
  MULTIPLE: 'multiple',
};

const tagInputRef = ref(null);
const tags = ref(props.modelValue);
const newTag = ref('');
const isFocused = ref(true);

const rules = computed(() => ({
  newTag: props.type === 'email' ? { email } : {},
}));

const v$ = useVuelidate(rules, { newTag });
const isNewTagInValidType = computed(() => v$.value.$invalid);

const showInput = computed(() =>
  props.mode === MODE.SINGLE
    ? isFocused.value && !tags.value.length
    : isFocused.value || !tags.value.length
);

const showDropdownMenu = computed(() =>
  props.mode === MODE.SINGLE && tags.value.length >= 1
    ? false
    : props.showDropdown
);

const filteredMenuItems = computed(() => {
  if (props.mode === MODE.SINGLE && tags.value.length >= 1) return [];

  const availableMenuItems = props.menuItems.filter(
    item => !tags.value.includes(item.label)
  );

  // Show typed value as suggestion only if:
  // 1. There's a value being typed
  // 2. The value isn't already in the tags
  // 3. Email validation passes (if type is email) and There are no menu items available
  const trimmedNewTag = newTag.value?.trim();
  const shouldShowTypedValue =
    trimmedNewTag &&
    !tags.value.includes(trimmedNewTag) &&
    !props.isLoading &&
    !availableMenuItems.length &&
    (props.type === 'email' ? !isNewTagInValidType.value : true);

  if (shouldShowTypedValue) {
    return [
      {
        label: trimmedNewTag,
        value: trimmedNewTag,
        email: trimmedNewTag,
        thumbnail: { name: trimmedNewTag, src: '' },
        action: 'create',
      },
    ];
  }

  return availableMenuItems;
});

const emitDataOnAdd = emailValue => {
  const matchingMenuItem = props.menuItems.find(
    item => item.email === emailValue
  );

  return matchingMenuItem
    ? emit('add', { email: emailValue, ...matchingMenuItem })
    : emit('add', { value: emailValue, action: 'create' });
};

const addTag = async () => {
  const trimmedTag = newTag.value?.trim();
  if (!trimmedTag) return;

  if (props.mode === MODE.SINGLE && tags.value.length >= 1) {
    newTag.value = '';
    return;
  }

  if (props.type === 'email' || props.allowCreate) {
    if (!(await v$.value.$validate())) return;
    emitDataOnAdd(trimmedTag);
  }

  tags.value.push(trimmedTag);
  newTag.value = '';
  modelValue.value = tags.value;
  tagInputRef.value?.focus();
};

const removeTag = index => {
  tags.value.splice(index, 1);
  modelValue.value = tags.value;
  emit('remove');
};

const handleDropdownAction = async ({ email: emailAddress, ...rest }) => {
  if (props.mode === MODE.SINGLE && tags.value.length >= 1) return;

  if (props.type === 'email' && props.showDropdown) {
    newTag.value = emailAddress;
    if (!(await v$.value.$validate())) return;
    emit('add', { email: emailAddress, ...rest });
  }

  tags.value.push(emailAddress);
  newTag.value = '';
  modelValue.value = tags.value;
  tagInputRef.value?.focus();
};

const handleFocus = () => {
  emit('focus');
  tagInputRef.value?.focus();
  isFocused.value = true;
};

const handleKeydown = event => {
  if (event.key === ',') {
    event.preventDefault();
    addTag();
  }
};

const handleClickOutside = () => {
  if (tags.value.length) isFocused.value = false;
  emit('onClickOutside');
};

watch(
  () => props.modelValue,
  newValue => {
    tags.value = newValue;
  }
);

watch(
  () => newTag.value,
  async newValue => {
    if (props.type === 'email' && newValue?.trim()?.length > 2) {
      await v$.value.$validate();
    }
  }
);

const handleInput = e => emit('input', e);
const handleBlur = e => emit('blur', e);
</script>

<template>
  <div
    v-on-click-outside="() => handleClickOutside()"
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
      <span class="flex-grow min-w-0 text-sm truncate text-n-slate-12">{{
        tag
      }}</span>
      <span
        class="flex-shrink-0 cursor-pointer i-lucide-x size-3.5 text-n-slate-11"
        @click.stop="removeTag(index)"
      />
    </div>
    <div
      v-if="showInput || showDropdownMenu"
      class="relative flex items-center gap-2 flex-1 min-w-[200px] w-full"
    >
      <InlineInput
        ref="tagInputRef"
        v-model="newTag"
        :placeholder="placeholder"
        :type="type"
        :disabled="disabled"
        class="w-full"
        :focus-on-mount="focusOnMount"
        :custom-input-class="`w-full ${isNewTagInValidType ? '!text-n-ruby-9 dark:!text-n-ruby-9' : ''}`"
        @enter-press="addTag"
        @focus="handleFocus"
        @input="handleInput"
        @blur="handleBlur"
        @keydown="handleKeydown"
      />
      <DropdownMenu
        v-if="showDropdownMenu"
        :menu-items="filteredMenuItems"
        :is-searching="isLoading"
        class="left-0 z-[100] top-8 overflow-y-auto max-h-60 w-[inherit] max-w-md dark:!outline-n-slate-5"
        @action="handleDropdownAction"
      />
    </div>
  </div>
</template>
