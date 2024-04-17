<template>
  <div>
    <!-- Draw a line -->
    <div class="flex flex-row items-center justify-between gap-4">
      <div class="flex-grow h-0.5 bg-slate-50 dark:bg-slate-700" />
    </div>
    <div class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl">
      <table-header-cell :span="6" label="Notification type" />
      <table-header-cell :span="3" label="Email" />
      <table-header-cell :span="3" label="Push notification" />
    </div>
    <div class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl">
      <div
        class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        <span class="text-slate-700 dark:text-slate-200">
          A new conversation is created
        </span>
      </div>
      <div
        class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
      >
        <input
          type="checkbox"
          name="email"
          :checked="true"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
      </div>
      <div
        class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
      >
        <input
          type="checkbox"
          name="email"
          :checked="false"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
      </div>
    </div>
    <div class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl">
      <div
        class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        <span class="text-slate-700 dark:text-slate-200">
          Conversation is assigned to you
        </span>
      </div>
      <div
        class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
      >
        <input
          type="checkbox"
          name="email"
          :checked="true"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
      </div>
      <div
        class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
      >
        <input
          type="checkbox"
          name="email"
          :checked="false"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
      </div>
    </div>
    <div class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl">
      <div
        class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        <span class="text-slate-700 dark:text-slate-200">
          Conversation is assigned to you
        </span>
      </div>
      <div
        class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
      >
        <input
          type="checkbox"
          name="email"
          :checked="true"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
      </div>
      <div
        class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
      >
        <input
          type="checkbox"
          name="email"
          :checked="false"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
      </div>
    </div>
    <div class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl">
      <div
        class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        <span class="text-slate-700 dark:text-slate-200">
          You are mentioned in a conversation
        </span>
      </div>
      <div
        class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
      >
        <input
          type="checkbox"
          name="email"
          :checked="true"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
      </div>
      <div
        class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
      >
        <input
          type="checkbox"
          name="email"
          :checked="false"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
      </div>
    </div>
    <div class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl">
      <div
        class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        <span class="text-slate-700 dark:text-slate-200">
          New message is created in an assigned conversation
        </span>
      </div>
      <div
        class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
      >
        <input
          type="checkbox"
          name="email"
          :checked="true"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
      </div>
      <div
        class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
      >
        <input
          type="checkbox"
          name="email"
          :checked="false"
          class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
        />
      </div>
    </div>
  </div>
</template>
<script setup>
import TableHeaderCell from 'dashboard/components/widgets/TableHeaderCell.vue';
</script>
