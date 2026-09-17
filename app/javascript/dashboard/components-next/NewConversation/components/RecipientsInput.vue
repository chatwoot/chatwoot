<script setup>
import { computed } from 'vue';

import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const props = defineProps({
  label: { type: String, required: true },
  placeholder: { type: String, default: '' },
  contacts: { type: Array, default: () => [] },
  showDropdown: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
  focusOnMount: { type: Boolean, default: false },
});

const emit = defineEmits(['input', 'onClickOutside']);

const modelValue = defineModel({ type: Array, default: () => [] });

const contactEmailsList = computed(() =>
  props.contacts
    .filter(contact => contact.email)
    .map(({ name, id, email }) => ({
      id,
      label: email,
      email,
      thumbnail: { name, src: '' },
      value: id,
      action: 'email',
    }))
);
</script>

<template>
  <div class="flex items-baseline flex-1 w-full gap-3 px-4 py-3 min-h-8">
    <label class="mb-0.5 text-sm font-medium whitespace-nowrap text-n-slate-11">
      {{ label }}
    </label>
    <div class="flex items-center w-full gap-3 min-h-7">
      <TagInput
        v-model="modelValue"
        :placeholder="placeholder"
        :menu-items="contactEmailsList"
        :show-dropdown="showDropdown"
        :is-loading="isLoading"
        :focus-on-mount="focusOnMount"
        type="email"
        allow-create
        class="flex-1 min-h-7"
        @input="emit('input', $event)"
        @on-click-outside="emit('onClickOutside')"
      />
      <slot />
    </div>
  </div>
</template>
