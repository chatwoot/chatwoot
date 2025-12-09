<script setup>
import { ref, computed, defineModel, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { debounce } from '@chatwoot/utils';
import { useMapGetter } from 'dashboard/composables/store.js';
import { searchContacts } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { fetchContactDetails } from '../helpers/searchHelper';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  label: { type: String, required: true },
});

const emit = defineEmits(['change']);

const FROM_TYPE = {
  CONTACT: 'contact',
  AGENT: 'agent',
};

const MENU_ACTIONS_SELECT = 'select';

const modelValue = defineModel({ type: String, default: null });

const { t } = useI18n();
const [showDropdown, toggleDropdown] = useToggle();

const searchQuery = ref('');
const searchedContacts = ref([]);
const isSearching = ref(false);
const selectedContact = ref(null);

const agentsList = useMapGetter('agents/getVerifiedAgents');

const createMenuItem = (item, type, isAgent = false) => {
  const transformed = useCamelCase(item, { deep: true });
  const value = `${type}:${transformed.id}`;
  return {
    label: transformed.name,
    value,
    action: MENU_ACTIONS_SELECT,
    type,
    thumbnail: {
      name: transformed.name,
      src: isAgent ? transformed.avatarUrl : transformed.thumbnail,
    },
    ...(isAgent
      ? {}
      : { description: transformed.email || transformed.phoneNumber }),
    isSelected: modelValue.value === value,
  };
};

const agentsSection = computed(() => {
  const agents =
    agentsList.value?.map(agent =>
      createMenuItem(agent, FROM_TYPE.AGENT, true)
    ) || [];
  return searchQuery.value
    ? agents.filter(agent =>
        agent.label.toLowerCase().includes(searchQuery.value.toLowerCase())
      )
    : agents;
});

const contactsSection = computed(
  () =>
    searchedContacts.value?.map(contact =>
      createMenuItem(contact, FROM_TYPE.CONTACT)
    ) || []
);

const menuSections = computed(() => [
  {
    title: t('SEARCH.FILTERS.CONTACTS'),
    items: contactsSection.value,
    isLoading: isSearching.value,
    emptyState: t('SEARCH.FILTERS.NO_CONTACTS'),
  },
  {
    title: t('SEARCH.FILTERS.AGENTS'),
    items: agentsSection.value,
    emptyState: t('SEARCH.FILTERS.NO_AGENTS'),
  },
]);

const selectedLabel = computed(() => {
  if (!modelValue.value) return props.label;

  const [type, id] = modelValue.value.split(':');
  const numericId = Number(id);

  if (type === FROM_TYPE.CONTACT) {
    if (selectedContact.value?.id === numericId) {
      return `${props.label}: ${selectedContact.value.name}`;
    }
    const contact = searchedContacts.value?.find(c => c.id === numericId);
    if (contact) return `${props.label}: ${contact.name}`;
  } else if (type === FROM_TYPE.AGENT) {
    const agent = agentsList.value?.find(a => a.id === numericId);
    if (agent) return `${props.label}: ${agent.name}`;
  }

  return `${props.label}: ${numericId}`;
});

const debouncedSearch = debounce(async query => {
  if (!query) {
    searchedContacts.value = selectedContact.value
      ? [selectedContact.value]
      : [];
    isSearching.value = false;
    return;
  }

  try {
    const contacts = await searchContacts({
      keys: ['name', 'email', 'phone_number'],
      query,
    });

    // Add selected contact to top if not already in results
    const allContacts = selectedContact.value
      ? [
          selectedContact.value,
          ...contacts.filter(c => c.id !== selectedContact.value.id),
        ]
      : contacts;

    searchedContacts.value = allContacts;
  } catch {
    // Ignore error
  } finally {
    isSearching.value = false;
  }
}, 300);

const performSearch = query => {
  searchQuery.value = query;
  if (query) {
    searchedContacts.value = selectedContact.value
      ? [selectedContact.value]
      : [];
    isSearching.value = true;
  }
  debouncedSearch(query);
};

const onToggleDropdown = () => {
  if (!showDropdown.value) {
    // Reset search when opening dropdown
    searchQuery.value = '';
    searchedContacts.value = selectedContact.value
      ? [selectedContact.value]
      : [];
  }
  toggleDropdown();
};

const handleAction = item => {
  if (modelValue.value === item.value) {
    modelValue.value = null;
    selectedContact.value = null;
  } else {
    modelValue.value = item.value;

    if (item.type === FROM_TYPE.CONTACT) {
      const [, id] = item.value.split(':');
      selectedContact.value = {
        id: Number(id),
        name: item.label,
        thumbnail: item.thumbnail?.src,
      };
    } else {
      selectedContact.value = null;
    }
  }

  toggleDropdown(false);
  emit('change');
};

const resolveContactName = async () => {
  if (!modelValue.value) return;

  const [type, id] = modelValue.value.split(':');
  if (type !== FROM_TYPE.CONTACT) return;

  const numericId = Number(id);
  if (selectedContact.value?.id === numericId) return;

  const contact = await fetchContactDetails(numericId);
  if (contact) {
    selectedContact.value = {
      id: contact.id,
      name: contact.name,
      thumbnail: contact.thumbnail,
    };
    if (!searchedContacts.value.some(c => c.id === contact.id)) {
      searchedContacts.value.push(selectedContact.value);
    }
  }
};

watch(() => modelValue.value, resolveContactName, { immediate: true });
</script>

<template>
  <div
    v-on-click-outside="() => toggleDropdown(false)"
    class="relative flex items-center group min-w-0 max-w-full"
  >
    <Button
      sm
      :variant="showDropdown ? 'faded' : 'ghost'"
      slate
      :label="selectedLabel"
      trailing-icon
      icon="i-lucide-chevron-down"
      class="!px-2 max-w-full"
      @click="onToggleDropdown"
    />
    <DropdownMenu
      v-if="showDropdown"
      :menu-sections="menuSections"
      show-search
      disable-local-filtering
      :is-searching="isSearching"
      class="mt-1 ltr:left-0 rtl:right-0 top-full w-64 max-h-80 overflow-y-auto"
      @search="performSearch"
      @action="handleAction"
    />
  </div>
</template>
