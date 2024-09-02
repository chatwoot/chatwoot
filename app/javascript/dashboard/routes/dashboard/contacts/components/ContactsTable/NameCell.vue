<script setup>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { useRoute } from 'dashboard/composables/route';
import { inject } from 'vue';

defineProps({
  row: {
    type: Object,
    required: true,
  },
});

const route = useRoute();
const openContactInfoPanel = inject('openContactInfoPanel');
</script>

<template>
  <woot-button
    variant="clear"
    @click="() => openContactInfoPanel(row.original.id)"
  >
    <div class="row--user-block">
      <Thumbnail
        size="32px"
        :src="row.original.thumbnail"
        :username="row.original.name"
        :status="row.original.availability_status"
      />
      <div class="user-block">
        <h6 class="overflow-hidden text-base whitespace-nowrap text-ellipsis">
          <router-link
            :to="`/app/accounts/${route.params.accountId}/contacts/${row.original.id}`"
            class="user-name"
          >
            {{ row.original.name }}
          </router-link>
        </h6>
        <button class="button clear small link view-details--button">
          {{ $t('CONTACTS_PAGE.LIST.VIEW_DETAILS') }}
        </button>
      </div>
    </div>
  </woot-button>
</template>
