<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContactLabels from 'dashboard/components-next/Contacts/ContactLabels/ContactLabels.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';
import ConfirmContactDeleteDialog from 'dashboard/components-next/Contacts/ContactsForm/ConfirmContactDeleteDialog.vue';
import Policy from 'dashboard/components/policy.vue';

import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import ContactStats from 'dashboard/components-next/Contacts/Pages/ContactStats.vue';
import ContactSidebarSection from 'dashboard/components-next/Contacts/ContactsSidebar/ContactSidebarSection.vue';
import ContactCustomAttributes from 'dashboard/components-next/Contacts/ContactsSidebar/ContactCustomAttributes.vue';
import ContactHistory from 'dashboard/components-next/Contacts/ContactsSidebar/ContactHistory.vue';
import ContactNotes from 'dashboard/components-next/Contacts/ContactsSidebar/ContactNotes.vue';
import ContactMedia from 'dashboard/components-next/Contacts/ContactsSidebar/ContactMedia.vue';
import ContactMerge from 'dashboard/components-next/Contacts/ContactsSidebar/ContactMerge.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['goToContactsList']);

const { t } = useI18n();
const store = useStore();

const confirmDeleteContactDialogRef = ref(null);

const avatarFile = ref(null);
const avatarUrl = ref('');

const contactsFormRef = ref(null);

const uiFlags = useMapGetter('contacts/getUIFlags');
const isUpdating = computed(() => uiFlags.value.isUpdating);

const isFormInvalid = computed(() => contactsFormRef.value?.isFormInvalid);

const contactData = ref({});

const metaSeparator = '•';

const contactId = computed(() => props.selectedContact?.id);

const CONTACT_SECTIONS = [
  { value: 'details', label: 'CONTACTS_LAYOUT.PROFILE.SECTIONS.DETAILS' },
  { value: 'attributes', label: 'CONTACTS_LAYOUT.SIDEBAR.TABS.ATTRIBUTES' },
  { value: 'history', label: 'CONTACTS_LAYOUT.PROFILE.STATS.CONVERSATIONS' },
  { value: 'notes', label: 'CONTACTS_LAYOUT.PROFILE.STATS.NOTES' },
  { value: 'media', label: 'CONTACTS_LAYOUT.PROFILE.STATS.FILES' },
  { value: 'merge', label: 'CONTACTS_LAYOUT.SIDEBAR.TABS.MERGE' },
];

const activeSection = ref('details');

const sectionTabs = computed(() =>
  CONTACT_SECTIONS.map(section => ({ label: t(section.label) }))
);

const activeSectionIndex = computed(() =>
  CONTACT_SECTIONS.findIndex(section => section.value === activeSection.value)
);

const handleSectionChange = tab => {
  const index = sectionTabs.value.findIndex(item => item.label === tab.label);
  if (index !== -1) activeSection.value = CONTACT_SECTIONS[index].value;
};

const getInitialContactData = () => {
  if (!props.selectedContact) return {};
  return { ...props.selectedContact };
};

onMounted(() => {
  Object.assign(contactData.value, getInitialContactData());
  if (contactId.value) {
    store.dispatch('contacts/fetchAttachments', contactId.value);
  }
});

const createdAt = computed(() => {
  return contactData.value?.createdAt
    ? dynamicTime(contactData.value.createdAt)
    : '';
});

const lastActivityAt = computed(() => {
  return contactData.value?.lastActivityAt
    ? dynamicTime(contactData.value.lastActivityAt)
    : '';
});

const avatarSrc = computed(() => {
  return avatarUrl.value ? avatarUrl.value : contactData.value?.thumbnail;
});

const handleFormUpdate = updatedData => {
  Object.assign(contactData.value, updatedData);
};

const updateContact = async () => {
  try {
    const { customAttributes, ...basicContactData } = contactData.value;
    await store.dispatch('contacts/update', basicContactData);
    await store.dispatch(
      'contacts/fetchContactableInbox',
      props.selectedContact.id
    );
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.ERROR_MESSAGE'));
  }
};

const openConfirmDeleteContactDialog = () => {
  confirmDeleteContactDialogRef.value?.dialogRef.open();
};

const handleAvatarUpload = async ({ file, url }) => {
  avatarFile.value = file;
  avatarUrl.value = url;

  try {
    await store.dispatch('contacts/update', {
      ...contactsFormRef.value?.state,
      avatar: file,
      isFormData: true,
    });
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.UPLOAD.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.UPLOAD.ERROR_MESSAGE'));
  }
};

