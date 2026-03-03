<script setup>
import { computed, onUnmounted, ref, onMounted } from 'vue';
import { useToggle } from '@vueuse/core';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { emitter } from 'shared/helpers/mitt';
import EmailTranscriptModal from './EmailTranscriptModal.vue';
import VirtiInfoModal from './VirtiInfoModal.vue';
import ResolveAction from '../../buttons/ResolveAction.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import virtiAuth from 'dashboard/api/virtiAuth';
import { virtiGet, virtiPost, virtiDelete } from 'dashboard/api/virtiBackend';

import {
  CMD_MUTE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

// No props needed as we're getting currentChat from the store directly
const store = useStore();
const { t } = useI18n();

const [showEmailActionsModal, toggleEmailModal] = useToggle(false);
const [showActionsDropdown, toggleDropdown] = useToggle(false);
const [showVirtiInfoModal, toggleVirtiInfoModal] = useToggle(false);

const virtiAvailable = ref(false);
const followUpAtivado = ref(false);
const followUpLoading = ref(false);

onMounted(async () => {
  await virtiAuth.ensureToken();
  virtiAvailable.value = virtiAuth.getAvailability();

  if (virtiAvailable.value) {
    const idRobo = virtiAuth.getIdRobo();
    const userId = idUsuario.value;
    if (idRobo && userId) {
      try {
        const res = await virtiGet(
          `/api/v1/infos_user/${idRobo}/${userId}/all`
        );
        followUpAtivado.value = Boolean(res?.data?.ProximoFollowUp);
      } catch {
        // silently fail — não impede o uso do resto
      }
    }
  }
});

const currentChat = computed(() => store.getters.getSelectedChat);

const idUsuario = computed(() => {
  const senderId = currentChat.value?.meta?.sender?.id;
  if (!senderId) return null;
  const contact = store.getters['contacts/getContact'](senderId);
  const phone = contact?.phone_number;
  if (!phone) return null;
  return `chatwoot_${phone.replace('+', '')}`;
});

const toggleFollowUp = async () => {
  const idRobo = virtiAuth.getIdRobo();
  const userId = idUsuario.value;
  if (!idRobo || !userId) return;

  followUpLoading.value = true;
  try {
    if (!followUpAtivado.value) {
      await virtiPost(`/api/v1/conversas/follow-up/${idRobo}/${userId}`);
      followUpAtivado.value = true;
      useAlert('Follow-up ativado com sucesso.');
    } else {
      await virtiDelete(`/api/v1/conversas/follow-up/${idRobo}/${userId}`);
      followUpAtivado.value = false;
      useAlert('Follow-up desativado com sucesso.');
    }
  } catch {
    useAlert('Erro ao alterar follow-up.');
  } finally {
    followUpLoading.value = false;
  }
};

const actionMenuItems = computed(() => {
  const items = [];

  if (!currentChat.value.muted) {
    items.push({
      icon: 'i-lucide-volume-off',
      label: t('CONTACT_PANEL.MUTE_CONTACT'),
      action: 'mute',
      value: 'mute',
    });
  } else {
    items.push({
      icon: 'i-lucide-volume-1',
      label: t('CONTACT_PANEL.UNMUTE_CONTACT'),
      action: 'unmute',
      value: 'unmute',
    });
  }

  items.push({
    icon: 'i-lucide-share',
    label: t('CONTACT_PANEL.SEND_TRANSCRIPT'),
    action: 'send_transcript',
    value: 'send_transcript',
  });

  return items;
});

const handleActionClick = ({ action }) => {
  toggleDropdown(false);

  if (action === 'mute') {
    store.dispatch('muteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
  } else if (action === 'unmute') {
    store.dispatch('unmuteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
  } else if (action === 'send_transcript') {
    toggleEmailModal();
  }
};

// These functions are needed for the event listeners
const mute = () => {
  store.dispatch('muteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
};

const unmute = () => {
  store.dispatch('unmuteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
};

emitter.on(CMD_MUTE_CONVERSATION, mute);
emitter.on(CMD_UNMUTE_CONVERSATION, unmute);
emitter.on(CMD_SEND_TRANSCRIPT, toggleEmailModal);

onUnmounted(() => {
  emitter.off(CMD_MUTE_CONVERSATION, mute);
  emitter.off(CMD_UNMUTE_CONVERSATION, unmute);
  emitter.off(CMD_SEND_TRANSCRIPT, toggleEmailModal);
});
</script>

<template>
  <div class="relative flex items-center gap-2 actions--container">
    <ButtonV4
      v-if="virtiAvailable"
      v-tooltip="'Informações do contato'"
      size="sm"
      variant="ghost"
      color="slate"
      icon="i-lucide-info"
      class="rounded-md"
      @click="toggleVirtiInfoModal(true)"
    />
    <ButtonV4
      v-if="virtiAvailable"
      v-tooltip="followUpAtivado ? 'Desativar Follow-up' : 'Ativar Follow-up'"
      size="sm"
      variant="ghost"
      :color="followUpAtivado ? 'blue' : 'slate'"
      icon="i-lucide-timer-reset"
      class="rounded-md"
      :disabled="followUpLoading"
      @click="toggleFollowUp"
    />
    <ResolveAction
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />
    <div
      v-on-clickaway="() => toggleDropdown(false)"
      class="relative flex items-center group"
    >
      <ButtonV4
        v-tooltip="$t('CONVERSATION.HEADER.MORE_ACTIONS')"
        size="sm"
        variant="ghost"
        color="slate"
        icon="i-lucide-more-vertical"
        class="rounded-md group-hover:bg-n-alpha-2"
        @click="toggleDropdown()"
      />
      <DropdownMenu
        v-if="showActionsDropdown"
        :menu-items="actionMenuItems"
        class="mt-1 ltr:right-0 rtl:left-0 top-full"
        @action="handleActionClick"
      />
    </div>
    <EmailTranscriptModal
      v-if="showEmailActionsModal"
      :show="showEmailActionsModal"
      :current-chat="currentChat"
      @cancel="toggleEmailModal"
    />
    <VirtiInfoModal
      v-if="showVirtiInfoModal"
      :conversation-id="currentChat.id"
      @close="toggleVirtiInfoModal(false)"
    />
  </div>
</template>
