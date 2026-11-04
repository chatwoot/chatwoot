<script setup>
const props = defineProps({
  product: { type: Object, required: true },
  selectable: { type: Boolean, default: false },
  checked: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
});

const emit = defineEmits(['toggle', 'view']);

const onRowClick = () => {
  if (props.selectable && !props.disabled) emit('toggle', props.product);
};
</script>

<template>
  <div
    class="flex items-center gap-3 p-1 rounded-lg outline outline-1 -outline-offset-1"
    :class="[
      checked ? 'outline-n-brand bg-n-alpha-2' : 'outline-n-container',
      selectable && disabled ? 'opacity-50 cursor-not-allowed' : '',
      selectable && !disabled ? 'cursor-pointer' : '',
    ]"
    data-testid="catalog-product-row"
    @click="onRowClick"
  >
    <input
      v-if="selectable"
      type="checkbox"
      class="mb-0 shrink-0"
      :checked="checked"
      :disabled="disabled"
      @click.stop="emit('toggle', product)"
    />
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
      @click.stop="emit('view', product)"
    >
      {{ $t('CATALOG.ACTIONS.SEE_MORE') }}
    </button>
  </div>
</template>
