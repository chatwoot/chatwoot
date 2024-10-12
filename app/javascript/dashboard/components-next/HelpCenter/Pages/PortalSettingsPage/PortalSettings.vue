<script setup>
import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const handleUploadAvatar = () => {};
</script>

<!-- TODO: Add i18n -->
<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #content>
      <div class="flex flex-col w-full gap-10 max-w-[640px] pt-2 pb-8">
        <div class="flex flex-col w-full gap-4">
          <div class="flex flex-col w-full gap-2">
            <label
              class="mb-0.5 text-sm font-medium text-gray-900 dark:text-gray-50"
            >
              Avatar
            </label>
            <Avatar
              label="Avatar"
              src="https://api.dicebear.com/9.x/avataaars/svg?seed=Amaya"
              class="bg-ruby-300 dark:bg-ruby-400"
              @upload="handleUploadAvatar"
            />
          </div>
          <div class="flex flex-col w-full gap-2">
            <div class="flex justify-between w-full h-10 gap-2 py-1">
              <label
                class="text-sm font-medium whitespace-nowrap min-w-[100px] text-slate-900 dark:text-slate-50"
              >
                Name
              </label>
              <Input placeholder="Name" class="w-[432px]" />
            </div>
            <div class="flex justify-between w-full h-10 gap-2 py-1">
              <label
                class="text-sm font-medium whitespace-nowrap min-w-[100px] text-slate-900 dark:text-slate-50"
              >
                Header text
              </label>
              <Input placeholder="Header text" class="w-[432px]" />
            </div>
            <div class="flex justify-between w-full h-10 gap-2 py-1">
              <label
                class="text-sm font-medium whitespace-nowrap min-w-[100px] text-slate-900 dark:text-slate-50"
              >
                Page title
              </label>
              <Input placeholder="Page title" class="w-[432px]" />
            </div>
            <div class="flex justify-between w-full h-10 gap-2 py-1">
              <label
                class="text-sm font-medium whitespace-nowrap min-w-[100px] text-slate-900 dark:text-slate-50"
              >
                Widget color
              </label>
            </div>
            <div class="flex justify-end w-full gap-2 py-2">
              <Button label="Save changes" size="sm" />
            </div>
          </div>
          <div class="w-full h-px bg-slate-50 dark:bg-slate-800/50" />
        </div>
        <div class="flex flex-col w-full gap-6">
          <div class="flex flex-col w-full gap-6">
            <h6 class="text-base font-medium text-slate-900 dark:text-slate-50">
              Configuration
            </h6>
            <div class="flex flex-col w-full gap-4">
              <div class="flex justify-between w-full gap-2 py-1">
                <InlineInput
                  placeholder="Slug"
                  label="Slug:"
                  custom-label-class="min-w-[100px]"
                  custom-input-class="!w-[430px]"
                />
              </div>
              <div class="flex justify-between w-full gap-2 py-1">
                <InlineInput
                  placeholder="Custom domain"
                  label="Custom domain:"
                  custom-label-class="min-w-[100px]"
                  custom-input-class="!w-[430px]"
                />
              </div>
              <div class="flex justify-between w-full gap-2 py-1">
                <InlineInput
                  placeholder="Home page link"
                  label="Home page link:"
                  custom-label-class="min-w-[100px]"
                  custom-input-class="!w-[430px]"
                />
              </div>
            </div>
          </div>
          <div class="flex justify-end w-full gap-3 py-4">
            <Button label="Edit configuration" size="sm" variant="secondary" />
            <Button
              label="Delete Test-Help Center"
              size="sm"
              variant="destructive"
            />
          </div>
        </div>
      </div>
    </template>
  </HelpCenterLayout>
</template>
