<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { generateLabelForContactableInboxesList } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper.js';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  targetInbox: {
    type: Object,
    default: null,
  },
  selectedContact: {
    type: Object,
    default: null,
  },
  showInboxesDropdown: {
    type: Boolean,
    required: true,
  },
  contactableInboxesList: {
    type: Array,
    default: () => [],
  },
  hasErrors: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'updateInbox',
  'toggleDropdown',
  'handleInboxAction',
]);

const { t } = useI18n();

const targetInboxLabel = computed(() => {
  return generateLabelForContactableInboxesList(props.targetInbox);
});
</script>

<template>
  <div
    class="flex items-center flex-1 w-full gap-3 px-4 py-3 overflow-y-visible"
  >
    <label class="mb-0.5 text-sm font-medium text-n-slate-11 whitespace-nowrap">
      {{ t('COMPOSE_NEW_CONVERSATION.FORM.INBOX_SELECTOR.LABEL') }}
    </label>
    <div
      v-if="targetInbox"
      class="flex items-center gap-1.5 rounded-md bg-n-alpha-2 truncate ltr:pl-3 rtl:pr-3 ltr:pr-1 rtl:pl-1 h-7 min-w-0"
    >
      <span class="text-sm truncate text-n-slate-12">
        {{ targetInboxLabel }}
      </span>
      <Button
        variant="ghost"
        icon="i-lucide-x"
        color="slate"
        size="xs"
        class="flex-shrink-0"
        @click="emit('updateInbox', null)"
      />
    </div>
    <div
      v-else
      v-on-click-outside="() => emit('toggleDropdown', false)"
      class="relative flex items-center h-7"
    >
      <Button
        :label="t('COMPOSE_NEW_CONVERSATION.FORM.INBOX_SELECTOR.BUTTON')"
        variant="link"
        size="sm"
        :color="hasErrors ? 'ruby' : 'slate'"
        :disabled="!selectedContact"
        class="hover:!no-underline"
        @click="emit('toggleDropdown', !showInboxesDropdown)"
      />
      <DropdownMenu
        v-if="contactableInboxesList?.length > 0 && showInboxesDropdown"
        :menu-items="contactableInboxesList"
        class="left-0 z-[100] top-8 overflow-y-auto max-h-60 w-fit max-w-sm dark:!outline-n-slate-5"
        @action="emit('handleInboxAction', $event)"
      />
    </div>
  </div>
</template>
