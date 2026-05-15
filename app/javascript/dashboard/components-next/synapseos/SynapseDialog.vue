<script setup>
// CUSTOMIZAÇÃO_SYNAPSEOS
// Wrapper da Dialog do PrimeVue com os tokens Synapse aplicados via passthrough.
// Bg/borda/texto seguem `_synapseos_tokens.scss` e alternam light/dark com o app.
import Dialog from 'primevue/dialog';

defineOptions({ inheritAttrs: false });

const dialogPt = {
  mask: { class: 'bg-modal-backdrop-light dark:bg-modal-backdrop-dark' },
  root: {
    class:
      'bg-s-surface text-s-primary border border-s-border rounded-2xl shadow-s-lg overflow-hidden',
  },
  header: {
    class:
      'bg-s-surface text-s-primary border-b border-s-border px-6 pt-5 pb-4',
  },
  title: { class: 'text-base font-semibold text-s-primary' },
  closeButton: {
    class: 'text-s-secondary hover:text-s-primary hover:bg-s-subtle rounded-md',
  },
  content: { class: 'bg-s-surface text-s-primary px-6 py-5' },
  footer: {
    class: 'bg-s-surface text-s-primary border-t border-s-border px-6 py-4',
  },
};
</script>

<template>
  <Dialog v-bind="$attrs" :pt="dialogPt">
    <template v-for="(_, slotName) in $slots" #[slotName]="slotProps">
      <slot :name="slotName" v-bind="slotProps ?? {}" />
    </template>
  </Dialog>
</template>
