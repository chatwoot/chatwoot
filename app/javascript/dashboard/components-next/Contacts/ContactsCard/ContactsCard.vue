<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

import ContactCardForm from 'dashboard/components-next/Contacts/ContactsCard/ContactCardForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ContactLabels from 'dashboard/components-next/Conversation/ConversationCard/CardLabels.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import countries from 'shared/constants/countries';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  email: { type: String, default: '' },
  labels: { type: Array, default: () => [] },
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
  'sendMessage',
  'deleteContact',
]);

const { t } = useI18n();

const contactCardFormRef = ref(null);

const getInitialContactData = () => ({
  id: props.id,
  name: props.name,
  email: props.email,
  phoneNumber: props.phoneNumber,
  additionalAttributes: props.additionalAttributes,
});

const contactData = ref(getInitialContactData());

const isFormInvalid = computed(() => contactCardFormRef.value?.isFormInvalid);

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

const companyName = computed(() => {
  const attributes = props.additionalAttributes || {};
  return attributes.companyName || '';
});

const formattedLocation = computed(() => {
  if (!countryDetails.value) return '';

  return [countryDetails.value.city, countryDetails.value.name]
    .filter(Boolean)
    .join(' ');
});

const handleFormUpdate = updatedData => {
  Object.assign(contactData.value, updatedData);
  emit('updateContact', contactData.value);
};

const handleUpdateContact = () => {
  contactCardFormRef.value?.handleUpdate();
};

const onClickExpand = () => {
  emit('toggle');
  contactData.value = getInitialContactData();
};

const onClickViewDetails = () => emit('showContact', props.id);

const onClickOpenSendMessage = () => emit('sendMessage', props.id);

const onClickDeleteContact = () => {
  emit('deleteContact', props.id);
};

const toggleSelect = checked => {
  emit('select', checked);
};

const handleAvatarHover = isHovered => {
  emit('avatarHover', isHovered);
};
</script>

