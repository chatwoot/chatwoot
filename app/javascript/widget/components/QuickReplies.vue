<template>
  <div class="quick-replies" :class="classObject" :style="showHideElement">
    <chat-option
      v-for="option in options"
      :key="option.id"
      :action="option"
      :is-selected="isSelected(option)"
      @click="onClick"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ChatOption from 'shared/components/ChatOption';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  components: {
    ChatOption,
  },
  mixins: [darkModeMixin],
  props: {
    isVisible: { type: Boolean, default: false },
  },
  data() {
    let width = document.documentElement.clientWidth;
    return { width };
  },
  computed: {
    ...mapGetters({
      options: 'conversation/getQuickRepliesOptions',
      onOptionSelect: 'conversation/getQuickRepliesCallback',
    }),
    isMobile() {
      return this.width < 668;
    },
    classObject() {
      return { 'mobile-quick-replies': this.isMobile };
    },
    showHideElement() {
      return { display: this.isVisible ? 'flex' : 'none' };
    },
  },
  mounted() {
    window.addEventListener('resize', this.getDimensions);
    const quickRepliesContainer = document.querySelector(
      '.mobile-quick-replies'
    );
    quickRepliesContainer?.addEventListener('wheel', this.scrollListener);
  },
  unmounted() {
    window.removeEventListener('resize', this.getDimensions);
    const quickRepliesContainer = document.querySelector(
      '.mobile-quick-replies'
    );
    quickRepliesContainer?.removeEventListener('wheel', this.scrollListener);
  },
  methods: {
    scrollListener(event) {
      event.preventDefault();
      const isTrackpad = event.deltaX && event.deltaY
      const increment = isTrackpad ? event.deltaX : event.deltaY
      document.querySelector('.mobile-quick-replies').scrollLeft += increment
    },
    getDimensions() {
      this.width = document.documentElement.clientWidth;
    },
    isSelected(option) {
      return this.selected === option.id;
    },
    onClick(selectedOption) {
      this.onOptionSelect(selectedOption);
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.quick-replies {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  justify-content: center;
  align-items: center;
  width: 100%;
  padding: 20px 20px 0 20px;
  max-width: $break-point-tablet;
  margin: 0 auto;
}

.mobile-quick-replies {
  justify-content: unset;
  flex-wrap: nowrap;
  overflow-x: auto;

  /* Hide scrollbar for IE, Edge and Firefox */
  -ms-overflow-style: none;
  scrollbar-width: none;

  /* Hide scrollbar for Chrome, Safari and Opera */
  &::-webkit-scrollbar {
    display: none;
  }

  .option:first-child {
    margin-left: auto !important;
  }
}
</style>
