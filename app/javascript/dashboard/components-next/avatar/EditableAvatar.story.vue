<script setup>
import EditableAvatar from './EditableAvatar.vue';
</script>

<template>
  <Story title="Components/Avatar" :layout="{ type: 'grid', width: '400' }">
    <Variant title="Default">
      <div class="p-4 bg-white dark:bg-slate-900">
        <EditableAvatar
          src="https://api.dicebear.com/9.x/avataaars/svg?seed=Amaya"
          class="bg-ruby-300 dark:bg-ruby-900"
        />
      </div>
    </Variant>

    <Variant title="Different Sizes">
      <div class="flex flex-wrap gap-4 p-4 bg-white dark:bg-slate-900">
        <EditableAvatar
          src="https://api.dicebear.com/9.x/avataaars/svg?seed=Felix"
          :size="48"
          class="bg-green-300 dark:bg-green-900"
        />
        <EditableAvatar
          :size="72"
          src="https://api.dicebear.com/9.x/avataaars/svg?seed=Jade"
          class="bg-indigo-300 dark:bg-indigo-900"
        />
        <EditableAvatar
          src="https://api.dicebear.com/9.x/avataaars/svg?seed=Emery"
          :size="96"
          class="bg-woot-300 dark:bg-woot-900"
        />
      </div>
    </Variant>
  </Story>
</template>
