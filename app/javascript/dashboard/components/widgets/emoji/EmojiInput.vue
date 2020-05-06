<template>
  <div role="dialog" class="emoji-dialog">
    <header class="emoji-dialog-header" role="menu">
      <ul>
        <li
          v-for="category in categoryList"
          :key="category.key"
          :class="{ active: selectedKey === category.key }"
          @click="changeCategory(category)"
        >
          <div
            role="menuitem"
            class="emojione"
            @click="changeCategory(category)"
            v-html="` ${getEmojiUnicode(`:${category.emoji}:`)}`"
          ></div>
        </li>
      </ul>
    </header>
    <div class="emoji-row">
      <h5 class="emoji-category-title">
        {{ selectedKey }}
      </h5>
      <div
        v-for="emoji in filteredSelectedEmojis"
        :key="emoji.shortname"
        role="menuitem"
        class="emojione"
        track-by="$index"
        @click="onClick(emoji)"
        v-html="getEmojiUnicode(emoji.shortname)"
      />
    </div>
  </div>
</template>

<script>
/* eslint-disable no-restricted-syntax */
import strategy from 'emojione/emoji.json';
import categoryList from './categories';
import { getEmojiUnicode } from './utils';

export default {
  props: ['onClick'],
  data() {
    return {
      selectedKey: 'people',
      categoryList,
      selectedEmojis: {},
    };
  },
  computed: {
    emojis() {
      const emojiArr = {};

      // categorise and nest emoji
      // sort ensures that modifiers appear unmodified keys
      const keys = Object.keys(strategy);
      for (const key of keys) {
        const value = strategy[key];

        // skip unknown categoryList
        if (value.category !== 'modifier') {
          if (!emojiArr[value.category]) emojiArr[value.category] = {};
          const match = key.match(/(.*?)_tone(.*?)$/);

          if (match) {
            // this check is to stop the plugin from failing in the case that the
            // emoji strategy miscategorizes tones - which was the case here:
            const unmodifiedEmojiExists = !!emojiArr[value.category][match[1]];
            if (unmodifiedEmojiExists) {
              emojiArr[value.category][match[1]][match[2]] = value;
            }
          } else {
            emojiArr[value.category][key] = [value];
          }
        }
      }
      return emojiArr;
    },
    filteredSelectedEmojis() {
      const emojis = this.selectedEmojis;
      const filteredEmojis = Object.keys(emojis)
        .map(key => {
          const emoji = emojis[key];
          const [lastEmoji] = emoji.slice(-1);
          return { ...lastEmoji, key };
        })
        .filter(emoji => {
          const { shortname } = emoji;
          if (shortname) {
            return this.filterEmoji(shortname);
          }
          return false;
        });
      return filteredEmojis;
    },
  },
  // On mount render initial emoji
  mounted() {
    this.getInitialEmoji();
  },
  methods: {
    // Change category and associated emojis
    changeCategory(category) {
      this.selectedKey = category.key;
      this.selectedEmojis = this.emojis[this.selectedKey];
    },

    // Filter non-existant or irregular unicode characters
    filterEmoji(shortName) {
      return shortName !== ':relaxed:' && shortName !== ':frowning2:';
    },
    // Get inital emojis
    getInitialEmoji() {
      this.selectedEmojis = this.emojis.people;
    },
    getEmojiUnicode,
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/widgets/emojiinput';
</style>