<template>
  <div class="relative">
    <div
      class="flex flex-col gap-2 pt-3 pb-2 lg:pb-3 lg:grid lg:gap-4 lg:items-center lg:rounded-lg lg:transition-all lg:duration-200 lg:grid-cols-[minmax(42%,1fr)_minmax(0,1fr)_minmax(0,1fr)] border-b border-n-weak lg:border-none"
    >
      <div
        class="flex items-center gap-3 lg:gap-2"
        :class="{ 'lg:col-span-3': isExpanded }"
      >
        <Button
          icon="i-lucide-chevron-down"
          link
          slate
          sm
          class="flex-shrink-0 hidden lg:flex !size-4 !rounded hover:enabled:!bg-n-alpha-2"
          :class="{ 'rotate-180': isExpanded }"
          @click="onClickExpand"
        />

        <div
          class="flex-shrink-0 flex items-center"
          @mouseenter="handleAvatarHover(true)"
          @mouseleave="handleAvatarHover(false)"
        >
          <Avatar
            :name="name"
            :src="thumbnail"
            :size="24"
            :status="availabilityStatus"
            hide-offline-status
          >
            <template v-if="selectable" #overlay="{ size }">
              <label
                class="flex items-center justify-center rounded-md cursor-pointer absolute inset-0 z-10 backdrop-blur-[2px]"
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

        <h4
          class="text-sm my-0 capitalize truncate text-n-slate-12 font-medium lg:max-w-40"
        >
          {{ name }}
        </h4>

        <div v-if="isExpanded" class="hidden lg:flex items-center gap-2">
          <div
            class="w-px h-3 bg-n-strong rounded-md ltr:ml-1 rtl:mr-1 flex-shrink-0"
          />
          <Button
            :label="t('CONTACTS_LAYOUT.CARD.ACTIONS.SEND_MESSAGE')"
            icon="i-lucide-message-circle"
            link
            sm
            class="hover:!no-underline"
            @click="onClickOpenSendMessage"
          />
          <div
            class="w-px h-3 bg-n-strong rounded-md ltr:ml-1 rtl:mr-1 flex-shrink-0"
          />
          <Button
            :label="t('CONTACTS_LAYOUT.CARD.ACTIONS.VIEW_DETAILS')"
            icon="i-lucide-info"
            link
            sm
            class="hover:!no-underline"
            @click="onClickViewDetails"
          />
          <div
            class="w-px h-3 bg-n-strong rounded-md ltr:ml-1 rtl:mr-1 flex-shrink-0"
          />
          <Button
            :label="t('CONTACTS_LAYOUT.CARD.ACTIONS.DELETE_CONTACT')"
            icon="i-lucide-trash-2"
            link
            sm
            ruby
            class="hover:!no-underline"
            @click="onClickDeleteContact"
          />
        </div>

        <div
          v-if="companyName"
          class="text-xs my-0 capitalize h-6 px-1 inline-flex items-center gap-1 rounded-md text-n-slate-12 font-440 max-w-40 min-w-0 outline outline-1 outline-n-weak"
          :class="{ 'lg:hidden': isExpanded }"
        >
          <Icon
            icon="i-lucide-briefcase-business"
            class="size-3.5 flex-shrink-0 text-n-slate-11"
          />
          <span class="truncate">{{ companyName }}</span>
        </div>

        <div
          v-if="countryDetails"
          class="w-px h-3 bg-n-strong rounded-lg flex-shrink-0"
          :class="{ 'lg:hidden': isExpanded }"
        />

        <span
          v-if="countryDetails"
          class="inline-flex items-center gap-2 text-sm min-w-0 text-n-slate-11"
          :class="{ 'lg:hidden': isExpanded }"
        >
          <Flag
            :country="countryDetails.countryCode"
            class="size-3.5 flex-shrink-0"
          />
          <span class="truncate">{{ formattedLocation }}</span>
        </span>

        <div class="ltr:ml-auto rtl:mr-auto">
          <Button
            icon="i-lucide-chevron-down"
            variant="ghost"
            color="slate"
            size="xs"
            class="flex-shrink-0 lg:!hidden !size-4 !rounded hover:enabled:!bg-n-alpha-2"
            :class="{ 'rotate-180': isExpanded }"
            @click="onClickExpand"
          />
        </div>
      </div>

      <div
        class="flex items-center gap-2 lg:gap-2 lg:min-w-0"
        :class="{ 'lg:hidden': isExpanded }"
      >
        <div
          v-if="email"
          class="flex items-center gap-1 truncate lg:max-w-72"
          :title="email"
        >
          <Icon
            icon="i-woot-mail"
            class="size-4 flex-shrink-0 text-n-slate-11"
          />
          <span class="text-sm text-n-slate-12 font-420 truncate">
            {{ email }}
          </span>
        </div>

        <div
          v-if="email && phoneNumber"
          class="w-px h-3 bg-n-strong rounded-lg flex-shrink-0"
        />

        <div
          v-if="phoneNumber"
          class="flex items-center gap-1 truncate lg:max-w-72"
          :title="phoneNumber"
        >
          <Icon
            icon="i-lucide-phone"
            class="size-3 flex-shrink-0 text-n-slate-11"
          />
          <span class="text-sm text-n-slate-12 font-420 truncate">
            {{ phoneNumber }}
          </span>
        </div>
      </div>

      <div class="flex flex-col gap-2 lg:hidden">
        <div v-if="labels.length > 0" class="min-h-[1rem]">
          <ContactLabels :labels="labels" disable-toggle class="my-0" />
        </div>

        <Button
          :label="t('CONTACTS_LAYOUT.CARD.VIEW_DETAILS')"
          link
          xs
          class="w-fit hover:!no-underline"
          slate
          @click="onClickViewDetails"
        />
      </div>

      <div
        class="hidden lg:flex items-center justify-end gap-3 flex-shrink-0"
        :class="{ 'lg:hidden': isExpanded }"
      >
        <ContactLabels
          :labels="labels"
          disable-toggle
          class="my-0 flex-1 justify-end"
        />
        <Button
          :label="t('CONTACTS_LAYOUT.CARD.VIEW_DETAILS')"
          link
          xs
          slate
          class="flex-shrink-0 hover:!no-underline"
          @click="onClickViewDetails"
        />
      </div>
    </div>

    <div
      class="transition-all duration-500 ease-in-out grid"
      :class="[
        isExpanded
          ? 'grid-rows-[1fr] opacity-100'
          : 'grid-rows-[0fr] opacity-0',
        isExpanded ? '' : 'overflow-hidden',
      ]"
    >
      <div class="min-h-0">
        <div class="relative flex flex-col lg:pt-3 pb-3 overflow-visible">
          <ContactCardForm
            ref="contactCardFormRef"
            :contact-data="contactData"
            class="lg:after:content-[''] lg:after:absolute lg:after:ltr:left-2 lg:after:rtl:right-2 lg:after:top-0 lg:after:w-px lg:after:bg-n-strong lg:after:bottom-11"
            @update="handleFormUpdate"
          />
          <div
            class="relative lg:ltr:pl-6 lg:rtl:pr-6 mt-6 mb-4 lg:before:block lg:before:content-[''] lg:before:absolute lg:ltr:before:left-2 lg:rtl:before:right-2 lg:before:top-1/2 lg:before:w-2 lg:before:h-px lg:before:bg-n-strong"
          >
            <Button
              :label="t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.UPDATE_BUTTON')"
              size="sm"
              :is-loading="isUpdating"
              :disabled="isUpdating || isFormInvalid"
              @click="handleUpdateContact"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
