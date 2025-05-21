<script setup>
import { watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import ContactNoteItem from 'next/Contacts/ContactsSidebar/components/ContactNoteItem.vue';
import Spinner from 'next/spinner/Spinner.vue';

const { contactId } = defineProps({
  contactId: { type: String, required: true },
});

const { t } = useI18n();
const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const uiFlags = useMapGetter('contactNotes/getUIFlags');
const isFetchingNotes = computed(() => uiFlags.value.isFetching);
const notGetterFn = useMapGetter('contactNotes/getAllNotesByContactId');
const notes = computed(() => notGetterFn.value(contactId));

const getWrittenBy = ({ user } = {}) => {
  const currentUserId = currentUser.value?.id;
  return user?.id === currentUserId
    ? t('CONTACTS_LAYOUT.SIDEBAR.NOTES.YOU')
    : user?.name || t('CONVERSATION.BOT');
};

watch(
  () => contactId,
  () => store.dispatch('contactNotes/get', { contactId }),
  { immediate: true }
);
</script>

<template>
  <div v-if="isFetchingNotes" class="p-8 grid place-content-center">
    <Spinner />
  </div>
  <div v-else-if="!notes.length" class="p-8 grid place-content-center">
    <p class="text-center">{{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.NO_NOTES') }}</p>
  </div>
  <div v-else class="max-h-[300px] overflow-scroll">
    <ContactNoteItem
      v-for="note in notes"
      :key="note.id"
      class="p-4 last-of-type:border-b-0"
      :note="note"
      collapsible
      :written-by="getWrittenBy(note)"
    />
  </div>
</template>
