<template>
  <div>
    Ticket Lists
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  components: {
  },
  data() {
    return {};
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    
  },
  methods: {
    closeNewTicketPanel() {
      this.$emit('close');
    },
  },
};
</script>