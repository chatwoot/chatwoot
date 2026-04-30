<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { frontendURL } from 'dashboard/helper/URLHelper';
import Avatar from 'next/avatar/Avatar.vue';

const props = defineProps({
  item: {
    type: Object,
    required: true,
  },
});

const router = useRouter();
const accountId = useMapGetter('getCurrentAccountId');

const contactPath = computed(() =>
  frontendURL(`accounts/${accountId.value}/contacts/${props.item.id}`)
);

const onCardClick = () => {
  router.push({ path: contactPath.value });
};
</script>

<template>
  <div class="flex flex-col pb-2">
    <div
      class="min-h-20 relative flex flex-col items-start px-4 py-3 cursor-pointer border mt-3 shadow outline-1 outline group/cardLayout rounded-2xl bg-n-solid-2 transition-all hover:border-n-slate-6 border-n-weak outline-n-container"
      @click="onCardClick"
    >
      <div class="flex items-center w-full gap-3">
        <Avatar
          :name="item.name"
          :src="item.thumbnail"
          :size="32"
          rounded-full
        />
        <div class="flex flex-col flex-1 min-w-0">
          <h4 class="text-sm font-semibold text-n-slate-12 truncate">
            {{ item.name }}
          </h4>
          <p v-if="item.email" class="text-xs text-n-slate-10 truncate">
            {{ item.email }}
          </p>
          <p v-else-if="item.phone_number" class="text-xs text-n-slate-10 truncate">
            {{ item.phone_number }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
