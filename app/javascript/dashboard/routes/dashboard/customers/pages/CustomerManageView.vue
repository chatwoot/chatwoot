<script setup>
import { onMounted, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ContactLabels from 'dashboard/components-next/Contacts/ContactLabels/ContactLabels.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const isValidatingToken = ref(true);
const isTokenValid = ref(false);

const contactsFormRef = ref(null);
const contactData = ref({});
const avatarFile = ref(null);
const avatarUrl = ref('');

const uiFlags = computed(() => store.getters['contacts/getUIFlags']);
const contact = computed(() =>
  store.getters['contacts/getContact'](route.params.contactId)
);

const isFetchingItem = computed(() => uiFlags.value.isFetchingItem);
const isUpdating = computed(() => uiFlags.value.isUpdating);
const isFormInvalid = computed(() => contactsFormRef.value?.isFormInvalid);

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

const fetchContact = async () => {
  if (route.params.contactId) {
    await store.dispatch('contacts/show', { id: route.params.contactId });

    // Map contact data ensuring additionalAttributes is properly structured
    const rawContact = contact.value;
    const additionalAttrs =
      rawContact.additional_attributes || rawContact.additionalAttributes || {};

    contactData.value = {
      ...rawContact,
      additionalAttributes: {
        description: additionalAttrs.description || '',
        companyName:
          additionalAttrs.company_name || additionalAttrs.companyName || '',
        countryCode:
          additionalAttrs.country_code || additionalAttrs.countryCode || '',
        country: additionalAttrs.country || '',
        city: additionalAttrs.city || '',
        socialProfiles:
          additionalAttrs.social_profiles ||
          additionalAttrs.socialProfiles ||
          {},
      },
    };
  }
};

const markAppointmentAsAssisted = async () => {
  const appointmentId = contact.value?.current_appointment_id;
  if (appointmentId) {
    try {
      await store.dispatch('appointments/update', {
        id: appointmentId,
        assisted: true,
      });
    } catch (error) {
      // Silently fail as this is a background operation
    }
  }
};

const handleFormUpdate = updatedData => {
  Object.assign(contactData.value, updatedData);
};

const updateContact = async () => {
  try {
    await store.dispatch('contacts/update', contactData.value);
    useAlert(t('CUSTOMER_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('CUSTOMER_MGMT.EDIT.API.ERROR_MESSAGE'));
  }
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
    if (contact.value && contact.value.id) {
      await store.dispatch('contacts/deleteAvatar', contact.value.id);
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

const continueToConversation = () => {
  const lastConversationId = contact.value?.last_conversation_id;
  const lastConversationInboxId = contact.value?.last_conversation_inbox_id;

  if (lastConversationId && lastConversationInboxId) {
    router.push({
      name: 'inbox_conversation',
      params: {
        accountId: route.params.accountId,
        inboxId: lastConversationInboxId,
        conversation_id: lastConversationId,
      },
    });
  } else {
    useAlert(t('CUSTOMER_MGMT.EDIT.NO_CONVERSATION_ERROR'));
  }
};

const validateAccessToken = async () => {
  const token = route.query.token;

  if (!token) {
    router.push({
      name: 'home',
      params: { accountId: route.params.accountId },
    });
    return false;
  }

  try {
    const response = await store.dispatch(
      'appointments/validateAppointmentToken',
      token
    );

    if (response.valid) {
      isTokenValid.value = true;
      return true;
    }
    router.push({
      name: 'home',
      params: { accountId: route.params.accountId },
    });
    return false;
  } catch (error) {
    router.push({
      name: 'home',
      params: { accountId: route.params.accountId },
    });
    return false;
  } finally {
    isValidatingToken.value = false;
  }
};

onMounted(async () => {
  const valid = await validateAccessToken();
  if (valid) {
    await fetchContact();
    await markAppointmentAsAssisted();
  }
});
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-auto bg-n-background p-8">
    <div class="max-w-4xl mx-auto w-full">
      <div
        v-if="isValidatingToken || isFetchingItem"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>

      <div v-else-if="isTokenValid && contact" class="flex flex-col gap-8">
        <div class="flex flex-col gap-2">
          <h1 class="text-2xl font-semibold text-n-slate-12">
            {{ $t('CUSTOMER_MGMT.EDIT.WELCOME_TITLE') }}
          </h1>
          <p class="text-sm text-n-slate-11">
            {{ $t('CUSTOMER_MGMT.EDIT.WELCOME_MESSAGE') }}
          </p>
        </div>

        <div class="flex flex-col items-start gap-3">
          <Avatar
            :src="avatarSrc || ''"
            :name="contact?.name || ''"
            :size="72"
            allow-upload
            @upload="handleAvatarUpload"
            @delete="handleAvatarDelete"
          />
          <div class="flex flex-col gap-1">
            <h3 class="text-base font-medium text-n-slate-12">
              {{ contact?.name }}
            </h3>
            <div class="flex flex-col gap-1.5">
              <span
                v-if="contact?.identifier"
                class="inline-flex items-center gap-1 text-sm text-n-slate-11"
              >
                <span class="i-ph-user-gear text-n-slate-10 size-4" />
                {{ contact?.identifier }}
              </span>
              <span
                class="inline-flex items-center gap-1 text-sm text-n-slate-11"
              >
                <span
                  v-if="contact?.identifier"
                  class="i-ph-activity text-n-slate-10 size-4"
                />
                {{
                  $t('CONTACTS_LAYOUT.DETAILS.CREATED_AT', { date: createdAt })
                }}
                •
                {{
                  $t('CONTACTS_LAYOUT.DETAILS.LAST_ACTIVITY', {
                    date: lastActivityAt,
                  })
                }}
              </span>
            </div>
          </div>
          <ContactLabels :contact-id="contact?.id" />
        </div>

        <div class="flex flex-col gap-6">
          <ContactsForm
            ref="contactsFormRef"
            :contact-data="contactData"
            is-details-view
            @update="handleFormUpdate"
          />

          <div class="flex items-center gap-3">
            <Button
              :label="$t('CUSTOMER_MGMT.EDIT.FORM.UPDATE_BUTTON')"
              size="sm"
              :is-loading="isUpdating"
              :disabled="isUpdating || isFormInvalid"
              @click="updateContact"
            />
            <Button
              :label="$t('CUSTOMER_MGMT.EDIT.FORM.CONTINUE_BUTTON')"
              size="sm"
              variant="outline"
              color="slate"
              :disabled="isUpdating"
              @click="continueToConversation"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
