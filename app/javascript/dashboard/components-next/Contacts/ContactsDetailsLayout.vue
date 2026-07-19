<script setup>
import { computed, useSlots, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { vOnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';
import ContactDetailMoreActions from 'dashboard/components-next/Contacts/ContactDetailMoreActions.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: () => ({}),
  },
  isUpdating: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['goToContactsList', 'toggleBlock', 'edit']);

const { t } = useI18n();
const slots = useSlots();
const route = useRoute();

const isContactSidebarOpen = ref(false);

const contactId = computed(() => route.params.contactId);

const selectedContactName = computed(() => {
  const name = props.selectedContact?.name?.toString().trim();
  if (name && name !== '.') return name;
  return (
    props.selectedContact?.phoneNumber ||
    props.selectedContact?.email ||
    t('CONTACTS_LAYOUT.HEADER.BREADCRUMB.FALLBACK_NAME')
  );
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

const isContactBlocked = computed(() => {
  return props.selectedContact?.blocked;
});

const handleBreadcrumbClick = () => {
  emit('goToContactsList');
};

const toggleBlock = () => {
  emit('toggleBlock', isContactBlocked.value);
};

const handleConversationSidebarToggle = () => {
  isContactSidebarOpen.value = !isContactSidebarOpen.value;
};

const closeMobileSidebar = () => {
  if (!isContactSidebarOpen.value) return;
  isContactSidebarOpen.value = false;
};
</script>

<template>
  <section class="flex w-full min-w-0 h-full overflow-hidden bg-n-surface-1">
    <div class="flex flex-col flex-1 min-w-0 min-h-0 overflow-hidden">
      <header class="sticky top-0 z-10 px-6 3xl:px-8 bg-n-surface-1">
        <div class="w-full max-w-full">
          <div
            class="flex flex-col xs:flex-row items-start xs:items-center justify-between w-full py-5 gap-2"
          >
            <Breadcrumb
              :items="breadcrumbItems"
              @click="handleBreadcrumbClick"
            />
            <div class="flex items-center gap-2">
              <Button
                :label="$t('CONTACTS_LAYOUT.HEADER.EDIT')"
                size="sm"
                slate
                icon="i-lucide-pencil"
                @click="emit('edit')"
              />
              <Button
                :label="
                  !isContactBlocked
                    ? $t('CONTACTS_LAYOUT.HEADER.BLOCK_CONTACT')
                    : $t('CONTACTS_LAYOUT.HEADER.UNBLOCK_CONTACT')
                "
                size="sm"
                slate
                :is-loading="isUpdating"
                :disabled="isUpdating"
                @click="toggleBlock"
              />
              <VoiceCallButton
                :phone="selectedContact?.phoneNumber"
                :contact-id="contactId"
                :label="$t('CONTACT_PANEL.CALL')"
                size="sm"
              />
              <ComposeConversation :contact-id="contactId">
                <template #trigger>
                  <Button
                    :label="$t('CONTACTS_LAYOUT.HEADER.SEND_MESSAGE')"
                    size="sm"
                  />
                </template>
              </ComposeConversation>
              <ContactDetailMoreActions
                v-if="selectedContact?.id"
                :selected-contact="selectedContact"
                @go-to-contacts-list="emit('goToContactsList')"
              />
            </div>
          </div>
        </div>
      </header>
      <main class="flex-1 min-h-0 px-6 overflow-y-auto 3xl:px-8">
        <div class="w-full py-3 max-w-full">
          <slot name="default" />
        </div>
      </main>
    </div>

    <!-- Desktop sidebar -->
    <div
      v-if="slots.sidebar"
      class="hidden lg:flex flex-col shrink-0 w-80 xl:w-96 min-h-0 border-l border-n-weak bg-n-solid-2"
    >
      <div class="shrink-0">
        <slot name="sidebarHeader" />
      </div>
      <div class="flex-1 min-h-0 overflow-y-auto pb-4 pt-2">
        <slot name="sidebar" />
      </div>
    </div>

    <!-- Mobile sidebar container -->
    <div
      v-if="slots.sidebar"
      class="lg:hidden fixed top-0 ltr:right-0 rtl:left-0 h-full z-50 flex justify-end transition-all duration-200 ease-in-out"
      :class="isContactSidebarOpen ? 'w-full' : 'w-16'"
    >
      <div
        v-on-click-outside="[
          closeMobileSidebar,
          { ignore: ['#contact-sidebar-content'] },
        ]"
        class="flex items-start p-1 w-fit h-fit relative order-1 xs:top-24 top-28 transition-all bg-n-solid-2 border border-n-weak duration-500 ease-in-out"
        :class="[
          isContactSidebarOpen
            ? 'justify-end ltr:rounded-l-full rtl:rounded-r-full ltr:rounded-r-none rtl:rounded-l-none'
            : 'justify-center rounded-full ltr:mr-6 rtl:ml-6',
        ]"
      >
        <Button
          ghost
          slate
          sm
          class="!rounded-full rtl:rotate-180"
          :class="{ 'bg-n-alpha-2': isContactSidebarOpen }"
          :icon="
            isContactSidebarOpen
              ? 'i-lucide-panel-right-close'
              : 'i-lucide-panel-right-open'
          "
          data-contact-sidebar-toggle
          @click="handleConversationSidebarToggle"
        />
      </div>

      <Transition
        enter-active-class="transition-transform duration-200 ease-in-out"
        leave-active-class="transition-transform duration-200 ease-in-out"
        enter-from-class="ltr:translate-x-full rtl:-translate-x-full"
        enter-to-class="ltr:translate-x-0 rtl:-translate-x-0"
        leave-from-class="ltr:translate-x-0 rtl:-translate-x-0"
        leave-to-class="ltr:translate-x-full rtl:-translate-x-full"
      >
        <div
          v-if="isContactSidebarOpen"
          id="contact-sidebar-content"
          class="order-2 w-[85%] sm:w-[50%] flex flex-col bg-n-solid-2 ltr:border-l rtl:border-r border-n-weak shadow-lg"
        >
          <div class="shrink-0">
            <slot name="sidebarHeader" />
          </div>
          <div class="flex-1 min-h-0 overflow-y-auto pb-4 pt-2">
            <slot name="sidebar" />
          </div>
        </div>
      </Transition>
    </div>
  </section>
</template>
