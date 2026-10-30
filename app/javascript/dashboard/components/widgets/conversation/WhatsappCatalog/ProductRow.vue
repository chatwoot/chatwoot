<script setup>
defineProps({
  product: { type: Object, required: true },
});

const emit = defineEmits(['view']);
</script>

<template>
  <div
    class="flex items-center gap-3 p-1 rounded-lg outline outline-1 -outline-offset-1 outline-n-container"
    data-testid="catalog-product-row"
  >
    <img
      v-if="product.image_urls?.length"
      :src="product.image_urls[0]"
      :alt="product.name"
      loading="lazy"
      decoding="async"
      class="object-cover rounded-md size-16 shrink-0"
    />
    <div v-else class="rounded-md size-16 shrink-0 bg-n-alpha-2" />
    <div class="flex flex-col flex-1 min-w-0">
      <span class="text-sm font-medium truncate text-n-slate-12">
        {{ product.name }}
      </span>
      <span v-if="product.price" class="text-xs text-n-slate-11">
        {{ product.price }}
      </span>
    </div>
    <button
      type="button"
      class="px-2 py-1 text-sm rounded-lg shrink-0 text-n-brand hover:bg-n-alpha-2"
      data-testid="catalog-see-more"
      @click="emit('view', product)"
    >
      {{ $t('CATALOG.ACTIONS.SEE_MORE') }}
    </button>
  </div>
</template>
