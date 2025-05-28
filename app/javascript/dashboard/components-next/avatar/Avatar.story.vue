<script setup>
import Avatar from './Avatar.vue';
</script>

<template>
  <Story title="Components/Avatar" :layout="{ type: 'grid', width: '400' }">
    <Variant title="Default">
      <div class="flex p-4 space-x-4 bg-white dark:bg-slate-900">
        <Avatar
          name=""
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Amaya"
        />
        <Avatar name="Amaya" src="" />
        <Avatar name="" src="" />
      </div>
    </Variant>

    <Variant title="Different Shapes">
      <div class="gap-4 p-4 bg-white dark:bg-slate-900">
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Amaya"
          name=""
          allow-upload
          rounded-full
          :size="48"
        />
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Amaya"
          name=""
          allow-upload
          :size="48"
        />
      </div>
    </Variant>

    <Variant title="Different Sizes">
      <div class="flex flex-wrap gap-4 p-4 bg-white dark:bg-slate-900">
        <Avatar
          src="https://api.dicebear.com/9.x/avataaars/svg?seed=Felix"
          :size="48"
          name=""
          allow-upload
        />
        <Avatar
          :size="72"
          src="https://api.dicebear.com/9.x/avataaars/svg?seed=Jade"
          name=""
          allow-upload
        />
        <Avatar
          src="https://api.dicebear.com/9.x/avataaars/svg?seed=Emery"
          name=""
          :size="96"
          allow-upload
        />
      </div>
    </Variant>

    <Variant title="With Status">
      <div class="flex flex-wrap gap-4 p-4 bg-white dark:bg-slate-900">
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Felix"
          status="online"
          name="Felix Online"
        />
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Jade"
          status="busy"
          name="Jade Busy"
        />
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Emery"
          status="offline"
          name="Emery Offline"
        />
      </div>
    </Variant>

    <Variant title="With Custom Icon">
      <div class="flex flex-wrap gap-4 p-4 bg-white dark:bg-slate-900">
        <Avatar name="Custom Icon" icon-name="i-lucide-user" :size="48" />
        <Avatar
          name="Custom Industry"
          icon-name="i-lucide-building-2"
          :size="48"
        />
      </div>
    </Variant>

    <Variant title="Upload States">
      <div class="flex flex-wrap gap-4 p-4 bg-white dark:bg-slate-900">
        <!-- Empty state with upload -->
        <Avatar name="Upload New" allow-upload :size="48" />

        <!-- With image and upload -->
        <Avatar
          src="https://api.dicebear.com/9.x/thumbs/svg?seed=Upload"
          name="Replace Image"
          allow-upload
          :size="48"
        />
      </div>
    </Variant>

    <Variant title="Name Initials">
      <div class="flex flex-wrap gap-4 p-4 bg-white dark:bg-slate-900">
        <Avatar name="Catherine" :size="48" />
        <Avatar name="John Doe" :size="48" />
        <Avatar name="Rose Doe John" :size="48" />
      </div>
    </Variant>
  </Story>
</template>
