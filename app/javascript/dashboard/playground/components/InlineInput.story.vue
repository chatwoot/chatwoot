<script setup>
import InlineInput from './InlineInput.vue';
</script>

<template>
  <Story
    title="Components/InlineInput"
    :layout="{ type: 'grid', width: '400' }"
  >
    <Variant title="Default">
      <div class="p-4 bg-white dark:bg-slate-800">
        <InlineInput placeholder="Default InlineInput" />
      </div>
    </Variant>

    <Variant title="With Label">
      <div class="p-4 bg-white dark:bg-slate-800">
        <InlineInput label="Username" placeholder="Enter your username" />
      </div>
    </Variant>

    <Variant title="Disabled">
      <div class="p-4 bg-white dark:bg-slate-800">
        <InlineInput
          label="Disabled InlineInput"
          placeholder="Can't type here"
          disabled
        />
      </div>
    </Variant>

    <Variant title="With Custom Classes">
      <div class="flex flex-col gap-4 p-4 bg-white dark:bg-slate-800">
        <InlineInput
          label="Custom Input Class"
          placeholder="Custom input style"
          custom-input-class="placeholder:text-green-200 dark:placeholder:text-green-800"
        />
        <InlineInput
          label="Custom Label Class"
          placeholder="Custom label style"
          custom-label-class="text-green-600 dark:text-green-400"
        />
      </div>
    </Variant>

    <Variant title="Different Types">
      <div class="flex flex-col gap-4 p-4 bg-white dark:bg-slate-800">
        <InlineInput label="Text" placeholder="Text input" />
        <InlineInput label="Number" placeholder="Number input" type="number" />
        <InlineInput
          label="Password"
          placeholder="Password input"
          type="password"
        />
        <InlineInput label="Email" placeholder="Email input" type="email" />
      </div>
    </Variant>
  </Story>
</template>
