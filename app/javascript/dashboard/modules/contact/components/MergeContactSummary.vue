<template>
  <div
    v-if="parentContactName"
    class="my-4 relative p-2.5 border rounded-[4px] text-slate-800 dark:text-slate-100 border-slate-100 dark:border-slate-700 bg-white dark:bg-slate-800"
  >
    <h5 class="text-base font-medium text-slate-900 dark:text-white">
      {{ $t('MERGE_CONTACTS.SUMMARY.TITLE') }}
    </h5>
    <ul class="ml-0 list-none">
      <li>
        <span class="inline-block mr-1">❌</span>
        <span
          v-dompurify-html="
            $t('MERGE_CONTACTS.SUMMARY.DELETE_WARNING', {
              primaryContactName,
            })
          "
        />
      </li>
      <li>
        <span class="inline-block mr-1">✅</span>
        <span
          v-dompurify-html="
            $t('MERGE_CONTACTS.SUMMARY.ATTRIBUTE_WARNING', {
              primaryContactName,
              parentContactName,
            })
          "
        />
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  props: {
    primaryContactName: {
      type: String,
      default: '',
    },
    parentContactName: {
      type: String,
      default: '',
    },
  },
};
</script>
