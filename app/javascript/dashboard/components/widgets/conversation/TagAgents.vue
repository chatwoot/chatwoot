<script setup>
import { computed, watchEffect } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
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

const emit = defineEmits(['selectAgent', 'close']);

const MAX_SUGGESTIONS = 6;

const hasMatches = defineModel('hasMatches', { type: Boolean, default: false });

const { t } = useI18n();

const agents = useMapGetter('agents/getVerifiedAgents');
const teams = useMapGetter('teams/getTeams');

const mentionCounts = LocalStorage.get(LOCAL_STORAGE_KEYS.MENTION_COUNTS) || {};

const buildItems = (records, type, subtitleKey, group) => {
  const matches = records
    .filter(({ name }) =>
      name?.toLowerCase().includes(props.searchKey.toLowerCase())
    )
    .map(record => ({
      id: `${type}-${record.id}`,
      record: { ...record, type },
      label: record.name,
      subtitle: record[subtitleKey],
      group,
    }))
    .sort((a, b) => (mentionCounts[b.id] || 0) - (mentionCounts[a.id] || 0));

  return props.searchKey ? matches : matches.slice(0, MAX_SUGGESTIONS);
};

const items = computed(() => [
  ...buildItems(
    agents.value,
    'user',
    'email',
    t('CONVERSATION.MENTION.AGENTS')
  ),
  ...buildItems(
    teams.value,
    'team',
    'description',
    t('CONVERSATION.MENTION.TEAMS')
  ),
]);

watchEffect(() => {
  hasMatches.value = items.value.length > 0;
});

const onSelect = item => {
  LocalStorage.updateJsonStore(
    LOCAL_STORAGE_KEYS.MENTION_COUNTS,
    item.id,
    (mentionCounts[item.id] || 0) + 1
  );
  emit('selectAgent', item.record);
};
</script>

<template>
  <CaretAnchoredPicker
    v-if="items.length"
    search-in-editor
    :caret-position="caretPosition"
    :items="items"
    :search-placeholder="t('CONVERSATION.PICKER.MENTION.SEARCH_PLACEHOLDER')"
    @select="onSelect"
    @close="emit('close')"
  >
    <template #item="{ item, selected }">
      <EmojiIcon
        v-if="item.record.icon"
        :value="item.record.icon"
        :color="item.record.icon_color"
        class="flex-shrink-0 my-0.5 text-xl size-6"
      />
      <Avatar
        v-else
        :src="item.record.thumbnail"
        :name="item.label"
        :size="24"
        :status="item.record.availability_status"
        rounded-full
        class="flex-shrink-0 my-0.5"
      />
      <span class="min-w-0 truncate text-heading-3 text-n-slate-12">
        {{ item.label }}
      </span>
      <span
        v-if="item.subtitle"
        class="flex-1 min-w-0 truncate text-body-main text-n-slate-11"
      >
        {{ item.subtitle }}
      </span>
      <kbd
        v-if="selected"
        class="flex items-center flex-shrink-0 p-1 border rounded ms-auto border-n-strong text-n-slate-11"
      >
        <Icon icon="i-lucide-corner-down-left" class="size-3" />
      </kbd>
    </template>
  </CaretAnchoredPicker>
  <template v-else />
</template>
