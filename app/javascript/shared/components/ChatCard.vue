<script>
import CardButton from 'shared/components/CardButton.vue';

export default {
  components: {
    CardButton,
  },
  props: {
    items: {
      type: Array,
      default: null
    },
    title: {
      type: String,
      default: '',
    },
    description: {
      type: String,
      default: '',
    },
    mediaUrl: {
      type: String,
      default: '',
    },
    price: {
      type: String,
      default: '',
    },
    actions: {
      type: Array,
      default: () => [],
    },
  },
};
</script>

<template>
  <div
    class="card-message chat-bubble agent bg-n-background dark:bg-n-solid-3 max-w-56 rounded-lg overflow-hidden"
  >
    <div v-if="items && items.length > 0">
      <div v-for="(item, index) in items" :key="index" class="mb-4">
        <img
          class="w-full object-contain max-h-[150px] rounded-[5px]"
          :src="item.mediaUrl"
        />
        <div class="card-body">
          <h4
            class="!text-base !font-medium !mt-1 !mb-1 !leading-[1.5] text-n-slate-12"
          >
            {{ item.title }}
          </h4>
          <p class="!mb-1 text-n-slate-11">
            {{ item.description }}
          </p>
          <p v-if="item.price" class="!mb-3 font-bold text-xl text-center text-n-slate-12">
            {{ item.price }}
          </p>
          <CardButton v-for="action in item.actions" :key="action.id" :action="action" />
        </div>
      </div>
    </div>
    <div v-else>
      <img
        class="w-full object-contain max-h-[150px] rounded-[5px]"
        :src="mediaUrl"
      />
      <div class="card-body">
        <h4
          class="!text-base !font-medium !mt-1 !mb-1 !leading-[1.5] text-n-slate-12"
        >
          {{ title }}
        </h4>
        <p class="!mb-1 text-n-slate-11">
          {{ description }}
        </p>
        <p v-if="item && item.price" class="!mb-3 font-bold text-xl text-center text-n-slate-12">
          {{ item.price }}
        </p>
        <p v-else-if="price" class="!mb-3 font-bold text-xl text-center text-n-slate-12">
          {{ price }}
        </p>
        <CardButton v-for="action in actions" :key="action.id" :action="action" />
      </div>
    </div>
  </div>
</template>