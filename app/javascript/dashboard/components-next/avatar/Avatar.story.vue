<script setup>
import Avatar from './Avatar.vue';
</script>

<template>
  <Story title="Components/Avatar" :layout="{ type: 'grid', width: '400' }">
    <Variant title="Default">
      <div class="p-4 bg-white dark:bg-slate-900">
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Amaya"
          class="bg-ruby-300 dark:bg-ruby-900"
        />
      </div>
    </Variant>

    <Variant title="Default with upload">
      <div class="p-4 bg-white dark:bg-slate-900">
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Amaya"
          class="bg-ruby-300 dark:bg-ruby-900"
          allow-upload
        />
      </div>
    </Variant>

    <Variant title="Invalid or empty SRC">
      <div class="p-4 space-x-4 bg-white dark:bg-slate-900">
        <Avatar src="https://example.com/ruby.png" name="Ruby" allow-upload />
        <Avatar name="Bruce Wayne" allow-upload />
      </div>
    </Variant>

    <Variant title="Rounded Full">
      <div class="p-4 space-x-4 bg-white dark:bg-slate-900">
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Amaya"
          allow-upload
          rounded-full
        />
      </div>
    </Variant>

    <Variant title="Different Sizes">
      <div class="flex flex-wrap gap-4 p-4 bg-white dark:bg-slate-900">
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Felix"
          :size="48"
          class="bg-green-300 dark:bg-green-900"
          allow-upload
        />
        <Avatar
          :size="72"
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Jade"
          class="bg-indigo-300 dark:bg-indigo-900"
          allow-upload
        />
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Emery"
          :size="96"
          class="bg-woot-300 dark:bg-woot-900"
          allow-upload
        />
      </div>
    </Variant>
  </Story>
</template>
