<template>
  <div>
    <form-select
      name="timezone"
      spacing="compact"
      label="Alert tone"
      placeholder="Ding"
      class="max-w-xl"
    >
      <option v-for="file in audioFiles" :key="file.label" :value="file.value">
        {{ file.label }}
      </option>
    </form-select>

    <div>
      <label
        class="flex justify-between pb-1 text-sm font-medium leading-6 text-slate-900 dark:text-white"
      >
        Alert events for conversations
      </label>
      <div
        class="flex flex-row justify-between h-10 max-w-xl p-2 border border-solid rounded-md border-slate-75 dark:border-slate-600"
      >
        <div
          class="flex flex-row items-center justify-center gap-1 border-r border-slate-75 grow"
        >
          <input type="radio" name="hotkey" value="enter" checked />
          <label>None</label>
        </div>
        <div
          class="flex flex-row items-center justify-center gap-1 border-r border-slate-75 grow"
        >
          <input type="radio" name="hotkey" value="enter" />
          <label>Assigned</label>
        </div>
        <div class="flex flex-row items-center justify-center gap-1 grow">
          <input type="radio" name="hotkey" value="enter" />
          <label>All</label>
        </div>
      </div>
    </div>
    <div>
      <label
        class="flex justify-between pb-1 text-sm font-medium leading-6 text-slate-900 dark:text-white"
      >
        Alert conditions
      </label>
      <div class="flex flex-row items-center justify-start gap-2">
        <input
          type="checkbox"
          name="send"
          :checked="true"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
        <label>
          Send audio alerts only if the browser window is not active
        </label>
      </div>
      <div class="flex flex-row items-center justify-start gap-2">
        <input
          type="checkbox"
          name="send"
          :checked="false"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
        <label>
          Send alerts every 30s until all the assigned conversations are read
        </label>
      </div>
    </div>
  </div>
</template>
<script setup>
import FormSelect from 'v3/components/Form/Select.vue';
const audioFiles = [
  { label: 'Ding', value: 'ding' },
  { label: 'Dong', value: 'dong' },
];
</script>
