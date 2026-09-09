<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import Avatar from 'next/avatar/Avatar.vue';
import EmojiIcon from 'dashboard/components-next/emoji-icon-picker/EmojiIcon.vue';
import CaretAnchoredPicker from 'dashboard/components-next/preview-picker/CaretAnchoredPicker.vue';

const props = defineProps({
  caretPosition: {
    type: Object,
    default: null,
  },
  searchKey: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['selectAgent', 'close', 'removeTrigger']);

const { t } = useI18n();
const getters = useStoreGetters();

const agents = computed(() => getters['agents/getVerifiedAgents'].value);
const teams = useMapGetter('teams/getTeams');
const isRTL = useMapGetter('accounts/isRTL');

const searchQuery = ref(props.searchKey);

const searchTerm = computed(() => searchQuery.value.trim().toLowerCase());

const matchesSearch = name => name?.toLowerCase().includes(searchTerm.value);

const agentItems = computed(() =>
  agents.value
    .filter(agent => matchesSearch(agent.name))
    .map(agent => ({
      id: `user-${agent.id}`,
      record: { ...agent, type: 'user', displayName: agent.name },
      label: agent.name,
      title: agent.name,
      subtitle: agent.email,
    }))
);

const teamItems = computed(() =>
  teams.value
    .filter(team => matchesSearch(team.name))
    .map(team => ({
      id: `team-${team.id}`,
      record: { ...team, type: 'team', displayName: team.name },
      label: team.name,
      title: team.name,
      subtitle: team.description,
    }))
);

const activeFilter = ref('all');

const tabs = computed(() => [
  { label: t('CONVERSATION.PICKER.MENTION.FILTER.ALL'), value: 'all' },
  {
    label: t('CONVERSATION.MENTION.AGENTS'),
    value: 'agents',
    count: agentItems.value.length,
  },
  {
    label: t('CONVERSATION.MENTION.TEAMS'),
    value: 'teams',
    count: teamItems.value.length,
  },
]);

const items = computed(() => {
  if (activeFilter.value === 'agents') return agentItems.value;
  if (activeFilter.value === 'teams') return teamItems.value;

  return [
    ...agentItems.value.map(item => ({
      ...item,
      group: t('CONVERSATION.MENTION.AGENTS'),
    })),
    ...teamItems.value.map(item => ({
      ...item,
      group: t('CONVERSATION.MENTION.TEAMS'),
    })),
  ];
});

// The arrows belong to the caret once there is a query to move through. RTL reverses the
// row, so the arrow that moves forward flips with it.
const navigateFilters = event => {
  if (searchQuery.value) return;

  const step = (event.key === 'ArrowRight') !== isRTL.value ? 1 : -1;
  const index = tabs.value.findIndex(tab => tab.value === activeFilter.value);
  const next = tabs.value[index + step];
  if (!next) return;

  event.preventDefault();
  activeFilter.value = next.value;
};

useKeyboardEvents({
  ArrowLeft: { action: navigateFilters, allowOnFocusedInput: true },
  ArrowRight: { action: navigateFilters, allowOnFocusedInput: true },
});

const availabilityLabels = computed(() => ({
  online: t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.ONLINE'),
  busy: t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.BUSY'),
  offline: t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE'),
}));

const availabilityLabel = status => availabilityLabels.value[status] ?? '';

const onSelect = item => emit('selectAgent', item.record);
</script>

<template>
  <CaretAnchoredPicker
    v-model:search="searchQuery"
    :caret-position="caretPosition"
    :items="items"
    :search-placeholder="t('CONVERSATION.PICKER.MENTION.SEARCH_PLACEHOLDER')"
    :empty-label="t('COMBOBOX.EMPTY_STATE')"
    @select="onSelect"
    @close="emit('close')"
    @remove-trigger="emit('removeTrigger')"
  >
    <template #filters>
      <div role="tablist" class="flex items-center min-w-0 gap-1">
        <button
          v-for="tab in tabs"
          :key="tab.value"
          type="button"
          role="tab"
          :aria-selected="activeFilter === tab.value"
          class="flex items-center min-w-0 gap-1 px-2 py-1 text-xs font-medium transition-colors rounded-md"
          :class="
            activeFilter === tab.value
              ? 'bg-n-alpha-1 dark:bg-n-alpha-2 text-n-slate-12'
              : 'text-n-slate-11 hover:bg-n-alpha-1'
          "
          @click="activeFilter = tab.value"
        >
          <span class="truncate">{{ tab.label }}</span>
          <span v-if="tab.count !== undefined" class="text-n-slate-10">
            {{ tab.count }}
          </span>
        </button>
      </div>
    </template>
    <template #leading="{ item }">
      <EmojiIcon
        v-if="item.record.type === 'team' && item.record.icon"
        :value="item.record.icon"
        :color="item.record.icon_color"
        class="flex-shrink-0 text-xl size-6"
      />
      <Avatar
        v-else
        :src="item.record.thumbnail"
        :name="item.label"
        :size="24"
        rounded-full
        class="flex-shrink-0"
      />
    </template>
    <template #preview="{ item }">
      <div v-if="item" class="flex flex-col gap-3 px-4 py-3">
        <div class="flex items-start gap-3">
          <EmojiIcon
            v-if="item.record.type === 'team' && item.record.icon"
            :value="item.record.icon"
            :color="item.record.icon_color"
            class="flex-shrink-0 text-3xl size-10"
          />
          <Avatar
            v-else
            :src="item.record.thumbnail"
            :name="item.label"
            :size="40"
            :status="item.record.availability_status"
            rounded-full
            class="flex-shrink-0"
          />
          <div class="flex flex-col min-w-0 gap-0.5">
            <span class="text-sm font-medium truncate text-n-slate-12">
              {{ item.label }}
            </span>
            <span
              v-if="item.subtitle"
              class="text-xs break-words text-n-slate-11"
            >
              {{ item.subtitle }}
            </span>
          </div>
        </div>
        <div
          v-if="item.record.type === 'user'"
          class="flex flex-col gap-2 text-xs"
        >
          <div class="flex items-center justify-between gap-2">
            <span class="text-n-slate-10">
              {{ t('CONVERSATION.PICKER.MENTION.AVAILABILITY') }}
            </span>
            <span class="capitalize text-n-slate-12">
              {{ availabilityLabel(item.record.availability_status) }}
            </span>
          </div>
          <div class="flex items-center justify-between gap-2">
            <span class="text-n-slate-10">
              {{ t('CONVERSATION.PICKER.MENTION.ROLE') }}
            </span>
            <span class="capitalize text-n-slate-12">{{
              item.record.role
            }}</span>
          </div>
        </div>
        <div v-else class="flex flex-col gap-2 text-xs">
          <div class="flex items-center justify-between gap-2">
            <span class="text-n-slate-10">
              {{ t('CONVERSATION.PICKER.MENTION.AUTO_ASSIGN') }}
            </span>
            <span class="text-n-slate-12">
              {{
                item.record.allow_auto_assign
                  ? t('CONVERSATION.PICKER.MENTION.ENABLED')
                  : t('CONVERSATION.PICKER.MENTION.DISABLED')
              }}
            </span>
          </div>
          <div v-if="item.record.is_member" class="text-n-slate-11">
            {{ t('CONVERSATION.PICKER.MENTION.YOU_ARE_A_MEMBER') }}
          </div>
        </div>
      </div>
    </template>
  </CaretAnchoredPicker>
</template>
