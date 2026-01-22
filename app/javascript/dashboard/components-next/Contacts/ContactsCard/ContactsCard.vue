<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';

import ContactCardForm from 'dashboard/components-next/Contacts/ContactsCard/ContactCardForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ContactLabels from 'dashboard/components-next/Conversation/ConversationCard/CardLabels.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Policy from 'dashboard/components/policy.vue';
import ContactAttributeDisplay from './ContactAttributeDisplay.vue';
import countries from 'shared/constants/countries';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  email: { type: String, default: '' },
  labels: { type: Array, default: () => [] },
  additionalAttributes: { type: Object, default: () => ({}) },
  customAttributes: { type: Object, default: () => ({}) },
  phoneNumber: { type: String, default: '' },
  thumbnail: { type: String, default: '' },
  availabilityStatus: { type: String, default: null },
  isExpanded: { type: Boolean, default: false },
  isSelected: { type: Boolean, default: false },
});

const emit = defineEmits([
  'toggle',
  'showContact',
  'select',
  'sendMessage',
  'deleteContact',
]);

const { t } = useI18n();
const store = useStore();

const isPrefetching = ref(false);
const hasPrefetched = ref(false);

const getInitialContactData = () => ({
  id: props.id,
  name: props.name,
  email: props.email,
  phoneNumber: props.phoneNumber,
  additionalAttributes: props.additionalAttributes,
  labels: props.labels,
});

const contactData = ref(getInitialContactData());

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

const prefetchContactData = async () => {
  if (hasPrefetched.value || isPrefetching.value || !props.id) return;

  isPrefetching.value = true;
  try {
    await Promise.all([
      store.dispatch('contactNotes/get', { contactId: props.id }),
      store.dispatch('contactConversations/get', props.id),
    ]);
    hasPrefetched.value = true;
  } catch (error) {
    // error
  } finally {
    isPrefetching.value = false;
  }
};

const handleExpandHover = isHovered => {
  if (isHovered && !props.isExpanded) {
    prefetchContactData();
  }
};
</script>

<template>
  <div class="relative">
    <div
      class="flex flex-col gap-2 p-2 lg:grid lg:gap-4 lg:items-center lg:rounded-lg lg:transition-all lg:duration-200 lg:grid-cols-[minmax(30%,1fr)_minmax(50%,1.5fr)_1fr]"
      :class="{ 'border-b border-n-weak lg:border-none': isExpanded }"
    >
      <div
        class="flex items-center gap-3 lg:gap-2"
        :class="{ 'lg:col-span-3': isExpanded }"
      >
        <div class="flex-shrink-0 size-5 flex items-center justify-center">
          <Checkbox
            :model-value="isSelected"
            @change="event => toggleSelect(event.target.checked)"
          />
        </div>

        <div
          class="relative hidden lg:block size-4 rounded-md hover:bg-n-alpha-2 flex-shrink-0"
          @mouseenter.passive="handleExpandHover(true)"
          @mouseleave.passive="handleExpandHover(false)"
        >
          <Button
            icon="i-lucide-chevron-down"
            link
            slate
            sm
            no-animation
            class="flex-shrink-0 !size-8 absolute -inset-2"
            :class="{ 'rotate-180': isExpanded }"
            @click="onClickExpand"
          />
        </div>

        <div class="flex-shrink-0 flex items-center">
          <Avatar
            :name="name"
            :src="thumbnail"
            :size="24"
            :status="availabilityStatus"
            hide-offline-status
          />
        </div>

        <h4
          class="text-heading-3 my-0 capitalize hover:cursor-pointer truncate text-n-slate-12 lg:max-w-40"
          @click="onClickViewDetails"
        >
          {{ name }}
        </h4>

        <div
          v-if="isExpanded"
          class="hidden lg:flex items-center gap-2 flex-shrink-0"
        >
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
          <Policy
            :permissions="['administrator']"
            class="flex items-center gap-2"
          >
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
          </Policy>
        </div>

        <div
          v-if="companyName"
          class="my-0 capitalize h-6 px-1 inline-flex items-center gap-1 rounded-md text-n-slate-12 max-w-40 min-w-0 bg-n-label-color outline outline-1 outline-n-label-border -outline-offset-1"
          :class="{ 'lg:hidden': isExpanded }"
        >
          <Icon
            icon="i-lucide-briefcase-business"
            class="size-3.5 flex-shrink-0 text-n-slate-11"
          />
          <span class="truncate text-label-small">{{ companyName }}</span>
        </div>

        <div
          class="relative lg:hidden size-5 rounded-md hover:bg-n-alpha-2 ltr:ml-auto rtl:mr-auto flex-shrink-0"
          @mouseenter.passive="handleExpandHover(true)"
          @mouseleave.passive="handleExpandHover(false)"
        >
          <Button
            icon="i-lucide-chevron-down"
            link
            slate
            sm
            no-animation
            class="flex-shrink-0 !size-8 absolute -inset-1.5"
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
          v-tooltip.top="{
            content: email,
            delay: { show: 500, hide: 0 },
          }"
          class="flex items-center gap-1 truncate lg:max-w-72"
        >
          <Icon
            icon="i-woot-mail"
            class="size-4 flex-shrink-0 text-n-slate-11"
          />
          <span class="text-body-main text-n-slate-12 truncate">
            {{ email }}
          </span>
        </div>

        <div
          v-if="email && phoneNumber"
          class="w-px h-3 bg-n-strong rounded-lg flex-shrink-0"
        />

        <div
          v-if="phoneNumber"
          v-tooltip.top="{
            content: phoneNumber,
            delay: { show: 500, hide: 0 },
          }"
          class="flex items-center gap-1 truncate lg:max-w-72"
        >
          <Icon
            icon="i-lucide-phone"
            class="size-3 flex-shrink-0 text-n-slate-11"
          />
          <span class="text-body-main text-n-slate-12 truncate">
            {{ phoneNumber }}
          </span>
        </div>

        <div
          v-if="countryDetails"
          class="w-px h-3 bg-n-strong rounded-lg flex-shrink-0"
        />

        <div
          v-if="countryDetails"
          v-tooltip.top="{
            content: formattedLocation,
            delay: { show: 500, hide: 0 },
          }"
          class="flex items-center gap-2 min-w-0 text-n-slate-11"
        >
          <Flag
            :country="countryDetails.countryCode"
            class="size-3.5 flex-shrink-0"
          />
          <span class="text-body-main text-n-slate-12 truncate">
            {{ formattedLocation }}
          </span>
        </div>
        <ContactAttributeDisplay :custom-attributes="customAttributes" />
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
      </div>
    </div>

    <div
      class="grid [transition:grid-template-rows_300ms_ease-out]"
      :class="[
        isExpanded ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]',
        isExpanded ? '' : 'overflow-hidden',
      ]"
    >
      <div class="min-h-0">
        <div
          class="relative flex flex-col pt-3 pb-4 lg:pt-[1.125rem] lg:pb-5 overflow-visible transition-opacity duration-[600ms] ease-out"
          :class="isExpanded ? 'opacity-100 delay-200' : 'opacity-0'"
        >
          <ContactCardForm :contact-data="contactData" />
        </div>
      </div>
    </div>
  </div>
</template>
