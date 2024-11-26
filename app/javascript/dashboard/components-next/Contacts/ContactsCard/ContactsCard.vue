<script setup>
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  email: { type: String, default: '' },
  additionalAttributes: { type: Object, default: () => ({}) },
  phoneNumber: { type: String, default: '' },
  thumbnail: { type: String, default: '' },
  isExpanded: { type: Boolean, default: false },
});

const emit = defineEmits(['toggle', 'updateContact', 'showContact']);

const { t } = useI18n();

const handleFormUpdate = updatedData => {
  emit('updateContact', { id: props.id, updatedData });
};

const onClickViewDetails = async () => {
  emit('showContact', props.id);
};
</script>

<template>
  <CardLayout :key="id" layout="row">
    <div class="flex items-center justify-start gap-4 flex-1">
      <Avatar :name="name" :src="thumbnail" :size="48" rounded-full />
      <div class="flex flex-col gap-0.5 flex-1">
        <div class="flex items-center gap-4">
          <span class="text-base font-medium truncate text-n-slate-12">
            {{ name }}
          </span>
          <span class="inline-flex gap-1 items-center">
            <span
              v-if="additionalAttributes?.companyName"
              class="i-ph-building-light size-4 text-n-slate-10 mb-0.5"
            />
            <span
              v-if="additionalAttributes?.companyName"
              class="text-sm truncate text-n-slate-11"
            >
              {{ additionalAttributes.companyName }}
            </span>
          </span>
        </div>
        <div class="flex items-center gap-3 justify-start">
          <div class="flex items-center gap-3">
            <div v-if="email" class="max-w-72 truncate" :title="email">
              <span class="text-sm text-n-slate-11">
                {{ email }}
              </span>
            </div>
            <div v-if="email" class="w-px h-3 bg-n-slate-6 truncate" />
            <span v-if="phoneNumber" class="text-sm text-n-slate-11 truncate">
              {{ phoneNumber }}
            </span>
            <div v-if="phoneNumber" class="w-px h-3 bg-n-slate-6 truncate" />
          </div>
          <Button
            :label="t('CONTACTS_LAYOUT.CARD.VIEW_DETAILS')"
            variant="link"
            size="xs"
            @click="onClickViewDetails"
          />
        </div>
      </div>
    </div>

    <Button
      icon="i-lucide-chevron-down"
      variant="ghost"
      color="slate"
      size="xs"
      :class="{ 'rotate-180': isExpanded }"
      @click="emit('toggle')"
    />

    <template #after>
      <transition
        enter-active-class="overflow-hidden transition-all duration-300 ease-out"
        leave-active-class="overflow-hidden transition-all duration-300 ease-in"
        enter-from-class="overflow-hidden opacity-0 max-h-0"
        enter-to-class="opacity-100 max-h-[360px]"
        leave-from-class="opacity-100 max-h-[360px]"
        leave-to-class="overflow-hidden opacity-0 max-h-0"
      >
        <div v-show="isExpanded" class="w-full">
          <div class="p-6 border-t border-n-strong">
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
