<script setup>
import { computed, useSlots } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';

import Button from 'dashboard/components-next/button/Button.vue';
import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';

const props = defineProps({
  buttonLabel: {
    type: String,
    default: '',
  },
  selectedContact: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['goToContactsList']);

const { t } = useI18n();
const slots = useSlots();
const route = useRoute();

const contactId = computed(() => route.params.contactId);

const selectedContactName = computed(() => {
  return props.selectedContact?.name;
});

const breadcrumbItems = computed(() => {
  const items = [
    {
      label: t('CONTACTS_LAYOUT.HEADER.BREADCRUMB.CONTACTS'),
      link: '#',
    },
  ];
  if (props.selectedContact) {
    items.push({
      label: selectedContactName.value,
    });
  }
  return items;
});

const handleBreadcrumbClick = () => {
  emit('goToContactsList');
};
</script>

<template>
  <section
    class="flex w-full h-full overflow-hidden justify-evenly bg-n-background"
  >
    <div
      class="flex flex-col w-full h-full transition-all duration-300 ltr:2xl:ml-56 rtl:2xl:mr-56"
    >
      <header class="sticky top-0 z-10 px-6 xl:px-0">
        <div class="w-full mx-auto max-w-[650px]">
          <div class="flex items-center justify-between w-full h-20 gap-2">
            <Breadcrumb
              :items="breadcrumbItems"
              @click="handleBreadcrumbClick"
            />
            <ComposeConversation :contact-id="contactId">
              <template #trigger="{ toggle }">
                <Button :label="buttonLabel" size="sm" @click="toggle" />
              </template>
            </ComposeConversation>
          </div>
        </div>
      </header>
      <main class="flex-1 px-6 overflow-y-auto xl:px-px">
        <div class="w-full py-4 mx-auto max-w-[650px]">
          <slot name="default" />
        </div>
      </main>
    </div>

    <div
      v-if="slots.sidebar"
      class="overflow-y-auto justify-end min-w-[200px] w-full py-6 max-w-[440px] border-l border-n-weak bg-n-solid-2"
    >
      <slot name="sidebar" />
    </div>
  </section>
</template>
