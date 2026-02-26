<template>
  <div class="deal-card p-4 mb-3 bg-white rounded-lg shadow-sm border border-slate-100 cursor-move hover:border-slate-300 transition-all">
    <div class="flex flex-col gap-2">
      <h4 class="text-sm font-medium text-slate-800">{{ deal.name }}</h4>
      <div class="flex justify-between items-center">
        <span class="text-xs font-semibold text-green-600">${{ deal.value }}</span>
        <span class="text-xs text-slate-400">{{ contactName }}</span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    deal: { type: Object, required: true }
  },
  computed: {
    contactName() {
      return this.deal.contact ? this.deal.contact.name : 'Unknown Contact';
    }
  }
}
</script>
