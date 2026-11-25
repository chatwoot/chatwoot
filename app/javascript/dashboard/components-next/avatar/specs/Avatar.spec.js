import { mount } from '@vue/test-utils';
import Avatar from '../Avatar.vue';

const UPLOAD_OVERLAY = '.bg-n-alpha-black1';
const DELETE_BUTTON = '.bg-n-solid-3';
const INITIALS = '.select-none';
const AVATAR_BOX = 'span[role="img"]';

const global = {
  stubs: {
    ChannelIcon: {
      props: ['inbox'],
      template: '<span class="channel-icon" />',
    },
  },
};

const createAvatar = (props = {}, options = {}) =>
  mount(Avatar, { props: { name: 'John Doe', ...props }, global, ...options });

describe('Avatar', () => {
  describe('initials', () => {
    it('uses the first letter of a single word name', () => {
      expect(createAvatar({ name: 'John' }).find(INITIALS).text()).toBe('J');
    });

    it('uses the first letter of the first two words', () => {
      expect(
        createAvatar({ name: 'john ronald reuel tolkien' })
          .find(INITIALS)
          .text()
      ).toBe('JR');
    });

    it('ignores emoji in the name', () => {
      expect(createAvatar({ name: '😀 Jane Doe' }).find(INITIALS).text()).toBe(
        'JD'
      );
    });

    it('falls back to the user icon when there is no name or image', () => {
      const wrapper = createAvatar({ name: '' });

      expect(wrapper.find('.i-lucide-user').exists()).toBe(true);
      expect(wrapper.find(INITIALS).exists()).toBe(false);
    });

    it('prefers a custom icon over initials', () => {
      const wrapper = createAvatar({ iconName: 'i-lucide-bot' });

      expect(wrapper.find('.i-lucide-bot').exists()).toBe(true);
      expect(wrapper.find(INITIALS).exists()).toBe(false);
    });
  });

  describe('image source', () => {
    it('renders the image when a src is given', () => {
      const img = createAvatar({ src: 'avatar.png' }).find('img');

      expect(img.exists()).toBe(true);
      expect(img.attributes('alt')).toBe('John Doe');
    });

    it('falls back to initials when the image fails to load', async () => {
      const wrapper = createAvatar({ src: 'broken.png' });
      await wrapper.find('img').trigger('error');

      expect(wrapper.find('img').exists()).toBe(false);
      expect(wrapper.find(INITIALS).text()).toBe('JD');
    });

    it('retries when the src changes after a failure', async () => {
      const wrapper = createAvatar({ src: 'broken.png' });
      await wrapper.find('img').trigger('error');
      await wrapper.setProps({ src: 'working.png' });

      expect(wrapper.find('img').exists()).toBe(true);
    });
  });

  describe('sizing', () => {
    it('applies the size to the container', () => {
      const style = createAvatar({ size: 48 }).attributes('style');

      expect(style).toContain('width: 48px');
      expect(style).toContain('height: 48px');
    });

    it('scales the initials with the avatar, capped at 24px', () => {
      expect(
        createAvatar({ size: 40 }).find(INITIALS).attributes('style')
      ).toContain('font-size: 16px');
      expect(
        createAvatar({ size: 200 }).find(INITIALS).attributes('style')
      ).toContain('font-size: 24px');
    });

    it.each([
      [16, 'rounded'],
      [24, 'rounded-md'],
      [32, 'rounded-lg'],
      [48, 'rounded-xl'],
      [64, 'rounded-2xl'],
    ])('uses a %ipx-appropriate radius', (size, expected) => {
      expect(createAvatar({ size }).find(AVATAR_BOX).classes()).toContain(
        expected
      );
    });

    it('honours roundedFull regardless of size', () => {
      expect(
        createAvatar({ size: 64, roundedFull: true }).find(AVATAR_BOX).classes()
      ).toContain('rounded-full');
    });
  });

  describe('status badge', () => {
    it.each([
      ['online', 'bg-n-teal-10'],
      ['busy', 'bg-n-amber-10'],
      ['offline', 'bg-n-slate-10'],
    ])('renders the %s badge', (status, expected) => {
      expect(createAvatar({ status }).find(`.${expected}`).exists()).toBe(true);
    });

    it('hides the offline badge when hideOfflineStatus is set', () => {
      const wrapper = createAvatar({
        status: 'offline',
        hideOfflineStatus: true,
      });

      expect(wrapper.find('.bg-n-slate-10').exists()).toBe(false);
    });

    it('accepts only known availability statuses', () => {
      const { validator } = Avatar.props.status;

      expect(validator('online')).toBe(true);
      expect(validator(null)).toBe(true);
      expect(validator('sleeping')).toBe(false);
    });

    it('renders the channel icon when an inbox is given', () => {
      const wrapper = createAvatar({ inbox: { channel_type: 'Channel::Api' } });

      expect(wrapper.find('.channel-icon').exists()).toBe(true);
    });

    it('prefers the status badge over the channel icon', () => {
      const wrapper = createAvatar({
        status: 'online',
        inbox: { channel_type: 'Channel::Api' },
      });

      expect(wrapper.find('.bg-n-teal-10').exists()).toBe(true);
      expect(wrapper.find('.channel-icon').exists()).toBe(false);
    });

    it('lets a consumer replace the badge', () => {
      const wrapper = createAvatar(
        { status: 'online' },
        { slots: { badge: '<span class="custom-badge" />' } }
      );

      expect(wrapper.find('.custom-badge').exists()).toBe(true);
      expect(wrapper.find('.bg-n-teal-10').exists()).toBe(false);
    });
  });

  describe('upload', () => {
    it('renders no upload affordance by default', () => {
      const wrapper = createAvatar();

      expect(wrapper.find(UPLOAD_OVERLAY).exists()).toBe(false);
      expect(wrapper.find('input[type="file"]').exists()).toBe(false);
    });

    it('opens the file picker when the overlay is clicked', async () => {
      const errors = [];
      const wrapper = createAvatar(
        { allowUpload: true },
        { global: { ...global, config: { errorHandler: e => errors.push(e) } } }
      );

      const input = wrapper.find('input[type="file"]');
      expect(input.exists()).toBe(true);

      const click = vi.fn();
      input.element.click = click;
      await wrapper.find(UPLOAD_OVERLAY).trigger('click');

      expect(click).toHaveBeenCalled();
      expect(errors).toEqual([]);
    });

    it('emits the selected file with a preview url', async () => {
      // jsdom does not implement createObjectURL, so there is nothing to spy on
      const original = URL.createObjectURL;
      URL.createObjectURL = vi.fn(() => 'blob:preview');
      const wrapper = createAvatar({ allowUpload: true });
      const file = new File(['x'], 'avatar.png', { type: 'image/png' });
      const input = wrapper.find('input[type="file"]');
      Object.defineProperty(input.element, 'files', { value: [file] });

      await input.trigger('change');

      expect(wrapper.emitted('upload')[0][0]).toEqual({
        file,
        url: 'blob:preview',
      });
      URL.createObjectURL = original;
    });

    it('does not emit when the picker is dismissed', async () => {
      const wrapper = createAvatar({ allowUpload: true });
      const input = wrapper.find('input[type="file"]');
      Object.defineProperty(input.element, 'files', { value: [] });

      await input.trigger('change');

      expect(wrapper.emitted('upload')).toBeUndefined();
    });
  });

  describe('delete', () => {
    it('offers delete only when there is an image to remove', () => {
      expect(
        createAvatar({ allowUpload: true }).find(DELETE_BUTTON).exists()
      ).toBe(false);
      expect(createAvatar({ src: 'a.png' }).find(DELETE_BUTTON).exists()).toBe(
        false
      );
      expect(
        createAvatar({ src: 'a.png', allowUpload: true })
          .find(DELETE_BUTTON)
          .exists()
      ).toBe(true);
    });

    it('emits delete and does not bubble to the surrounding row', async () => {
      const onRowClick = vi.fn();
      const Row = {
        components: { Avatar },
        template: `<div @click="onRowClick">
          <Avatar name="John Doe" src="a.png" allow-upload @delete="onDelete" />
        </div>`,
        setup: () => ({ onRowClick, onDelete: vi.fn() }),
      };
      const wrapper = mount(Row, { global });

      await wrapper.find(DELETE_BUTTON).trigger('click');

      expect(wrapper.findComponent(Avatar).emitted('delete')).toHaveLength(1);
      expect(onRowClick).not.toHaveBeenCalled();
    });
  });

  describe('overlay slot', () => {
    // ConversationCard.vue's shape: #overlay is ALWAYS passed and the v-if sits
    // on the inner node, so an unhovered card yields only a comment node.
    const ConversationCardLike = {
      components: { Avatar },
      props: { hovered: { type: Boolean, default: false } },
      template: `
        <Avatar name="John Doe">
          <template #overlay="{ size }">
            <label v-if="hovered" class="selection-checkbox" :style="{ width: size + 'px' }" />
          </template>
        </Avatar>
      `,
    };

    // CardAvatar.vue / ContactsCard.vue's shape: v-if on the <template> itself.
    const CardAvatarLike = {
      components: { Avatar },
      props: { hovered: { type: Boolean, default: false } },
      template: `
        <Avatar name="John Doe">
          <template v-if="hovered" #overlay>
            <label class="selection-checkbox" />
          </template>
        </Avatar>
      `,
    };

    it('renders the consumer overlay instead of the upload one', () => {
      const wrapper = mount(ConversationCardLike, {
        props: { hovered: true },
        global,
      });

      expect(wrapper.find('.selection-checkbox').exists()).toBe(true);
      expect(wrapper.find(UPLOAD_OVERLAY).exists()).toBe(false);
    });

    it('does not fall back to the upload overlay when the slot renders nothing', () => {
      const wrapper = mount(ConversationCardLike, {
        props: { hovered: false },
        global,
      });

      expect(wrapper.find('.selection-checkbox').exists()).toBe(false);
      expect(wrapper.find(UPLOAD_OVERLAY).exists()).toBe(false);
      expect(wrapper.find('.i-lucide-upload').exists()).toBe(false);
    });

    it('does not fall back when the v-if is on the template', () => {
      const wrapper = mount(CardAvatarLike, {
        props: { hovered: false },
        global,
      });

      expect(wrapper.find(UPLOAD_OVERLAY).exists()).toBe(false);
    });

    it('passes the upload handles to the slot', () => {
      const slotProps = {};
      mount(Avatar, {
        props: { name: 'John Doe', size: 48, allowUpload: true },
        global,
        slots: {
          overlay: props => {
            Object.assign(slotProps, props);
            return '';
          },
        },
      });

      expect(slotProps.size).toBe(48);
      expect(typeof slotProps.handleUpload).toBe('function');
      expect(typeof slotProps.handleImageUpload).toBe('function');
    });
  });
});
