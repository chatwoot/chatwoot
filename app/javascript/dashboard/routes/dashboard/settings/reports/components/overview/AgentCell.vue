<script setup>
import BaseCell from 'dashboard/components/table/BaseCell.vue';
import Avatar from 'next/avatar/Avatar.vue';
import { useMapGetter } from 'dashboard/composables/store';

defineProps({
  row: {
    type: Object,
    required: true,
  },
});

const isRTL = useMapGetter('accounts/isRTL');
</script>

<template>
  <BaseCell>
    <div
      class="items-center flex text-left"
      :class="{ 'flex-row-reverse': isRTL }"
    >
      <Avatar
        :src="row.original.thumbnail"
        :name="row.original.agent"
        :status="row.original.status"
        :size="32"
        hide-offline-status
        rounded-full
      />
      <div class="items-start flex flex-col min-w-0 my-0 mx-2">
        <h6
          class="overflow-hidden text-sm m-0 leading-[1.2] text-n-slate-12 whitespace-nowrap text-ellipsis"
        >
          {{ row.original.agent }}
        </h6>
        <span class="text-xs text-n-slate-11">
          {{ row.original.email }}
        </span>
      </div>
    </div>
  </BaseCell>
</template>
