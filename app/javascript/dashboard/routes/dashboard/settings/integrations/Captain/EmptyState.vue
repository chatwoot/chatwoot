<script setup>
import CaptainInboxRow from './CaptainInboxRow.vue';

const dummyInboxes = [
  { name: 'Website Live Chat', type: 'Channel::WebWidget' },
  { name: 'Email', type: 'Channel::Email' },
  { name: 'Facebook Messenger', type: 'Channel::Facebook' },
];
</script>

<template>
  <div class="w-full min-h-[12rem] relative">
    <table class="min-w-full divide-y divide-slate-75 dark:divide-slate-700">
      <thead>
        <th
          v-for="thHeader in $t(
            'INTEGRATION_SETTINGS.CAPTAIN.LIST.TABLE_HEADER'
          )"
          :key="thHeader"
          class="py-4 pr-4 font-semibold text-left text-slate-700 dark:text-slate-300"
        >
          {{ thHeader }}
        </th>
      </thead>
      <tbody class="divide-y divide-slate-50 dark:divide-slate-800">
        <CaptainInboxRow
          v-for="inbox in dummyInboxes"
          :key="inbox.name"
          :inbox="inbox"
        />
      </tbody>
    </table>
    <div
      class="absolute inset-0 flex flex-col items-center justify-center w-full h-full bg-gradient-to-t from-white dark:from-slate-900 to-transparent"
    >
      <slot />
    </div>
  </div>
</template>
