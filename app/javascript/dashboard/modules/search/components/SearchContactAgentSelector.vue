<script setup>
import { ref, computed, defineModel } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { debounce } from '@chatwoot/utils';
import { useMapGetter } from 'dashboard/composables/store.js';
import { searchContacts } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  label: {
    type: String,
    required: true,
  },
});

const modelValue = defineModel({
  type: [String, Number],
  default: null,
});

const MENU_ITEM_TYPES = {
  AGENT: 'agent',
  CONTACT: 'contact',
};

const MENU_ACTIONS = {
  SELECT: 'select',
};

const SEARCH_KEYS = ['name', 'email', 'phone_number'];
const DEBOUNCE_DELAY = 300;

const { t } = useI18n();
const [showDropdown, toggleDropdown] = useToggle();

const searchQuery = ref('');
const searchedContacts = ref([]);
const isSearching = ref(false);

const selectedContact = ref(null);

const agentsList = useMapGetter('agents/getVerifiedAgents');

const agentsSection = computed(() => {
  const agents = agentsList.value?.map(agent => {
    const transformedAgent = useCamelCase(agent, { deep: true });
    return {
      label: transformedAgent.name,
      value: transformedAgent.id,
      action: MENU_ACTIONS.SELECT,
      type: MENU_ITEM_TYPES.AGENT,
      thumbnail: {
        name: transformedAgent.name,
        src: transformedAgent.avatarUrl,
      },
      isSelected: modelValue.value === transformedAgent.id,
    };
  });

  if (!searchQuery.value) return agents;

  return agents.filter(agent =>
    agent.label.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

const contactsSection = computed(() => {
  return searchedContacts.value?.map(contact => {
    const transformedContact = useCamelCase(contact, { deep: true });
    const label = transformedContact.name;
    const description =
      transformedContact.email || transformedContact.phoneNumber;

    return {
      label: label,
      value: transformedContact.id,
      action: MENU_ACTIONS.SELECT,
      type: MENU_ITEM_TYPES.CONTACT,
      thumbnail: {
        name: transformedContact.name,
        src: transformedContact.thumbnail,
      },
      description,
      isSelected: modelValue.value === transformedContact.id,
    };
  });
});

const menuSections = computed(() => {
  return [
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
  ];
});

const selectedLabel = computed(() => {
  if (!modelValue.value) return props.label;

  // Check in preserved selected contact
  if (selectedContact.value && selectedContact.value.id === modelValue.value) {
    return `${props.label}: ${selectedContact.value.name}`;
  }

  // Check in agents
  const agent = agentsList.value?.find(a => a.id === modelValue.value);
  if (agent) return `${props.label}: ${agent.name}`;

  // Check in searched contacts
  const contact = searchedContacts.value?.find(c => c.id === modelValue.value);
  if (contact) return `${props.label}: ${contact.name}`;

  return `${props.label}: ${modelValue.value}`;
});

const debouncedSearch = debounce(async query => {
  if (!query) {
    searchedContacts.value = [];
    isSearching.value = false;
    return;
  }

  try {
    const contacts = await searchContacts({
      keys: SEARCH_KEYS,
      query,
    });
    searchedContacts.value = contacts;
  } catch (error) {
    // Ignore error
  } finally {
    isSearching.value = false;
  }
}, DEBOUNCE_DELAY);

const performSearch = query => {
  searchQuery.value = query;
  if (query) {
    searchedContacts.value = [];
    isSearching.value = true;
  }
  debouncedSearch(query);
};

const handleAction = item => {
  if (item.type === MENU_ITEM_TYPES.CONTACT) {
    selectedContact.value = { id: item.value, name: item.label };
  } else {
    selectedContact.value = null;
  }
  modelValue.value = item.value;
  toggleDropdown(false);
};

const onToggleDropdown = () => {
  if (!showDropdown.value) {
    searchQuery.value = '';
    searchedContacts.value = [];
  }
  toggleDropdown();
};
</script>

<template>
  <div
    v-on-click-outside="() => toggleDropdown(false)"
    class="relative flex items-center group"
  >
    <Button
      sm
      outline
      slate
      :label="selectedLabel"
      trailing-icon
      icon="i-lucide-chevron-down"
      class="outline-dashed"
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
