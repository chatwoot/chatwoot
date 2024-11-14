<script setup>
import { computed } from 'vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  contacts: {
    type: Array,
    required: true,
  },
  selectedContact: {
    type: Object,
    default: null,
  },
  showContactsDropdown: {
    type: Boolean,
    required: true,
  },
  isLoading: {
    type: Boolean,
    required: true,
  },
  isCreatingContact: {
    type: Boolean,
    required: true,
  },
  contactId: {
    type: String,
    default: null,
  },
  contactableInboxesList: {
    type: Array,
    default: () => [],
  },
  showInboxesDropdown: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits([
  'searchContacts',
  'setSelectedContact',
  'clearSelectedContact',
  'updateDropdown',
]);

const contactsList = computed(() => {
  return props.contacts?.map(({ name, id, thumbnail, email, ...rest }) => ({
    id,
    label: `${name} (${email})`,
    value: id,
    thumbnail: { name, src: thumbnail },
    ...rest,
    name,
    email,
    action: 'contact',
  }));
});

const selectedContactLabel = computed(() => {
  return `${props.selectedContact?.name} (${props.selectedContact?.email})`;
});
</script>

<template>
  <div class="relative flex-1 px-4 py-3 overflow-y-visible">
    <div class="flex items-baseline w-full gap-3 min-h-7">
      <label class="text-sm font-medium text-n-slate-11 whitespace-nowrap">
        {{ 'To :' }}
      </label>

      <div
        v-if="selectedContact"
        class="flex items-center gap-1.5 rounded-md bg-n-alpha-2 px-3 min-h-7"
      >
        <span class="text-sm truncate text-n-slate-12">
          {{ isCreatingContact ? 'Creating contact...' : selectedContactLabel }}
        </span>
        <Button
          variant="ghost"
          icon="i-lucide-x"
          color="slate"
          :disabled="contactId"
          size="xs"
          @click="emit('clearSelectedContact')"
        />
      </div>
      <TagInput
        v-else
        placeholder="Search or enter email and press Enter"
        mode="single"
        :menu-items="contactsList"
        :show-dropdown="showContactsDropdown"
        :is-loading="isLoading"
        :disabled="contactableInboxesList?.length > 0 && showInboxesDropdown"
        type="email"
        class="flex-1 min-h-7"
        @focus="emit('updateDropdown', 'contacts', true)"
        @input="emit('searchContacts', $event)"
        @on-click-outside="emit('updateDropdown', 'contacts', false)"
        @add="emit('setSelectedContact', $event)"
        @remove="emit('clearSelectedContact')"
      />
    </div>
  </div>
</template>
