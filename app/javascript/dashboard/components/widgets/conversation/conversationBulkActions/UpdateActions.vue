<script setup>
import { useI18n } from 'vue-i18n';
import { ref } from 'vue';

import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';

const props = defineProps({
  showResolve: {
    type: Boolean,
    default: true,
  },
  showReopen: {
    type: Boolean,
    default: true,
  },
  showSnooze: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['update', 'close']);

const { t } = useI18n();

const actions = ref([
  { icon: 'checkmark', key: 'resolved' },
  { icon: 'arrow-redo', key: 'open' },
  { icon: 'send-clock', key: 'snoozed' },
]);

const updateConversations = key => {
  if (key === 'snoozed') {
    // If the user clicks on the snooze option from the bulk action change status dropdown.
    // Open the snooze option for bulk action in the cmd bar.
    const ninja = document.querySelector('ninja-keys');
    ninja?.open({ parent: 'bulk_action_snooze_conversation' });
  } else {
    emit('update', key);
  }
};

const onClose = () => {
  emit('close');
};

const showAction = key => {
  const actionsMap = {
    resolved: props.showResolve,
    open: props.showReopen,
    snoozed: props.showSnooze,
  };
  return actionsMap[key] || false;
};

const actionLabel = key => {
  const labelsMap = {
    resolved: t('CONVERSATION.HEADER.RESOLVE_ACTION'),
    open: t('CONVERSATION.HEADER.REOPEN_ACTION'),
    snoozed: t('BULK_ACTION.UPDATE.SNOOZE_UNTIL'),
  };
  return labelsMap[key] || '';
};
</script>

<template>
  <div
    v-on-clickaway="onClose"
    class="absolute z-20 w-auto origin-top-right bg-white border border-solid rounded-lg shadow-md right-2 top-12 dark:bg-slate-800 border-slate-50 dark:border-slate-700"
  >
    <div
      class="right-[var(--triangle-position)] block z-10 absolute text-left -top-3"
    >
      <svg height="12" viewBox="0 0 24 12" width="24">
        <path
          d="M20 12l-8-8-12 12"
          fill-rule="evenodd"
          stroke-width="1px"
          class="fill-white dark:fill-slate-800 stroke-slate-50 dark:stroke-slate-600/50"
        />
      </svg>
    </div>
    <div class="p-2.5 flex gap-1 items-center justify-between">
      <span class="text-sm font-medium text-slate-600 dark:text-slate-100">
        {{ $t('BULK_ACTION.UPDATE.CHANGE_STATUS') }}
      </span>
      <woot-button
        size="tiny"
        variant="clear"
        color-scheme="secondary"
        icon="dismiss"
        @click="onClose"
      />
    </div>
    <div class="px-2.5 pt-0 pb-2.5">
      <WootDropdownMenu class="m-0 list-none">
        <template v-for="action in actions">
          <WootDropdownItem v-if="showAction(action.key)" :key="action.key">
            <woot-button
              variant="clear"
              color-scheme="secondary"
              size="small"
              :icon="action.icon"
              @click="updateConversations(action.key)"
            >
              {{ actionLabel(action.key) }}
            </woot-button>
          </WootDropdownItem>
        </template>
      </WootDropdownMenu>
    </div>
  </div>
</template>
