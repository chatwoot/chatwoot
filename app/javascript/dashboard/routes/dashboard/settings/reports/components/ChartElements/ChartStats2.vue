<script setup>
defineProps({
  title: {
    type: String,
  },
  desc: {
    type: String,
  },
  legend1: {
    type: String,
  },
  legend1Value: {
    type: String,
  },
  legend2: {
    type: String,
  },
  legend2Value: {
    type: String,
  },
});
</script>

<template>
  <div class="text-n-slate-11">
    <span class="text-sm">
      {{ title }}
    </span>
    <div class="flex items-center text-n-slate-12 mt-1">
      <div class="text-xl font-medium flex-1">
        {{ desc }}
      </div>
      <div class="flex flex-wrap justify-end gap-3 flex-end">
        <div class="text-sm flex flex-row gap-1 items-center">
          <div class="rounded-full h-2 w-2 circle2" />
          <span>{{ $t(legend1) }}</span>
          <span v-if="legend1Value" class="font-medium text-base">{{
            isFinite(legend1Value) ? legend1Value : 0
          }}</span>
        </div>
        <div class="text-sm flex flex-row gap-1 items-center">
          <div class="rounded-full h-2 w-2 circle1" />
          <span>{{ $t(legend2) }}</span>
          <span v-if="legend2Value" class="font-medium text-base">{{
            isFinite(legend2Value) ? legend2Value : 0
          }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.circle1 {
  background-color: rgb(31, 147, 255);
}

.circle2 {
  background-color: rgb(144, 196, 245);
}
</style>
