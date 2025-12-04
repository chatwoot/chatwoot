<script setup>
import { computed, watch } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useAdmin } from 'dashboard/composables/useAdmin';
import ContactInfoRow from './ContactInfoRow.vue';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'next/icon/Icon.vue';
import EditContact from './EditContact.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import NextButton from 'dashboard/components-next/button/Button.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';

import {
  isAConversationRoute,
  isAInboxViewRoute,
  getConversationDashboardRoute,
} from 'dashboard/helper/routeHelpers';
import { emitter } from 'shared/helpers/mitt';

const props = defineProps({
  contact: {
    type: Object,
    default: () => ({}),
  },
  showAvatar: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['panelClose']);

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();

const [showEditModal, toggleEditModal] = useToggle(false);
const [showMergeModal, toggleMergeModal] = useToggle(false);
const [showDeleteModal, toggleDeleteModal] = useToggle(false);

const uiFlags = useMapGetter('contacts/getUIFlags');

const contactProfileLink = computed(
  () => `/app/accounts/${route.params.accountId}/contacts/${props.contact.id}`
);

const additionalAttributes = computed(
  () => props.contact.additional_attributes || {}
);

const findCountryFlag = (countryCode, cityAndCountry) => {
  try {
    if (!countryCode) {
      return `${cityAndCountry} 🌎`;
    }

    const code = countryCode?.toLowerCase();
    return `${cityAndCountry} <span class="fi fi-${code} size-3.5"></span>`;
  } catch (error) {
    return '';
  }
};

const deleteContact = async ({ id }) => {
  try {
    await store.dispatch('contacts/delete', id);
    emit('panelClose');
    useAlert(t('DELETE_CONTACT.API.SUCCESS_MESSAGE'));

    if (isAConversationRoute(route.name)) {
      router.push({
        name: getConversationDashboardRoute(route.name),
      });
    } else if (isAInboxViewRoute(route.name)) {
      router.push({
        name: 'inbox_view',
      });
    } else if (route.name !== 'contacts_dashboard') {
      router.push({
        name: 'contacts_dashboard',
      });
    }
  } catch (error) {
    useAlert(
      error.message ? error.message : t('DELETE_CONTACT.API.ERROR_MESSAGE')
    );
  }
};

const location = computed(() => {
  const {
    country = '',
    city = '',
    country_code: countryCode,
  } = additionalAttributes.value;
  const cityAndCountry = [city, country].filter(item => !!item).join(', ');

  if (!cityAndCountry) {
    return '';
  }
  return findCountryFlag(countryCode, cityAndCountry);
});

watch(
  () => props.contact.id,
  id => store.dispatch('contacts/fetchContactableInbox', id),
  { immediate: true }
);

const openComposeConversationModal = toggleFn => {
  toggleFn();
  // Flag to prevent triggering drag n drop,
  // When compose modal is active
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, true);
};

const closeComposeConversationModal = () => {
  // Flag to enable drag n drop,
  // When compose modal is closed
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, false);
};

const closeDelete = () => {
  toggleDeleteModal(false);
  toggleEditModal(false);
};

const confirmDeletion = () => {
  deleteContact(props.contact);
  closeDelete();
};

const closeMergeModal = () => {
  toggleMergeModal(false);
};

const openMergeModal = () => {
  toggleMergeModal(true);
};
</script>

