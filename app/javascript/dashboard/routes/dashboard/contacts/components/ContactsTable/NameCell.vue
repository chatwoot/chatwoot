<script setup>
import BaseCell from 'dashboard/components/table/BaseCell.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { inject } from 'vue';

defineProps({
  row: {
    type: Object,
    required: true,
  },
});

const route = useRoute();
const openContactInfoPanel = inject('openContactInfoPanel');
const isRTL = useMapGetter('accounts/isRTL');
</script>

<template>
  <BaseCell>
    <woot-button
      variant="clear"
      class="!px-0"
      @click="() => openContactInfoPanel(row.original.id)"
    >
      <div class="items-center flex" :class="{ 'flex-row-reverse': isRTL }">
        <Thumbnail
          size="32px"
          :src="row.original.thumbnail"
          :username="row.original.name"
          :status="row.original.availability_status"
        />
        <div class="items-start flex flex-col my-0 mx-2">
          <h6 class="overflow-hidden text-base whitespace-nowrap text-ellipsis">
            <router-link
              :to="`/app/accounts/${route.params.accountId}/contacts/${row.original.id}`"
              class="text-sm font-medium m-0 capitalize"
            >
              {{ row.original.name }}
            </router-link>
          </h6>
          <button
            class="button clear small link text-slate-600 dark:text-slate-200"
          >
            {{ $t('CONTACTS_PAGE.LIST.VIEW_DETAILS') }}
          </button>
        </div>
      </div>
    </woot-button>
  </BaseCell>
</template>
