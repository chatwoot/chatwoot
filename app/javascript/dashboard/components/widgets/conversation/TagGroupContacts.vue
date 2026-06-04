<script setup>
import Avatar from 'next/avatar/Avatar.vue';
import { ref, computed, watch, nextTick } from 'vue';
import { useKeyboardNavigableList } from 'dashboard/composables/useKeyboardNavigableList';

const props = defineProps({
  contacts: {
    type: Array,
    default: () => [],
  },
  searchKey: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['selectContact']);

const contactsRef = ref(null);
const selectedIndex = ref(0);

const displayName = item =>
  item.displayName || item.name || item.whatsapp_username || item.bsuid || '';

const displayInfo = item =>
  [item.whatsapp_username, item.bsuid, item.phone_number]
    .filter(Boolean)
    .join(' · ');

const items = computed(() => {
  const search = props.searchKey.trim().toLowerCase();

  return props.contacts
    .map(contact => ({
      ...contact,
      type: 'group_contact',
      displayName: displayName(contact),
      displayInfo: displayInfo(contact),
    }))
    .filter(item => {
      if (!item.id || !item.bsuid) return false;
      if (!search) return true;

      return [item.displayName, item.displayInfo]
        .filter(Boolean)
        .some(value => value.toLowerCase().includes(search));
    });
});

const adjustScroll = () => {
  nextTick(() => {
    const container = contactsRef.value;
    if (!container) return;

    const selectedElement = container.querySelector(
      `#group-contact-mention-item-${selectedIndex.value}`
    );
    selectedElement?.scrollIntoView({ block: 'nearest', behavior: 'auto' });
  });
};

const onSelect = () => {
  const item = items.value[selectedIndex.value];
  if (item) emit('selectContact', item);
};

useKeyboardNavigableList({
  items,
  onSelect,
  adjustScroll,
  selectedIndex,
});

watch(items, newItems => {
  if (newItems.length < selectedIndex.value + 1) {
    selectedIndex.value = 0;
  }
});

const onHover = index => {
  selectedIndex.value = index;
};

const onContactSelect = index => {
  selectedIndex.value = index;
  onSelect();
};
</script>

<template>
  <div>
    <ul
      v-if="items.length"
      ref="contactsRef"
      class="vertical dropdown menu mention--box bg-n-solid-1 p-1 rounded-xl text-sm overflow-auto absolute w-full z-20 shadow-md left-0 leading-[1.2] bottom-full max-h-[12.5rem] border border-solid border-n-strong"
      role="listbox"
    >
      <li
        v-for="(item, index) in items"
        :id="`group-contact-mention-item-${index}`"
        :key="`${item.id}-${item.bsuid}`"
      >
        <div
          :class="{ 'bg-n-alpha-black2': index === selectedIndex }"
          class="flex items-center px-2 py-1 rounded-md cursor-pointer"
          role="option"
          @click="onContactSelect(index)"
          @mouseover="onHover(index)"
        >
          <div class="ltr:mr-2 rtl:ml-2">
            <Avatar
              :src="item.thumbnail"
              :name="item.displayName"
              rounded-full
            />
          </div>
          <div class="overflow-hidden flex-1 max-w-full whitespace-nowrap">
            <h5
              class="overflow-hidden mb-0 text-sm capitalize whitespace-nowrap text-n-slate-11 text-ellipsis"
              :class="{ 'text-n-slate-12': index === selectedIndex }"
            >
              {{ item.displayName }}
            </h5>
            <div
              class="overflow-hidden text-xs whitespace-nowrap text-ellipsis text-n-slate-10"
              :class="{ 'text-n-slate-11': index === selectedIndex }"
            >
              {{ item.displayInfo }}
            </div>
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
