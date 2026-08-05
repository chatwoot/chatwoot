<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { SENDER_LIST_TYPES } from 'dashboard/constants/senderLists';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  email: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const store = useStore();

const showDropdown = ref(false);

const entries = useMapGetter('senderListEntries/getEntries');

const normalizedEmail = computed(() => props.email?.trim().toLowerCase() || '');
const domain = computed(() => normalizedEmail.value.split('@')[1] || '');

const findEntry = value =>
  entries.value.find(entry => entry.value.toLowerCase() === value) || null;

const emailEntry = computed(() =>
  normalizedEmail.value ? findEntry(normalizedEmail.value) : null
);
const domainEntry = computed(() =>
  domain.value ? findEntry(domain.value) : null
);
const activeEntry = computed(() => emailEntry.value || domainEntry.value);

const listName = listType =>
  t(`SENDER_LISTS.LISTS.${listType.toUpperCase()}.TITLE`);

const statusLabel = computed(() => {
  const entry = activeEntry.value;
  if (!entry) return t('SENDER_LISTS.CONTACT.NOT_LISTED');

  const list = listName(entry.list_type);
  return emailEntry.value
    ? t('SENDER_LISTS.CONTACT.ON_LIST_EMAIL', { list })
    : t('SENDER_LISTS.CONTACT.ON_LIST_DOMAIN', { list, value: entry.value });
});

const statusClass = computed(() => {
  const listType = activeEntry.value?.list_type;
  if (listType === 'vip') return 'bg-n-teal-9/10 text-n-teal-11';
  if (listType === 'blocked') return 'bg-n-ruby-9/10 text-n-ruby-11';
  if (listType === 'allowed') return 'bg-n-alpha-2 text-n-slate-12';
  return 'bg-n-alpha-2 text-n-slate-11';
});

const buildItems = (target, entry) => {
  const items = SENDER_LIST_TYPES.filter(
    listType => listType !== entry?.list_type
  ).map(listType => ({
    label: t(`SENDER_LISTS.CONTACT.ADD_TO_${listType.toUpperCase()}`),
    value: listType,
    action: 'add',
    target,
  }));

  if (entry) {
    items.push({
      label: t('SENDER_LISTS.CONTACT.REMOVE', {
        list: listName(entry.list_type),
      }),
      value: entry.id,
      action: 'delete',
      target,
    });
  }

  return items;
};

const menuSections = computed(() => {
  const sections = [
    {
      title: t('SENDER_LISTS.CONTACT.EMAIL_SECTION'),
      items: buildItems('email', emailEntry.value),
    },
  ];

  if (domain.value) {
    sections.push({
      title: t('SENDER_LISTS.CONTACT.DOMAIN_SECTION', { domain: domain.value }),
      items: buildItems('domain', domainEntry.value),
    });
  }

  return sections;
});

const handleAction = async ({ action, value, target }) => {
  showDropdown.value = false;

  if (action === 'delete') {
    try {
      await store.dispatch('senderListEntries/delete', value);
    } catch (error) {
      useAlert(t('SENDER_LISTS.API.DELETE_ERROR'));
    }
    return;
  }

  try {
    const errors = await store.dispatch('senderListEntries/create', {
      listType: value,
      values: [target === 'domain' ? domain.value : normalizedEmail.value],
    });
    if (errors.length) useAlert(errors[0].message);
  } catch (error) {
    useAlert(t('SENDER_LISTS.API.CREATE_ERROR'));
  }
};

onMounted(() => {
  store.dispatch('senderListEntries/get');
});
</script>

<template>
  <div class="flex items-center gap-2">
    <span class="text-sm text-n-slate-11">
      {{ t('SENDER_LISTS.CONTACT.TITLE') }}
    </span>
    <span
      class="inline-flex items-center h-6 px-2 text-sm rounded-md"
      :class="statusClass"
    >
      {{ statusLabel }}
    </span>
    <div class="relative">
      <button
        v-tooltip.top="t('SENDER_LISTS.CONTACT.MANAGE')"
        class="flex items-center justify-center rounded-md size-6 text-n-slate-11 hover:bg-n-alpha-2"
        :class="{ 'bg-n-alpha-2': showDropdown }"
        @click="showDropdown = !showDropdown"
      >
        <span class="i-lucide-ellipsis size-4" />
      </button>
      <DropdownMenu
        v-if="showDropdown"
        v-on-clickaway="() => (showDropdown = false)"
        :menu-sections="menuSections"
        class="z-[100] w-56 mt-2 ltr:left-0 rtl:right-0 top-full"
        @action="handleAction"
      />
    </div>
  </div>
</template>
