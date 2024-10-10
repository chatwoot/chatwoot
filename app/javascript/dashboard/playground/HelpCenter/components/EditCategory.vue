<script setup>
import { reactive } from 'vue';
import Input from 'dashboard/playground/components/Input.vue';
import TextArea from 'dashboard/playground/components/TextArea.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';

const emit = defineEmits(['close']);

const category = reactive({
  name: '',
  slug: '',
  description: '',
});

const closeEditCategory = () => {
  emit('close');
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <div
    class="w-[400px] absolute top-10 right-0 bg-white dark:bg-slate-800 p-6 rounded-xl border border-slate-50 dark:border-slate-800/50 shadow-md flex flex-col gap-6"
  >
    <h3 class="text-base font-medium text-slate-900 dark:text-slate-50">
      Edit category
    </h3>
    <div class="flex flex-col gap-4">
      <div
        class="flex items-center justify-start gap-8 px-4 py-2 border rounded-lg border-slate-50 dark:border-slate-700/50"
      >
        <div class="flex flex-col items-start w-full gap-2 py-2">
          <span class="text-sm font-medium text-slate-700 dark:text-slate-300">
            Portal
          </span>
          <span class="text-sm text-slate-800 dark:text-slate-100">
            User Guide
          </span>
        </div>
        <div class="justify-start w-px h-10 bg-slate-50 dark:bg-slate-700/50" />
        <div class="flex flex-col w-full gap-2 py-2">
          <span class="text-sm font-medium text-slate-700 dark:text-slate-300">
            Locale
          </span>
          <span class="text-sm text-slate-800 dark:text-slate-100">
            English (en-US)
          </span>
        </div>
      </div>
      <div class="flex flex-col gap-4">
        <div class="relative">
          <Input
            v-model="category.name"
            label="Category name"
            placeholder="Enter category name"
            custom-input-class="!h-10 ltr:pl-12 rtl:pr-12 border-transparent dark:border-transparent !bg-slate-25 dark:!bg-slate-900 focus:!border-transparent dark:focus:!border-transparent"
          >
            <template #prefix>
              <ButtonV4
                variant="secondary"
                size="icon"
                icon="emoji-add"
                class="!h-10 !w-10 absolute top-[26px] ltr:left-0 rtl:right-0 ltr:rounded-r-none rtl:rounded-l-none"
              />
            </template>
          </Input>
        </div>
        <Input
          v-model="category.slug"
          label="Slug"
          placeholder="Enter slug"
          message="app.chatwoot.com/hc/my-portal/en-US/categories/my-slug"
          message-type="info"
          custom-input-class="!h-10 border-transparent dark:border-transparent !bg-slate-25 dark:!bg-slate-900 focus:!border-transparent dark:focus:!border-transparent"
        />
        <TextArea
          v-model="category.description"
          label="Description"
          placeholder="Enter description"
          show-character-count
          custom-text-area-class="border-transparent dark:border-transparent !bg-slate-25 dark:!bg-slate-900 focus:!border-transparent dark:focus:!border-transparent"
        />
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-3">
      <ButtonV4
        variant="secondary"
        label="Cancel"
        text-variant="default"
        class="w-full"
        @click="closeEditCategory"
      />
      <ButtonV4 label="Upgrade" class="w-full" />
    </div>
  </div>
</template>
