<template>
  <div role="dialog" class="emoji-dialog">
    <header class="emoji-dialog-header" role="menu">
      <ul>
        <li
          v-bind:class="{ 'active': selectedKey === category.key }"
          v-for="category in categoryList"
          @click="changeCategory(category)"
        >
          <div
            @click="changeCategory(category)"
            role="menuitem"
            class="emojione"
            v-html="getEmojiUnicode(`:${category.emoji}:`)"
          >
          </div>
        </li>
      </ul>
    </header>
    <div class="emoji-row">
      <h5 class="emoji-category-title">{{selectedKey}}</h5>
      <div
        v-for="(emoji, key) in selectedEmojis"
        role="menuitem"
        :class="`emojione`"
        v-html="getEmojiUnicode(emoji[emoji.length - 1].shortname)"
        v-if="filterEmoji(emoji[emoji.length - 1].shortname)"
        track-by="$index"
        @click="onClick(emoji[emoji.length - 1])"
      />
      </div>
    </div>
  </div>
</template>

<script>
import strategy from 'emojione/emoji.json';
import categoryList from './categories';
import { getEmojiUnicode } from './utils';

export default {
  props: ['onClick'],
  data() {
    return {
      selectedKey: 'people',
      categoryList,
      selectedEmojis: [],
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
