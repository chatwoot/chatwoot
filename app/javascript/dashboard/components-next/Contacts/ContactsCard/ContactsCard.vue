<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { debounce } from '@chatwoot/utils';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Thumbnail from 'dashboard/components-next/thumbnail/Thumbnail.vue';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  email: { type: String, default: '' },
  additionalAttributes: { type: Object, default: () => ({}) },
  phoneNumber: { type: String, default: '' },
  thumbnail: { type: String, default: '' },
  isExpanded: { type: Boolean, default: false },
});

const emit = defineEmits(['toggle']);

const { t } = useI18n();
const store = useStore();

const author = computed(() => ({
  name: props.name,
  thumbnail: props.thumbnail,
}));

const updateContact = async updatedData => {
  await store.dispatch('contacts/update', updatedData);
  await store.dispatch('contacts/fetchContactableInbox', props.id);
};

const handleFormUpdate = debounce(
  updatedData => updateContact(updatedData),
  400,
  false
);
</script>

<template>
  <CardLayout :key="id" layout="row">
    <template #header>
      <div class="flex items-center justify-between gap-4">
        <Thumbnail :author="author" :name="name" :src="thumbnail" :size="48" />
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <span class="text-sm font-medium truncate text-n-slate-12">{{
              name
            }}</span>
            <template v-if="additionalAttributes?.company_name">
              <span class="text-sm text-n-slate-11">{{
                t('CONTACTS_LAYOUT.CARD.OF')
              }}</span>
              <span class="text-sm font-medium truncate text-n-slate-12">
                {{ additionalAttributes.company_name }}
              </span>
            </template>
          </div>
          <div class="flex items-center gap-3">
            <span v-if="email" class="text-sm text-n-slate-11">{{
              email
            }}</span>
            <div v-if="phoneNumber" class="w-px h-3 bg-n-slate-6" />
            <span v-if="phoneNumber" class="text-sm text-n-slate-11">{{
              phoneNumber
            }}</span>
            <div v-if="phoneNumber || email" class="w-px h-3 bg-n-slate-6" />
            <Button
              :label="t('CONTACTS_LAYOUT.CARD.VIEW_DETAILS')"
              variant="link"
              size="xs"
            />
          </div>
        </div>
      </div>
    </template>

    <template #footer>
      <Button
        icon="i-lucide-chevron-down"
        variant="ghost"
        color="slate"
        size="xs"
        :class="{ 'rotate-180': isExpanded }"
        @click="emit('toggle')"
      />
    </template>

    <template #expanded>
      <transition
        enter-active-class="overflow-hidden transition-all duration-300 ease-out"
        leave-active-class="overflow-hidden transition-all duration-300 ease-in"
        enter-from-class="overflow-hidden opacity-0 max-h-0"
        enter-to-class="opacity-100 max-h-[360px]"
        leave-from-class="opacity-100 max-h-[360px]"
        leave-to-class="overflow-hidden opacity-0 max-h-0"
      >
        <div
          v-show="isExpanded"
          class="w-full overflow-visible transition-all duration-200"
        >
          <div class="border-t border-n-strong">
            <ContactsForm
              :contact-data="{
                id,
                name,
                email,
                phoneNumber,
                additionalAttributes,
              }"
              @update="handleFormUpdate"
            />
          </div>
        </div>
      </transition>
    </template>
  </CardLayout>
</template>
