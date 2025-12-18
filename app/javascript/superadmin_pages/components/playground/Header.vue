<script setup>
defineProps({
  responseSourcePath: {
    type: String,
    required: true,
  },
  responseSourceName: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <header
    class="sticky top-0 z-10 bg-n-background border-b border-n-weak"
    role="banner"
  >
    <div class="flex items-center h-16 mx-auto max-w-[60rem]">
      <a :href="responseSourcePath" class="text-woot-500 hover:underline mr-4">
        Back
      </a>
      <div
        class="border border-solid border-n-weak text-n-slate-11 mr-4 p-2 rounded-full"
      >
        <svg width="24" height="24"><use xlink:href="#icon-mist-fill" /></svg>
      </div>
      <div class="flex flex-col justify-center">
        <h1 id="page-title" class="text-lg font-medium text-n-slate-12">
          Robin AI playground
        </h1>
        <p class="text-sm text-n-slate-11">
          Chat with the source
          <span class="font-medium text-n-slate-12">
            {{ responseSourceName }}
          </span>
          and evaluate it's efficiency.
        </p>
      </div>
    </div>
  </header>
</template>
