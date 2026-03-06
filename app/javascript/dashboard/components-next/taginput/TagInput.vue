<script setup>
import { ref, computed, watch } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { useVuelidate } from '@vuelidate/core';

import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import {
  MODE,
  INPUT_TYPES,
  getValidationRules,
  checkTagTypeValidity,
  buildTagMenuItems,
  canAddTag,
  findMatchingMenuItem,
} from './helper/tagInputHelper';

const props = defineProps({
  placeholder: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  type: { type: String, default: INPUT_TYPES.TEXT },
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
    default: MODE.MULTIPLE,
    validator: value => [MODE.SINGLE, MODE.MULTIPLE].includes(value),
  },
  focusOnMount: { type: Boolean, default: false },
  allowCreate: { type: Boolean, default: false },
  // Skip label-based dedup when the consumer already filters menuItems by ID.
  // Prevents removing all same-name items when one is selected (e.g. duplicate agent names).
  skipLabelDedup: { type: Boolean, default: false },
  // When false, the dropdown won't auto-open on mount; it opens only on click/focus.
  autoOpenDropdown: { type: Boolean, default: true },
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

const tagInputRef = ref(null);
const tags = ref(props.modelValue);
const newTag = ref('');
const isFocused = ref(props.autoOpenDropdown);

const rules = computed(() => getValidationRules(props.type));
const v$ = useVuelidate(rules, { newTag });

const isNewTagInValidType = computed(() =>
  checkTagTypeValidity(props.type, newTag.value, v$.value)
);

const showInput = computed(() =>
  props.mode === MODE.SINGLE
    ? isFocused.value && !tags.value.length
    : isFocused.value || !tags.value.length
);

const showDropdownMenu = computed(() =>
  props.mode === MODE.SINGLE && tags.value.length >= 1
    ? false
    : props.showDropdown && isFocused.value
);

const filteredMenuItems = computed(() => {
  const items = buildTagMenuItems({
    mode: props.mode,
    tags: tags.value,
    menuItems: props.menuItems,
    newTag: newTag.value,
    isLoading: props.isLoading,
    type: props.type,
    isNewTagInValidType: isNewTagInValidType.value,
    allowCreate: props.allowCreate,
    skipLabelDedup: props.skipLabelDedup,
  });
  if (props.type !== INPUT_TYPES.TEXT) return items;
  const query = newTag.value?.trim()?.toLowerCase();
  if (!query) return items;
  return items.filter(item => item.label?.toLowerCase().includes(query));
});

const emitDataOnAdd = value => {
  const matchingMenuItem = findMatchingMenuItem(props.menuItems, value);
  return matchingMenuItem
    ? emit('add', { value: value, ...matchingMenuItem })
    : emit('add', { value: value, action: 'create' });
};

const updateValueAndFocus = value => {
  tags.value.push(value);
  newTag.value = '';
  modelValue.value = tags.value;
  tagInputRef.value?.focus();
};

const addTag = async () => {
  const trimmedTag = newTag.value?.trim();
  if (!trimmedTag) return;

  if (!canAddTag(props.mode, tags.value.length)) {
    newTag.value = '';
    return;
  }

  const isValidatedType = [INPUT_TYPES.EMAIL, INPUT_TYPES.TEL].includes(
    props.type
  );

  if (!isValidatedType && !props.allowCreate && props.showDropdown) return;

  if (isValidatedType || props.allowCreate) {
    if (!(await v$.value.$validate())) return;
    emitDataOnAdd(trimmedTag);
  }
  updateValueAndFocus(trimmedTag);
};

const removeTag = index => {
  tags.value.splice(index, 1);
  modelValue.value = tags.value;
  emit('remove', index);
};

const handleDropdownAction = async ({
  email: emailAddress,
  phoneNumber,
  label,
  ...rest
}) => {
  if (props.mode === MODE.SINGLE && tags.value.length >= 1) return;
  if (!props.showDropdown) return;

  const isEmail = props.type === INPUT_TYPES.EMAIL;
  const tagValue = isEmail ? emailAddress : phoneNumber || label;

  if (isEmail || props.type === INPUT_TYPES.TEL) {
    newTag.value = tagValue;
    if (!(await v$.value.$validate())) return;
  }

  emit(
    'add',
    isEmail ? { email: emailAddress, ...rest } : { phoneNumber, label, ...rest }
  );
  updateValueAndFocus(tagValue);
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
  isFocused.value = false;
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
        class="ltr:left-0 rtl:right-0 z-[100] top-8 overflow-y-auto max-h-56 w-[inherit] max-w-md dark:!outline-n-slate-5"
        @action="handleDropdownAction"
      />
    </div>
  </div>
</template>
