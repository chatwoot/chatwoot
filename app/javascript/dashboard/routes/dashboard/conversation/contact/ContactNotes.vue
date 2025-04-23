<script setup>
import { onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useStore,
  useMapGetter,
  useFunctionGetter,
} from 'dashboard/composables/store';
import ContactNoteItem from 'next/Contacts/ContactsSidebar/components/ContactNoteItem.vue';

const props = defineProps({
  contactId: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const notes = useFunctionGetter(
  'contactNotes/getAllNotesByContactId',
  props.contactId
);

const getWrittenBy = note => {
  const isCurrentUser = note?.user?.id === currentUser.value.id;
  return isCurrentUser
    ? t('CONTACTS_LAYOUT.SIDEBAR.NOTES.YOU')
    : note?.user?.name || 'Bot';
};

onMounted(() => {
  store.dispatch('contactNotes/get', {
    contactId: props.contactId,
  });
});
</script>

<template>
  <ContactNoteItem
    v-for="note in notes"
    :key="note.id"
    class="p-4"
    :note="note"
    :written-by="getWrittenBy(note)"
  />
</template>
