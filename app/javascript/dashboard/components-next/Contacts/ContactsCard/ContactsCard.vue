<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import ContactDeleteSection from 'dashboard/components-next/Contacts/ContactsCard/ContactDeleteSection.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import countries from 'shared/constants/countries';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  email: { type: String, default: '' },
  additionalAttributes: { type: Object, default: () => ({}) },
  phoneNumber: { type: String, default: '' },
  thumbnail: { type: String, default: '' },
  availabilityStatus: { type: String, default: null },
  isExpanded: { type: Boolean, default: false },
  isUpdating: { type: Boolean, default: false },
  selectable: { type: Boolean, default: false },
  isSelected: { type: Boolean, default: false },
});

const emit = defineEmits([
  'toggle',
  'updateContact',
  'showContact',
  'select',
  'avatarHover',
]);

const { t } = useI18n();

const contactsFormRef = ref(null);

const getInitialContactData = () => ({
  id: props.id,
  name: props.name,
  email: props.email,
  phoneNumber: props.phoneNumber,
  additionalAttributes: props.additionalAttributes,
});

const contactData = ref(getInitialContactData());

const isFormInvalid = computed(() => contactsFormRef.value?.isFormInvalid);

const countriesMap = computed(() => {
  return countries.reduce((acc, country) => {
    acc[country.code] = country;
    acc[country.id] = country;
    return acc;
  }, {});
});

const countryDetails = computed(() => {
  const attributes = props.additionalAttributes || {};
  const { country, countryCode, city } = attributes;

  if (!country && !countryCode) return null;

  const activeCountry =
    countriesMap.value[country] || countriesMap.value[countryCode];

  if (!activeCountry) return null;

  return {
    countryCode: activeCountry.id,
    city: city ? `${city},` : null,
    name: activeCountry.name,
  };
});

const formattedLocation = computed(() => {
  if (!countryDetails.value) return '';

  return [countryDetails.value.city, countryDetails.value.name]
    .filter(Boolean)
    .join(' ');
});

const handleFormUpdate = updatedData => {
  Object.assign(contactData.value, updatedData);
};

const handleUpdateContact = () => {
  emit('updateContact', contactData.value);
};

const onClickExpand = () => {
  emit('toggle');
  contactData.value = getInitialContactData();
};

const onClickViewDetails = () => emit('showContact', props.id);

const toggleSelect = checked => {
  emit('select', checked);
};

const handleAvatarHover = isHovered => {
  emit('avatarHover', isHovered);
};
</script>

<template>
  <div class="relative">
    <CardLayout
      :key="id"
      layout="row"
      class="!bg-surface-container hover:!bg-surface-container-high transition-colors duration-200"
      :class="{
        '!bg-surface-container-high outline outline-1 outline-secondary/30':
          isSelected,
      }"
    >
      <div class="flex items-center justify-start flex-1 gap-4">
        <div
          class="relative"
          @mouseenter="handleAvatarHover(true)"
          @mouseleave="handleAvatarHover(false)"
        >
          <Avatar
            :name="name"
            :src="thumbnail"
            :size="48"
            :status="availabilityStatus"
            hide-offline-status
            rounded-full
          >
            <template v-if="selectable" #overlay="{ size }">
              <label
                class="flex items-center justify-center rounded-full cursor-pointer absolute inset-0 z-10 backdrop-blur-[2px] border border-secondary/30"
                :style="{ width: `${size}px`, height: `${size}px` }"
                @click.stop
              >
                <Checkbox
                  :model-value="isSelected"
                  @change="event => toggleSelect(event.target.checked)"
                />
              </label>
            </template>
          </Avatar>
        </div>
        <div class="flex flex-col gap-0.5 flex-1">
          <div class="flex flex-wrap items-center gap-x-4 gap-y-1">
            <span class="text-base font-medium truncate text-on-surface">
              {{ name }}
            </span>
            <span class="inline-flex items-center gap-1">
              <span
                v-if="additionalAttributes?.companyName"
                class="i-ph-building-light mb-0.5 size-4 text-on-surface-variant/60"
              />
              <span
                v-if="additionalAttributes?.companyName"
                class="text-sm truncate text-on-surface-variant"
              >
                {{ additionalAttributes.companyName }}
              </span>
            </span>
          </div>
          <div
            class="flex flex-wrap items-center justify-start gap-x-3 gap-y-1"
          >
            <div v-if="email" class="truncate max-w-72" :title="email">
              <span class="text-sm text-on-surface-variant">
                {{ email }}
              </span>
            </div>
            <div v-if="email" class="w-px h-3 truncate bg-outline-variant/20" />
            <span
              v-if="phoneNumber"
              class="text-sm truncate text-on-surface-variant"
            >
              {{ phoneNumber }}
            </span>
            <div
              v-if="phoneNumber"
              class="w-px h-3 truncate bg-outline-variant/20"
            />
            <span
              v-if="countryDetails"
              class="inline-flex items-center gap-2 text-sm truncate text-on-surface-variant"
            >
              <Flag :country="countryDetails.countryCode" class="size-3.5" />
              {{ formattedLocation }}
            </span>
            <div
              v-if="countryDetails"
              class="w-px h-3 truncate bg-outline-variant/20"
            />
            <Button
              :label="t('CONTACTS_LAYOUT.CARD.VIEW_DETAILS')"
              link
              teal
              xs
              class="!no-underline hover:!no-underline"
              @click="onClickViewDetails"
            />
          </div>
        </div>
      </div>

      <Button
        icon="i-lucide-chevron-down"
        ghost
        slate
        xs
        class="shrink-0 rounded-md text-on-surface-variant hover:bg-surface-container-highest"
        :class="{ 'rotate-180': isExpanded }"
        @click="onClickExpand"
      />

      <template #after>
        <div
          class="transition-all duration-500 ease-in-out grid overflow-hidden"
          :class="
            isExpanded
              ? 'grid-rows-[1fr] opacity-100'
              : 'grid-rows-[0fr] opacity-0'
          "
        >
          <div class="overflow-hidden">
            <div
              class="flex flex-col gap-6 border-t border-outline-variant/10 bg-surface-container-lowest p-6"
            >
              <ContactsForm
                ref="contactsFormRef"
                :contact-data="contactData"
                @update="handleFormUpdate"
              />
              <div
                class="flex justify-end border-t border-outline-variant/15 pt-4"
              >
                <Button
                  :label="
                    t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.UPDATE_BUTTON')
                  "
                  solid
                  teal
                  md
                  trailing-icon
                  icon="i-lucide-save"
                  :is-loading="isUpdating"
                  :disabled="isUpdating || isFormInvalid"
                  class="font-semibold hover:shadow-[0_0_15px_rgba(4,190,153,0.35)]"
                  @click="handleUpdateContact"
                />
              </div>
            </div>
            <ContactDeleteSection
              :selected-contact="{
                id: props.id,
                name: props.name,
              }"
            />
          </div>
        </div>
      </template>
    </CardLayout>
  </div>
</template>
