import { mount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import VideoEmbedInput from './VideoEmbedInput.vue';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

// One representative link per provider in the real markdown_embeds.yml config
// (github_gist is intentionally excluded from the previewable embeds list).
const SUPPORTED_URLS = [
  ['youtube (watch)', 'https://youtube.com/watch?v=dQw4w9WgXcQ'],
  ['youtube (youtu.be)', 'https://youtu.be/dQw4w9WgXcQ'],
  ['loom', 'https://loom.com/share/abc123'],
  ['vimeo', 'https://vimeo.com/123456789'],
  ['mp4', 'https://example.com/video.mp4'],
  ['arcade (tab)', 'https://app.arcade.software/share/abc123?embed_mobile=tab'],
  ['arcade', 'https://app.arcade.software/share/abc123'],
  ['wistia', 'https://mybrand.wistia.com/medias/abc123'],
  ['bunny', 'https://iframe.mediadelivery.net/embed/12345/abc-def'],
  ['codepen', 'https://codepen.io/user/pen/abcXYZ'],
  ['guidejar', 'https://guidejar.com/guides/abc123'],
];

const InputStub = {
  name: 'Input',
  props: ['modelValue', 'messageType'],
  emits: ['update:modelValue', 'enter', 'input'],
  template: '<input :value="modelValue" />',
};

const ButtonStub = {
  name: 'Button',
  props: ['label', 'disabled'],
  emits: ['click'],
  template:
    '<button :disabled="disabled" @click="$emit(\'click\')">{{ label }}</button>',
};

const mountInput = () =>
  mount(VideoEmbedInput, {
    global: { stubs: { Input: InputStub, Button: ButtonStub, Icon: true } },
  });

const setUrl = async (wrapper, value) => {
  wrapper.findComponent({ name: 'Input' }).vm.$emit('update:modelValue', value);
  await wrapper.vm.$nextTick();
};

const addButton = wrapper =>
  wrapper.findAll('button').find(b => b.text() === 'VIDEO_EMBED.ADD');

describe('VideoEmbedInput', () => {
  it.each(SUPPORTED_URLS)(
    'enables Embed and submits a %s link',
    async (_label, url) => {
      const wrapper = mountInput();
      await setUrl(wrapper, url);

      const add = addButton(wrapper);
      expect(add.attributes('disabled')).toBeUndefined();

      await add.trigger('click');
      expect(wrapper.emitted('submit')).toEqual([[url]]);
    }
  );

  it('disables Embed and shows the error for an unsupported link', async () => {
    const wrapper = mountInput();
    await setUrl(wrapper, 'https://example.com/not-a-video');

    expect(addButton(wrapper).attributes('disabled')).toBeDefined();

    wrapper.findComponent({ name: 'Input' }).vm.$emit('enter');
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('submit')).toBeFalsy();
    expect(wrapper.text()).toContain('VIDEO_EMBED.ERROR');
  });

  it('ignores a submit while the field is empty', async () => {
    const wrapper = mountInput();
    wrapper.findComponent({ name: 'Input' }).vm.$emit('enter');
    await wrapper.vm.$nextTick();
    expect(wrapper.emitted('submit')).toBeFalsy();
  });

  it('emits cancel from the Cancel button', async () => {
    const wrapper = mountInput();
    const cancel = wrapper
      .findAll('button')
      .find(b => b.text() === 'VIDEO_EMBED.CANCEL');
    await cancel.trigger('click');
    expect(wrapper.emitted('cancel')).toBeTruthy();
  });
});
