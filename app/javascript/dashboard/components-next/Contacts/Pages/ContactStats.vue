<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  contactId: {
    type: [Number, String],
    default: null,
  },
  lastSeen: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const conversationsByContact = useMapGetter(
  'contactConversations/getAllConversationsByContactId'
);
const notesByContact = useMapGetter('contactNotes/getAllNotesByContactId');
const attachmentsByContact = useMapGetter('contacts/getContactAttachments');

const statTiles = computed(() => [
  {
    key: 'conversations',
    label: t('CONTACTS_LAYOUT.PROFILE.STATS.CONVERSATIONS'),
    value: conversationsByContact.value(props.contactId)?.length ?? 0,
  },
  {
    key: 'notes',
    label: t('CONTACTS_LAYOUT.PROFILE.STATS.NOTES'),
    value: notesByContact.value(props.contactId)?.length ?? 0,
  },
  {
    key: 'files',
    label: t('CONTACTS_LAYOUT.PROFILE.STATS.FILES'),
    value:
      attachmentsByContact.value(props.contactId)?.filter(a => a.data_url)
        ?.length ?? 0,
  },
]);
</script>

<template>
  <div
    class="grid grid-cols-2 overflow-hidden border sm:grid-cols-4 gap-px rounded-xl border-n-weak bg-n-weak"
  >
    <div
      v-for="tile in statTiles"
      :key="tile.key"
      class="flex flex-col gap-2 px-5 py-5 bg-n-solid-1"
    >
      <span
        class="text-xs font-semibold tracking-wider uppercase text-n-slate-10"
      >
        {{ tile.label }}
      </span>
      <span class="text-3xl font-semibold tabular-nums text-n-slate-12">
        {{ tile.value }}
      </span>
    </div>
    <div class="flex flex-col gap-2 px-5 py-5 bg-n-solid-1">
      <span
        class="text-xs font-semibold tracking-wider uppercase text-n-slate-10"
      >
        {{ t('CONTACTS_LAYOUT.PROFILE.STATS.LAST_SEEN') }}
      </span>
      <span class="text-base font-medium truncate text-n-slate-12">
        {{ lastSeen || t('CONTACTS_LAYOUT.PROFILE.STATS.NEVER') }}
      </span>
    </div>
  </div>
</template>
