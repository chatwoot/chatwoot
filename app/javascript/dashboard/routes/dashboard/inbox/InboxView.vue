<script>
import InboxList from './InboxList.vue';
import InboxItemHeader from './components/InboxItemHeader.vue';
import ConversationBox from 'dashboard/components/widgets/conversation/ConversationBox.vue';

export default {
  components: {
    InboxList,
    InboxItemHeader,
    ConversationBox,
  },
};
</script>
<template>
  <section class="flex w-full h-full bg-white dark:bg-slate-900">
    <InboxList />
    <div class="flex flex-col w-full h-full">
      <InboxItemHeader :total-length="28" :current-index="1" />
      <ConversationBox class="h-full" />
    </div>
  </section>
</template>
