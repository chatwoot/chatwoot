<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn } from '@vueuse/core';

import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import ContactAPI from 'dashboard/api/contacts';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

const props = defineProps({
  label: {
    type: Object,
    required: true,
  },
});

const CONTACTS_PER_PAGE = 15;
const PREVIEW_COUNT = 6;

const { t } = useI18n();

const popoverRef = ref(null);
const dialogRef = ref(null);
const contacts = ref([]);
const totalCount = ref(0);
const currentPage = ref(1);
const searchQuery = ref('');

const { run: runContactsRequest, isPending: isFetching } =
  useAbortableRequest();

const previewContacts = computed(() => contacts.value.slice(0, PREVIEW_COUNT));

const fetchContacts = async () => {
  try {
    const response = await runContactsRequest(signal =>
      searchQuery.value
        ? ContactAPI.search(
            searchQuery.value,
            currentPage.value,
            'name',
            props.label.title,
            { signal }
          )
        : ContactAPI.get(currentPage.value, 'name', props.label.title, {
            signal,
          })
    );
    if (!response) return;
    contacts.value = response.data.payload;
    totalCount.value = response.data.meta.count;
  } catch {
    contacts.value = [];
    totalCount.value = 0;
  }
};

const handleOpen = () => {
  searchQuery.value = '';
  currentPage.value = 1;
  fetchContacts();
};

const handleExpand = () => {
  popoverRef.value.hide();
  dialogRef.value.open();
};

const handlePageChange = page => {
  currentPage.value = page;
  fetchContacts();
};

const handleSearch = useDebounceFn(() => {
  currentPage.value = 1;
  fetchContacts();
}, 300);
</script>

<template>
  <Popover ref="popoverRef" @show="handleOpen">
    <Button
      variant="link"
      color="slate"
      size="sm"
      :label="t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.VIEW')"
    />
    <template #content>
      <div class="flex flex-col gap-1 p-4 w-[26rem]">
        <div class="flex items-center justify-between gap-3 mb-2">
          <div class="flex items-center min-w-0 gap-2">
            <Icon icon="i-lucide-users" class="size-4 text-n-slate-11" />
            <span class="text-heading-2 text-n-slate-12">
              {{ t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.CONTACTS.TITLE') }}
            </span>
            <span class="text-body-main text-n-slate-11">
              {{ t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.CONTACTS.TAGGED_WITH') }}
            </span>
            <span
              class="inline-flex items-center h-7 gap-2 px-2 rounded-md shrink-0 outline outline-1 -outline-offset-1 outline-n-strong"
            >
              <span
                class="rounded-sm size-2"
                :style="{ backgroundColor: label.color }"
              />
              <span class="text-body-main text-n-slate-12">
                {{ label.title }}
              </span>
            </span>
          </div>
          <Button
            variant="ghost"
            color="blue"
            size="sm"
            icon="i-lucide-maximize-2"
            @click="handleExpand"
          />
        </div>
        <Spinner v-if="isFetching" class="self-center my-6" />
        <template v-else>
          <div
            v-for="contact in previewContacts"
            :key="contact.id"
            class="flex items-center justify-between h-10 gap-3"
          >
            <div class="flex items-center min-w-0 gap-2">
              <Avatar
                :name="contact.name"
                :src="contact.thumbnail"
                :size="24"
                rounded-full
              />
              <span class="min-w-0 truncate text-body-main text-n-slate-12">
                {{ contact.name }}
              </span>
            </div>
            <span class="truncate shrink-0 text-body-main text-n-slate-11">
              {{ contact.phone_number || contact.email }}
            </span>
          </div>
          <p
            v-if="!contacts.length"
            class="py-6 mb-0 text-center text-body-main text-n-slate-11"
          >
            {{ t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.CONTACTS.EMPTY_STATE') }}
          </p>
        </template>
      </div>
    </template>
  </Popover>

  <Dialog
    ref="dialogRef"
    width="5xl"
    :show-cancel-button="false"
    :show-confirm-button="false"
  >
    <div class="flex flex-col gap-4">
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center min-w-0 gap-2">
          <Icon icon="i-lucide-users" class="size-4 text-n-slate-11" />
          <span class="text-heading-2 text-n-slate-12">
            {{ t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.CONTACTS.TITLE') }}
          </span>
          <span class="text-body-main text-n-slate-11">
            {{ t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.CONTACTS.TAGGED_WITH') }}
          </span>
          <span
            class="inline-flex items-center h-7 gap-2 px-2 rounded-md shrink-0 outline outline-1 -outline-offset-1 outline-n-strong"
          >
            <span
              class="rounded-sm size-2"
              :style="{ backgroundColor: label.color }"
            />
            <span class="text-body-main text-n-slate-12">
              {{ label.title }}
            </span>
          </span>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <Input
            v-model="searchQuery"
            custom-input-class="!ps-9"
            class="w-80"
            :placeholder="
              t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.CONTACTS.SEARCH_PLACEHOLDER')
            "
            @input="handleSearch"
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute z-10 -translate-y-1/2 pointer-events-none start-3 top-1/2 size-4 text-n-slate-11"
              />
            </template>
          </Input>
          <Button
            variant="ghost"
            color="slate"
            size="sm"
            icon="i-lucide-minimize-2"
            @click="dialogRef.close()"
          />
        </div>
      </div>

      <div
        class="flex flex-col h-[41.25rem] max-h-[60vh] overflow-y-auto pe-3 [scrollbar-gutter:stable]"
      >
        <Spinner v-if="isFetching" class="m-auto" />
        <template v-else>
          <div
            v-for="contact in contacts"
            :key="contact.id"
            class="flex items-center justify-between h-12 gap-3 shrink-0"
          >
            <div class="flex items-center min-w-0 gap-3">
              <Avatar
                :name="contact.name"
                :src="contact.thumbnail"
                :size="24"
                rounded-full
              />
              <span class="min-w-0 truncate text-body-main text-n-slate-12">
                {{ contact.name }}
              </span>
            </div>
            <span class="truncate shrink-0 text-body-main text-n-slate-11">
              {{ contact.phone_number || contact.email }}
            </span>
          </div>
          <p
            v-if="!contacts.length"
            class="py-8 mb-0 text-center text-body-main text-n-slate-11"
          >
            {{ t('CAMPAIGN.WHATSAPP.FORM.AUDIENCE.CONTACTS.EMPTY_STATE') }}
          </p>
        </template>
      </div>

      <div v-if="totalCount > CONTACTS_PER_PAGE" class="-mx-6 -mb-6">
        <PaginationFooter
          :current-page="currentPage"
          :total-items="totalCount"
          :items-per-page="CONTACTS_PER_PAGE"
          class="rounded-b-xl !bg-transparent !border-n-strong before:hidden"
          @update:current-page="handlePageChange"
        />
      </div>
    </div>
  </Dialog>
</template>
