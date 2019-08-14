<template>
  <div>
  <ul class="vertical dropdown menu canned" id="canned-list"  v-bind:style="{ top: getTopPadding() + 'rem'}">
    <li
      v-for="(item, index) in cannedMessages"
      :id="`canned-${index}`"
      :class="{'active': index === selectedIndex}"
      v-on:click="onListItemSelection(index)"
      v-on:mouseover="onHover(index)"
    >
      <a><strong>{{item.short_code}}</strong> - {{item.content}}</a>
    </li>
  </ul>
</div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  props: ['onKeyenter', 'onClick'],
  data() {
    return {
      selectedIndex: 0,
    };
  },
  computed: {
    ...mapGetters({
      cannedMessages: 'getCannedResponses',
    }),
  },
  mounted() {
    /* eslint-disable no-confusing-arrow */
    document.addEventListener('keydown', this.keyListener);
  },
  methods: {
    getTopPadding() {
      if (this.cannedMessages.length <= 4) {
        return -this.cannedMessages.length * 3.5;
      }
      return -14;
    },
    isUp(e) {
      return e.keyCode === 38 || (e.ctrlKey && e.keyCode === 80);  // UP, Ctrl-P
    },
    isDown(e) {
      return e.keyCode === 40 || (e.ctrlKey && e.keyCode === 78);  // DOWN, Ctrl-N
    },
    isEnter(e) {
      return e.keyCode === 13;
    },
    keyListener(e) {
      if (this.isUp(e)) {
        if (!this.selectedIndex) {
          this.selectedIndex = this.cannedMessages.length - 1;
        } else {
          this.selectedIndex -= 1;
        }
      }
      if (this.isDown(e)) {
        if (this.selectedIndex === this.cannedMessages.length - 1) {
          this.selectedIndex = 0;
        } else {
          this.selectedIndex += 1;
        }
      }
      if (this.isEnter(e)) {
        this.onKeyenter(this.cannedMessages[this.selectedIndex].content);
      }
      this.$el.querySelector('#canned-list').scrollTop = 34 * this.selectedIndex;
    },
    onHover(index) {
      this.selectedIndex = index;
    },
    onListItemSelection(index) {
      this.selectedIndex = index;
      this.onClick(this.cannedMessages[this.selectedIndex].content);
    },
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.keyListener);
  },
};
</script>
