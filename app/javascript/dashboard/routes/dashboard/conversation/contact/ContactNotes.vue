<script setup>
import { onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useStore,
  useMapGetter,
  useFunctionGetter,
} from 'dashboard/composables/store';
import ContactNoteItem from 'next/Contacts/ContactsSidebar/components/ContactNoteItem.vue';
import Spinner from 'next/spinner/Spinner.vue';

const props = defineProps({
  contactId: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const uiFlags = useMapGetter('contactNotes/getUIFlags');
const isFetchingNotes = computed(() => uiFlags.value.isFetching);
const notes = useFunctionGetter(
  'contactNotes/getAllNotesByContactId',
  props.contactId
);

const getWrittenBy = ({ user } = {}) => {
  const currentUserId = currentUser.value?.id;
  return user?.id === currentUserId
    ? t('CONTACTS_LAYOUT.SIDEBAR.NOTES.YOU')
    : user?.name || 'Bot';
};

onMounted(() => {
  store.dispatch('contactNotes/get', {
    contactId: props.contactId,
  });
});
</script>

<template>
  <div v-if="isFetchingNotes" class="p-8 grid place-content-center">
    <Spinner />
  </div>
  <template v-else>
    <ContactNoteItem
      v-for="note in notes"
      :key="note.id"
      class="p-4 last-of-type:border-b-0"
      :note="note"
      collapsible
      :written-by="getWrittenBy(note)"
    />
  </template>
</template>
