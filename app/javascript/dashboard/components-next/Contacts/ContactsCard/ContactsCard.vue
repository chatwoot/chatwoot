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
    <div class="flex items-center justify-between gap-4">
      <Avatar :name="name" :src="thumbnail" :size="48" rounded-full />
      <div class="flex flex-col gap-1">
        <div class="flex items-center gap-2">
          <span class="text-sm font-medium truncate text-n-slate-12">
            {{ name }}
          </span>
          <template v-if="additionalAttributes?.companyName">
            <span class="text-sm text-n-slate-11">
              {{ t('CONTACTS_LAYOUT.CARD.OF') }}
            </span>
            <span class="text-sm font-medium truncate text-n-slate-12">
              {{ additionalAttributes.companyName }}
            </span>
          </template>
        </div>
        <div class="flex items-center gap-3">
          <span v-if="email" class="text-sm text-n-slate-11">{{ email }}</span>
          <div v-if="email" class="w-px h-3 bg-n-slate-6" />
          <span v-if="phoneNumber" class="text-sm text-n-slate-11">
            {{ phoneNumber }}
          </span>
          <div v-if="phoneNumber" class="w-px h-3 bg-n-slate-6" />
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
