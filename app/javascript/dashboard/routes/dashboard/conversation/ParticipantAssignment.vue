<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useToggle } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';

import Button from 'dashboard/components-next/button/Button.vue';
import AvatarGroup from 'dashboard/components-next/avatar/AvatarGroup.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const { agentsList } = useAgentsList(false);

const selectedParticipants = ref([]);
const triggerRef = ref(null);
const dropdownRef = ref(null);

const [openParticipantsList, toggleParticipantsList] = useToggle(false);

const { positionClasses } = useDropdownPosition(
  triggerRef,
  dropdownRef,
  openParticipantsList
);

const currentUser = useMapGetter('getCurrentUser');

const watchersFromStore = computed(() => {
  return store.getters['conversationWatchers/getByConversationId'](
    props.conversationId
  );
});

const participantsLabel = computed(() => {
  const count = selectedParticipants.value.length;
  if (count === 0) {
    return t('CONVERSATION_PARTICIPANTS.NO_PARTICIPANTS_TEXT');
  }
  return t('CONVERSATION_PARTICIPANTS.TOTAL_PARTICIPANT_TEXT', { n: count });
});

const thumbnailList = computed(() => {
  return selectedParticipants.value.slice(0, 3);
});

const moreParticipantsCount = computed(() => {
  const maxThumbnailCount = 3;
  return selectedParticipants.value.length - maxThumbnailCount;
});

const moreParticipantsText = computed(() => {
  if (moreParticipantsCount.value > 0) {
    return `+${moreParticipantsCount.value}`;
  }
  return '';
});

const isUserWatching = computed(() => {
  return selectedParticipants.value.some(
    participant => participant.id === currentUser.value.id
  );
});

const participantMenuItems = computed(() => {
  return agentsList.value.map(agent => ({
    label: agent.name || agent.available_name,
    value: agent.id,
    thumbnail: { name: agent.name, src: agent.thumbnail },
    isSelected: selectedParticipants.value.some(p => p.id === agent.id),
    action: 'toggleParticipant',
  }));
});

const fetchParticipants = () => {
  store.dispatch('conversationWatchers/show', {
    conversationId: props.conversationId,
  });
};

const updateParticipants = async userIds => {
  let alertMessage = t('CONVERSATION_PARTICIPANTS.API.SUCCESS_MESSAGE');

  try {
    await store.dispatch('conversationWatchers/update', {
      conversationId: props.conversationId,
      userIds,
    });
  } catch (error) {
    alertMessage =
      error?.message || t('CONVERSATION_PARTICIPANTS.API.ERROR_MESSAGE');
  } finally {
    useAlert(alertMessage);
  }
  fetchParticipants();
};

const handleParticipantAction = ({ value }) => {
  const isSelected = selectedParticipants.value.some(p => p.id === value);

  if (isSelected) {
    // Remove participant
    selectedParticipants.value = selectedParticipants.value.filter(
      p => p.id !== value
    );
  } else {
    // Add participant
    const agent = agentsList.value.find(a => a.id === value);
    if (agent) {
      selectedParticipants.value = [...selectedParticipants.value, agent];
    }
  }

  const userIds = selectedParticipants.value.map(p => p.id);
  updateParticipants(userIds);
};

const onSelfAssign = () => {
  if (!isUserWatching.value) {
    selectedParticipants.value = [
      ...selectedParticipants.value,
      currentUser.value,
    ];
    const userIds = selectedParticipants.value.map(p => p.id);
    updateParticipants(userIds);
  }
};

watch(
  () => props.conversationId,
  () => {
    fetchParticipants();
  }
);

watch(watchersFromStore, participants => {
  selectedParticipants.value = [...(participants || [])];
});

onMounted(() => {
  fetchParticipants();
  store.dispatch('agents/get');
});
</script>

<template>
  <div class="grid grid-cols-[30%_1fr] gap-3 w-full items-center h-9">
    <span class="text-sm font-420 text-n-slate-11 truncate whitespace-nowrap">
      {{ $t('CONVERSATION_SIDEBAR.PARTICIPANTS_LABEL') }}
    </span>
    <div
      v-on-click-outside="() => toggleParticipantsList(false)"
      class="relative w-fit"
    >
      <div class="flex items-center gap-1">
        <Button
          ref="triggerRef"
          slate
          :variant="openParticipantsList ? 'faded' : 'ghost'"
          :label="participantsLabel"
          no-animation
          class="!px-1 !py-1 h-7 !rounded-lg !font-420 !gap-1.5 w-fit !justify-start"
          @click="toggleParticipantsList()"
        >
          <template #icon>
            <AvatarGroup
              v-if="selectedParticipants.length > 0"
              :users-list="thumbnailList"
              :size="16"
              :show-more-count="moreParticipantsCount > 0"
              :more-count-text="moreParticipantsText"
              gap="tight"
            />
          </template>
          <div class="grid grid-cols-[1fr_auto] items-center gap-1.5 min-w-0">
            <span class="truncate min-w-0 font-420">
              {{ participantsLabel }}
            </span>
            <Icon
              :icon="
                openParticipantsList
                  ? 'i-lucide-chevron-up'
                  : 'i-lucide-chevron-down'
              "
              class="size-4 text-n-slate-11 flex-shrink-0"
            />
          </div>
        </Button>
        <div
          v-if="!isUserWatching"
          class="w-px mx-1 h-3 bg-n-weak rounded-lg flex-shrink-0"
        />
        <Button
          v-if="!isUserWatching"
          link
          :label="$t('CONVERSATION_PARTICIPANTS.JOIN')"
          sm
          class="flex-shrink-0 !text-n-blue-11 hover:!no-underline"
          @click="onSelfAssign"
        />
      </div>
      <DropdownMenu
        v-if="openParticipantsList"
        ref="dropdownRef"
        :menu-items="participantMenuItems"
        show-search
        :search-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
        "
        class="z-[100] w-52 overflow-y-auto max-h-60"
        :class="positionClasses"
        @action="handleParticipantAction"
      >
        <template #trailing-icon="{ item }">
          <Icon
            v-if="item.isSelected"
            icon="i-lucide-check"
            class="size-4 text-n-blue-11 flex-shrink-0"
          />
        </template>
      </DropdownMenu>
    </div>
  </div>
</template>
