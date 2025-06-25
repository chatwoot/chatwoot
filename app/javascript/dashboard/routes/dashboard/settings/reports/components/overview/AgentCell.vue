<script setup>
import BaseCell from 'dashboard/components/table/BaseCell.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
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
      <Thumbnail
        :src="row.original.thumbnail"
        size="32px"
        :username="row.original.agent"
        :status="row.original.status"
      />
      <div class="items-start flex flex-col min-w-0 my-0 mx-2">
        <h6
          class="overflow-hidden text-sm m-0 leading-[1.2] text-slate-800 dark:text-slate-100 whitespace-nowrap text-ellipsis"
        >
          {{ row.original.agent }}
        </h6>
        <span class="text-xs text-slate-600 dark:text-slate-200">
          {{ row.original.email }}
        </span>
      </div>
    </div>
  </BaseCell>
</template>
