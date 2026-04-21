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

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="parentContactName"
    class="my-4 relative p-2.5 border rounded-[4px] text-s-primary border-s-border bg-s-bg"
  >
    <h5 class="text-base font-medium text-s-primary">
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