<template>
  <div class="relative items-center w-full px-4 pb-4 pt-3">
    <div class="flex flex-col w-full gap-3 text-start">
      <div class="flex flex-row gap-4 md:gap-8">
        <Avatar
          v-if="showAvatar"
          :src="contact.thumbnail"
          :name="contact.name"
          :status="contact.availability_status"
          :size="64"
          hide-offline-status
        />
        <div
          v-if="showAvatar"
          class="flex flex-col justify-center min-w-0 flex-1"
        >
          <div class="flex items-center gap-1">
            <h3
              :title="contact.name"
              class="flex-shrink font-medium max-w-full min-w-0 my-0 text-base capitalize break-words text-n-slate-12 line-clamp-2"
            >
              {{ contact.name }}
            </h3>
            <div class="w-px h-2 bg-n-strong rounded-md ltr:ml-1 rtl:mr-1" />
            <a
              :href="contactProfileLink"
              target="_blank"
              rel="noopener nofollow noreferrer"
              class="flex-shrink-0 flex items-center"
            >
              <Icon
                icon="i-lucide-arrow-up-right"
                class="size-4 text-n-slate-10 hover:text-n-slate-12 transition-colors"
              />
            </a>
          </div>
          <p
            v-if="contact"
            class="text-sm text-n-slate-11 font-420 m-0 truncate"
          >
            {{ contact.email || contact.phone_number || '---' }}
          </p>
        </div>
      </div>

      <div class="flex flex-col items-start gap-3 min-w-0 w-full">
        <p
          v-if="additionalAttributes.description"
          class="break-words text-sm text-n-slate-11 font-420 mb-0"
        >
          {{ additionalAttributes.description }}
        </p>
        <div class="flex flex-col items-start w-full">
          <ContactInfoRow
            :href="contact.email ? `mailto:${contact.email}` : ''"
            :value="contact.email"
            :title="t('CONTACT_PANEL.EMAIL_ADDRESS')"
            show-copy
          />
          <ContactInfoRow
            :value="additionalAttributes.company_name"
            :title="t('CONTACT_PANEL.COMPANY')"
          />
          <ContactInfoRow
            :href="contact.phone_number ? `tel:${contact.phone_number}` : ''"
            :value="contact.phone_number"
            :title="t('CONTACT_PANEL.PHONE_NUMBER')"
            show-copy
          />
          <ContactInfoRow
            v-if="contact.identifier"
            :value="contact.identifier"
            :title="t('CONTACT_PANEL.IDENTIFIER')"
          />
          <ContactInfoRow
            v-if="location || additionalAttributes.location"
            :value="location || additionalAttributes.location"
            :title="t('CONTACT_PANEL.LOCATION')"
          />
          <ContactInfoRow
            v-if="contact.created_at"
            :value="dynamicTime(contact.created_at)"
            :title="t('CONTACT_PANEL.CREATED_AT_LABEL')"
          />
        </div>
      </div>
      <div class="flex items-center w-full mb-1 gap-3">
        <ComposeConversation
          :contact-id="String(contact.id)"
          is-modal
          @close="closeComposeConversationModal"
        >
          <template #trigger="{ toggle }">
            <NextButton
              :label="t('CONTACT_PANEL.BUTTON_LABEL.NEW_MESSAGE')"
              slate
              sm
              class="!px-2"
              @click="openComposeConversationModal(toggle)"
            />
          </template>
        </ComposeConversation>
        <VoiceCallButton
          :phone="contact.phone_number"
          :contact-id="contact.id"
          size="sm"
          :label="t('CONTACT_PANEL.BUTTON_LABEL.CALL')"
          slate
          class="!px-2"
        />
        <NextButton
          :label="t('CONTACT_PANEL.BUTTON_LABEL.EDIT')"
          slate
          sm
          class="!px-2"
          @click="() => toggleEditModal()"
        />

        <NextButton
          :label="t('CONTACT_PANEL.BUTTON_LABEL.MERGE')"
          slate
          sm
          class="!px-2"
          :disabled="uiFlags.isMerging"
          @click="openMergeModal"
        />
        <NextButton
          v-if="isAdmin"
          :label="t('CONTACT_PANEL.BUTTON_LABEL.DELETE')"
          slate
          sm
          class="!px-2"
          :disabled="uiFlags.isDeleting"
          @click="() => toggleDeleteModal()"
        />
      </div>
      <EditContact
        v-if="showEditModal"
        :show="showEditModal"
        :contact="contact"
        @cancel="() => toggleEditModal()"
      />
      <ContactMergeModal
        v-if="showMergeModal"
        :primary-contact="contact"
        :show="showMergeModal"
        @close="closeMergeModal"
      />
    </div>
    <woot-delete-modal
      v-if="showDeleteModal"
      v-model:show="showDeleteModal"
      :on-close="closeDelete"
      :on-confirm="confirmDeletion"
      :title="t('DELETE_CONTACT.CONFIRM.TITLE')"
      :message="t('DELETE_CONTACT.CONFIRM.MESSAGE')"
      :message-value="contact?.name || ''"
      :confirm-text="t('DELETE_CONTACT.CONFIRM.YES')"
      :reject-text="t('DELETE_CONTACT.CONFIRM.NO')"
    />
  </div>
</template>
