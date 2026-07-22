<script setup>
import { computed, ref } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  // Null while a fetch is in flight so stale counts are never shown.
  totalCount: {
    type: Number,
    default: null,
  },
  agents: {
    type: Array,
    default: () => [],
  },
  inboxes: {
    type: Array,
    default: () => [],
  },
  // Self-scoped viewers only ever see their own calls, so the assignee filter
  // is meaningless for them — only admins get it.
  showAssignee: {
    type: Boolean,
    default: false,
  },
});

const activity = defineModel('activity', { type: String, default: null });
const assigneeId = defineModel('assigneeId', { type: Number, default: null });
const inboxId = defineModel('inboxId', { type: Number, default: null });

const { t } = useI18n();

const ACTIVITY_ICONS = {
  missed: 'i-lucide-phone-missed',
  no_reply: 'i-lucide-phone-outgoing',
  incoming: 'i-lucide-phone-incoming',
  outgoing: 'i-lucide-phone-outgoing',
  in_progress: 'i-lucide-phone-call',
};

const BASE_ACTIVITIES = ['missed', 'no_reply'];
const OTHER_ACTIVITIES = ['incoming', 'outgoing', 'in_progress'];

// A single open-menu identifier keeps the three dropdowns mutually exclusive:
// opening one closes the others without any cross-wiring.
const openMenu = ref(null); // 'activity' | 'assignee' | 'more' | null

const toggleMenu = name => {
  openMenu.value = openMenu.value === name ? null : name;
};

// Each dropdown wrapper closes itself on outside clicks. The guard keeps the
// other two wrappers (which the click is also outside of) from closing a
// menu the user is interacting with.
const closeOnOutside = name => {
  if (openMenu.value === name) openMenu.value = null;
};

const activityLabel = value => t(`CALLS_PAGE.FILTERS.${value.toUpperCase()}`);

const activeChipLabel = computed(() => {
  const label = activityLabel(activity.value);
  return props.totalCount === null ? label : `${label} (${props.totalCount})`;
});

const inactiveChips = computed(() =>
  BASE_ACTIVITIES.filter(value => value !== activity.value)
);

const otherActivityItems = computed(() =>
  OTHER_ACTIVITIES.map(value => ({
    label: activityLabel(value),
    value,
    action: 'filter',
    icon: ACTIVITY_ICONS[value],
    isSelected: activity.value === value,
  }))
);

const assigneeItems = computed(() => [
  {
    label: t('CALLS_PAGE.FILTERS.ALL_ASSIGNEES'),
    value: null,
    action: 'filter',
    isSelected: !assigneeId.value,
  },
  ...props.agents.map(agent => ({
    label: agent.name,
    value: agent.id,
    action: 'filter',
    thumbnail: { name: agent.name, src: agent.thumbnail },
    isSelected: assigneeId.value === agent.id,
  })),
]);

const moreFiltersSections = computed(() => [
  {
    title: t('CALLS_PAGE.FILTERS.INBOX'),
    items: [
      {
        label: t('CALLS_PAGE.FILTERS.ALL_INBOXES'),
        value: null,
        action: 'inbox',
        isSelected: !inboxId.value,
      },
      ...props.inboxes.map(inbox => ({
        label: inbox.name,
        value: inbox.id,
        action: 'inbox',
        isSelected: inboxId.value === inbox.id,
      })),
    ],
  },
]);

const selectedAssigneeLabel = computed(
  () =>
    props.agents.find(agent => agent.id === assigneeId.value)?.name ||
    t('CALLS_PAGE.FILTERS.ASSIGNEE')
);

const hasMoreFilters = computed(() => Boolean(inboxId.value));

const setActivity = value => {
  openMenu.value = null;
  activity.value = value;
};

const setAssignee = ({ value }) => {
  openMenu.value = null;
  assigneeId.value = value;
};

const applyMoreFilter = ({ action, value }) => {
  openMenu.value = null;
  if (action === 'inbox') inboxId.value = value;
};
</script>

<template>
  <div class="flex flex-wrap items-center justify-between gap-3">
    <div class="flex flex-wrap items-center gap-3">
      <span v-if="!activity" class="text-heading-3 text-n-slate-11 shrink-0">
        {{
          totalCount === null
            ? t('CALLS_PAGE.ALL_CALLS')
            : t('CALLS_PAGE.ALL_CALLS_COUNT', { count: totalCount })
        }}
      </span>
      <Button
        v-else
        variant="outline"
        color="blue"
        size="sm"
        :icon="ACTIVITY_ICONS[activity]"
        class="shrink-0"
        @click="setActivity(null)"
      >
        {{ activeChipLabel }}
        <Icon icon="i-lucide-x" />
      </Button>
      <div class="w-px h-4 bg-n-strong shrink-0" />
      <Button
        v-for="chip in inactiveChips"
        :key="chip"
        variant="outline"
        color="slate"
        size="sm"
        :icon="ACTIVITY_ICONS[chip]"
        :label="activityLabel(chip)"
        class="shrink-0 text-n-slate-12"
        @click="setActivity(chip)"
      />
      <OnClickOutside
        class="relative shrink-0"
        @trigger="closeOnOutside('activity')"
      >
        <Button
          variant="outline"
          color="slate"
          size="sm"
          icon="i-lucide-phone"
          class="text-n-slate-12"
          @click="toggleMenu('activity')"
        >
          {{ t('CALLS_PAGE.FILTERS.OTHER_ACTIVITY') }}
          <Icon icon="i-lucide-chevron-down" class="text-n-slate-11" />
        </Button>
        <DropdownMenu
          v-if="openMenu === 'activity'"
          :menu-items="otherActivityItems"
          class="mt-1 start-0 top-full w-44"
          @action="setActivity($event.value)"
        />
      </OnClickOutside>
    </div>
    <div class="flex items-center gap-2 shrink-0">
      <OnClickOutside
        v-if="showAssignee"
        class="relative"
        @trigger="closeOnOutside('assignee')"
      >
        <Button
          variant="outline"
          color="slate"
          size="sm"
          icon="i-lucide-user-round-cog"
          class="max-w-52 text-n-slate-12"
          @click="toggleMenu('assignee')"
        >
          <span class="truncate">{{ selectedAssigneeLabel }}</span>
          <Icon icon="i-lucide-chevron-down" class="text-n-slate-11 shrink-0" />
        </Button>
        <DropdownMenu
          v-if="openMenu === 'assignee'"
          :menu-items="assigneeItems"
          show-search
          class="mt-1 end-0 top-full w-56 max-h-72"
          @action="setAssignee"
        />
      </OnClickOutside>
      <OnClickOutside class="relative" @trigger="closeOnOutside('more')">
        <Button
          variant="outline"
          size="sm"
          icon="i-lucide-list-filter"
          :color="hasMoreFilters ? 'blue' : 'slate'"
          :class="hasMoreFilters ? '' : 'text-n-slate-12'"
          @click="toggleMenu('more')"
        >
          {{ t('CALLS_PAGE.FILTERS.MORE_FILTERS') }}
          <Icon
            icon="i-lucide-chevron-down"
            :class="hasMoreFilters ? '' : 'text-n-slate-11'"
          />
        </Button>
        <DropdownMenu
          v-if="openMenu === 'more'"
          :menu-sections="moreFiltersSections"
          class="mt-1 end-0 top-full w-56 max-h-80"
          @action="applyMoreFilter"
        />
      </OnClickOutside>
    </div>
  </div>
</template>