const handleAvatarDelete = async () => {
  try {
    if (props.selectedContact && props.selectedContact.id) {
      await store.dispatch('contacts/deleteAvatar', props.selectedContact.id);
      useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.DELETE.SUCCESS_MESSAGE'));
    }
    avatarFile.value = null;
    avatarUrl.value = '';
    contactData.value.thumbnail = null;
  } catch (error) {
    useAlert(
      error.message
        ? error.message
        : t('CONTACTS_LAYOUT.DETAILS.AVATAR.DELETE.ERROR_MESSAGE')
    );
  }
};
</script>

<template>
  <div class="flex flex-col gap-8 pb-10">
    <div class="flex items-start gap-5 min-w-0">
      <Avatar
        :src="avatarSrc || ''"
        :name="selectedContact?.name || ''"
        :size="72"
        allow-upload
        @upload="handleAvatarUpload"
        @delete="handleAvatarDelete"
      />
      <div class="flex flex-col gap-2 min-w-0">
        <h1
          class="text-xl font-semibold leading-tight tracking-tight truncate text-n-slate-12"
        >
          {{ selectedContact?.name }}
        </h1>
        <div
          class="flex flex-wrap items-center text-sm gap-x-2 gap-y-1 text-n-slate-11"
        >
          <span
            v-if="selectedContact?.identifier"
            class="inline-flex items-center gap-1"
          >
            <span class="i-ph-user-gear text-n-slate-10 size-4" />
            {{ selectedContact?.identifier }}
          </span>
          <span v-if="selectedContact?.identifier" class="text-n-slate-8">
            {{ metaSeparator }}
          </span>
          <span>
            {{ t('CONTACTS_LAYOUT.DETAILS.CREATED_AT', { date: createdAt }) }}
          </span>
          <span class="text-n-slate-8">{{ metaSeparator }}</span>
          <span>
            {{
              t('CONTACTS_LAYOUT.DETAILS.LAST_ACTIVITY', {
                date: lastActivityAt,
              })
            }}
          </span>
        </div>
        <ContactLabels :contact-id="selectedContact?.id" />
      </div>
    </div>

    <ContactStats :contact-id="contactId" :last-seen="lastActivityAt" />

    <div class="flex flex-col gap-4">
      <TabBar
        :tabs="sectionTabs"
        :initial-active-tab="activeSectionIndex"
        class="max-w-full bg-n-alpha-black2"
        @tab-changed="handleSectionChange"
      />

      <div>
        <template v-if="activeSection === 'details'">
          <div class="flex flex-col gap-4">
            <ContactSidebarSection
              :title="t('CONTACTS_LAYOUT.PROFILE.SECTIONS.DETAILS')"
              body-class="px-4 py-4"
            >
              <div class="flex flex-col items-start gap-6">
                <ContactsForm
                  ref="contactsFormRef"
                  :contact-data="contactData"
                  is-details-view
                  @update="handleFormUpdate"
                />
                <Button
                  :label="
                    t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.UPDATE_BUTTON')
                  "
                  size="sm"
                  :is-loading="isUpdating"
                  :disabled="isUpdating || isFormInvalid"
                  @click="updateContact"
                />
              </div>
            </ContactSidebarSection>
            <Policy :permissions="['administrator']">
              <ContactSidebarSection
                :title="t('CONTACTS_LAYOUT.DETAILS.DELETE_CONTACT')"
                body-class="flex flex-col items-start gap-4 p-4"
              >
                <span class="text-sm text-n-slate-11">
                  {{ t('CONTACTS_LAYOUT.DETAILS.DELETE_CONTACT_DESCRIPTION') }}
                </span>
                <Button
                  :label="t('CONTACTS_LAYOUT.DETAILS.DELETE_CONTACT')"
                  color="ruby"
                  size="sm"
                  @click="openConfirmDeleteContactDialog"
                />
              </ContactSidebarSection>
              <ConfirmContactDeleteDialog
                ref="confirmDeleteContactDialogRef"
                :selected-contact="selectedContact"
                @go-to-contacts-list="emit('goToContactsList')"
              />
            </Policy>
          </div>
        </template>
        <ContactCustomAttributes
          v-else-if="activeSection === 'attributes'"
          :selected-contact="selectedContact"
        />
        <ContactHistory v-else-if="activeSection === 'history'" />
        <ContactNotes v-else-if="activeSection === 'notes'" />
        <ContactMedia v-else-if="activeSection === 'media'" />
        <ContactMerge
          v-else-if="activeSection === 'merge'"
          :selected-contact="selectedContact"
          @go-to-contacts-list="emit('goToContactsList')"
        />
      </div>
    </div>
  </div>
</template>
