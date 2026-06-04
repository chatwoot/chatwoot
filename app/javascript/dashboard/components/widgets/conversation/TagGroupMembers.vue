<script setup>
import Avatar from 'next/avatar/Avatar.vue';
import { ref, computed, watch, nextTick } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useKeyboardNavigableList } from 'dashboard/composables/useKeyboardNavigableList';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  searchKey: {
    type: String,
    default: '',
  },
  groupContactId: {
    type: [Number, String],
    required: true,
  },
  excludePhoneNumber: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['selectAgent']);

const { t } = useI18n();
const getters = useStoreGetters();

const groupMembers = computed(() =>
  getters['groupMembers/getGroupMembers'].value(props.groupContactId)
);

const tagGroupMembersRef = ref(null);
const selectedIndex = ref(0);

const items = computed(() => {
  const search = props.searchKey?.trim().toLowerCase() || '';

  const memberItems = groupMembers.value
    .filter(member => member.is_active)
    .filter(member => member.contact?.phone_number !== props.excludePhoneNumber)
    .map(member => ({
      id: member.contact?.id || member.id,
      type: 'contact',
      displayName: member.contact?.name || member.contact?.phone_number || '',
      displayInfo: member.contact?.phone_number || '',
      thumbnail: member.contact?.thumbnail || '',
      name: member.contact?.name || member.contact?.phone_number || '',
    }))
    .filter(item =>
      search
        ? item.displayName.toLowerCase().includes(search) ||
          item.displayInfo.toLowerCase().includes(search)
        : true
    );

  const allItems = [...memberItems];

  if (!allItems.length) return [];

  return [
    {
      type: 'header',
      title: t('GROUP.MENTION.DROPDOWN_HEADER'),
      id: 'group-members-header',
    },
    ...allItems,
  ];
});

const selectableItems = computed(() => {
  return items.value.filter(item => item.type !== 'header');
});

const getSelectableIndex = item => {
  return selectableItems.value.findIndex(
    selectableItem =>
      selectableItem.type === item.type && selectableItem.id === item.id
  );
};

const adjustScroll = () => {
  nextTick(() => {
    if (tagGroupMembersRef.value) {
      const selectedElement = tagGroupMembersRef.value.querySelector(
        `#mention-item-${selectedIndex.value}`
      );
      if (selectedElement) {
        selectedElement.scrollIntoView({
          block: 'nearest',
          behavior: 'auto',
        });
      }
    }
  });
};

const onSelect = () => {
  emit('selectAgent', selectableItems.value[selectedIndex.value]);
};

useKeyboardNavigableList({
  items: selectableItems,
  onSelect,
  adjustScroll,
  selectedIndex,
});

watch(selectableItems, newList => {
  if (newList.length < selectedIndex.value + 1) {
    selectedIndex.value = 0;
  }
});

const onHover = index => {
  selectedIndex.value = index;
};

const onMemberSelect = index => {
  selectedIndex.value = index;
  onSelect();
};
</script>

<template>
  <div>
    <ul
      v-if="items.length"
      ref="tagGroupMembersRef"
      class="vertical dropdown menu mention--box bg-n-solid-1 p-1 rounded-xl text-sm overflow-auto absolute w-full z-20 shadow-md left-0 leading-[1.2] bottom-full max-h-[12.5rem] border border-solid border-n-strong"
      role="listbox"
    >
      <li
        v-for="item in items"
        :id="
          item.type === 'header'
            ? undefined
            : `mention-item-${getSelectableIndex(item)}`
        "
        :key="`${item.type}-${item.id}`"
      >
        <!-- Section Header -->
        <div
          v-if="item.type === 'header'"
          class="px-2 py-2 text-xs font-medium tracking-wide capitalize text-n-slate-11"
        >
          {{ item.title }}
        </div>
        <!-- Selectable Item -->
        <div
          v-else
          :class="{
            'bg-n-alpha-black2': getSelectableIndex(item) === selectedIndex,
          }"
          class="flex items-center px-2 py-1 rounded-md cursor-pointer"
          role="option"
          @click="onMemberSelect(getSelectableIndex(item))"
          @mouseover="onHover(getSelectableIndex(item))"
        >
          <div class="ltr:mr-2 rtl:ml-2">
            <Avatar
              :src="item.thumbnail"
              :name="item.displayName"
              rounded-full
            />
          </div>
          <div
            class="overflow-hidden flex-1 max-w-full whitespace-nowrap text-ellipsis"
          >
            <h5
              class="overflow-hidden mb-0 text-sm capitalize whitespace-nowrap text-n-slate-11 text-ellipsis"
              :class="{
                'text-n-slate-12': getSelectableIndex(item) === selectedIndex,
              }"
            >
              {{ item.displayName }}
            </h5>
            <div
              class="overflow-hidden text-xs whitespace-nowrap text-ellipsis text-n-slate-10"
              :class="{
                'text-n-slate-11': getSelectableIndex(item) === selectedIndex,
              }"
            >
              {{ item.displayInfo }}
            </div>
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
