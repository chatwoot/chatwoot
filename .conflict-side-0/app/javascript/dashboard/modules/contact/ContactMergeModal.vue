<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert, useTrack } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';

import MergeContact from 'dashboard/modules/contact/components/MergeContact.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ContactAPI from 'dashboard/api/contacts';
import { CONTACTS_EVENTS } from '../../helper/AnalyticsHelper/events';

const props = defineProps({
  primaryContact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('contacts/getUIFlags');

const dialogRef = ref(null);
const isSearching = ref(false);
const searchResults = ref([]);

watch(
  () => props.primaryContact.id,
  () => {
    isSearching.value = false;
    searchResults.value = [];
  }
);

const open = () => {
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

defineExpose({ open, close });

const onClose = () => {
  close();
  emit('close');
};

const onContactSearch = async query => {
  isSearching.value = true;
  searchResults.value = [];

  try {
    const {
      data: { payload },
    } = await ContactAPI.search(query);
    searchResults.value = payload.filter(
      contact => contact.id !== props.primaryContact.id
    );
  } catch (error) {
    useAlert(t('MERGE_CONTACTS.SEARCH.ERROR_MESSAGE'));
  } finally {
    isSearching.value = false;
  }
};

const onMergeContacts = async parentContactId => {
  useTrack(CONTACTS_EVENTS.MERGED_CONTACTS);
  try {
    await store.dispatch('contacts/merge', {
      childId: props.primaryContact.id,
      parentId: parentContactId,
    });
    useAlert(t('MERGE_CONTACTS.FORM.SUCCESS_MESSAGE'));
    close();
    emit('close');
  } catch (error) {
    useAlert(t('MERGE_CONTACTS.FORM.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="2xl"
    :title="$t('MERGE_CONTACTS.TITLE')"
    :description="$t('MERGE_CONTACTS.DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
  >
    <MergeContact
      :key="primaryContact.id"
      :primary-contact="primaryContact"
      :is-searching="isSearching"
      :is-merging="uiFlags.isMerging"
      :search-results="searchResults"
      @search="onContactSearch"
      @cancel="onClose"
      @submit="onMergeContacts"
    />
  </Dialog>
</template>
