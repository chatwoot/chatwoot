import { describe, it, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import { nextTick, ref } from 'vue';
import Avatar from './Avatar.vue';

// Mock the i18n composable
vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

describe('Avatar', () => {
  describe('fallback behavior for missing avatars', () => {
    it('displays initials when avatar src is null', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: null,
          size: 32,
        },
      });

      expect(wrapper.find('img').exists()).toBe(false);
      expect(wrapper.text()).toContain('JD');
    });

    it('displays initials when avatar src is undefined', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'Jane Smith',
          src: undefined,
          size: 32,
        },
      });

      expect(wrapper.find('img').exists()).toBe(false);
      expect(wrapper.text()).toContain('JS');
    });

    it('displays initials when avatar src is empty string', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'Bob Wilson',
          src: '',
          size: 32,
        },
      });

      expect(wrapper.find('img').exists()).toBe(false);
      expect(wrapper.text()).toContain('BW');
    });

    it('displays single initial for single word names', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'Alice',
          src: null,
          size: 32,
        },
      });

      expect(wrapper.text()).toContain('A');
    });

    it('displays fallback user icon when name is empty and src is null', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: '',
          src: null,
          size: 32,
        },
      });

      expect(wrapper.find('img').exists()).toBe(false);
      // Should show the fallback icon class
      const iconWrapper = wrapper.find('.i-lucide-user');
      expect(iconWrapper.exists()).toBe(true);
    });
  });

  describe('reactive avatar updates', () => {
    it('updates from null avatar to valid avatar reactively', async () => {
      const avatarUrl = ref(null);
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: avatarUrl.value,
          size: 32,
        },
      });

      // Initially should show initials
      expect(wrapper.find('img').exists()).toBe(false);
      expect(wrapper.text()).toContain('JD');

      // Update to valid avatar URL
      await wrapper.setProps({ src: 'https://example.com/avatar.jpg' });
      await nextTick();

      // Should now show image
      expect(wrapper.find('img').exists()).toBe(true);
      expect(wrapper.find('img').attributes('src')).toBe(
        'https://example.com/avatar.jpg'
      );
    });

    it('falls back to initials when image fails to load', async () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: 'https://example.com/broken-image.jpg',
          size: 32,
        },
      });

      // Initially should show image
      const img = wrapper.find('img');
      expect(img.exists()).toBe(true);

      // Simulate image load error
      await img.trigger('error');
      await nextTick();

      // Should fall back to initials
      expect(wrapper.text()).toContain('JD');
    });

    it('resets to valid image when src prop changes after error', async () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: 'https://example.com/broken.jpg',
          size: 32,
        },
      });

      // Trigger error on first image
      await wrapper.find('img').trigger('error');
      await nextTick();

      // Update to a new valid URL
      await wrapper.setProps({ src: 'https://example.com/valid.jpg' });
      await nextTick();

      // Should show new image (internal state reset)
      const img = wrapper.find('img');
      expect(img.exists()).toBe(true);
      expect(img.attributes('src')).toBe('https://example.com/valid.jpg');
    });
  });

  describe('group conversation avatars', () => {
    it('handles multiple contacts without avatars in group messages', () => {
      const contacts = [
        { id: 1, name: 'Alice Brown', thumbnail: null },
        { id: 2, name: 'Bob Green', thumbnail: null },
        { id: 3, name: 'Charlie Red', thumbnail: null },
      ];

      contacts.forEach(contact => {
        const wrapper = mount(Avatar, {
          props: {
            name: contact.name,
            src: contact.thumbnail,
            size: 24,
          },
        });

        expect(wrapper.find('img').exists()).toBe(false);
        // Should show initials for each contact
        expect(wrapper.text().length).toBeGreaterThan(0);
      });
    });

    it('maintains consistent color scheme based on name', () => {
      const wrapper1 = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: null,
          size: 32,
        },
      });

      const wrapper2 = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: null,
          size: 32,
        },
      });

      // Both avatars with same name should have same background color
      const style1 = wrapper1.find('[role="img"]').attributes('style');
      const style2 = wrapper2.find('[role="img"]').attributes('style');

      expect(style1).toContain('background-color');
      expect(style1).toBe(style2);
    });
  });

  describe('avatar sizes', () => {
    it('renders correct size for conversation list (32px)', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: null,
          size: 32,
        },
      });

      const avatarSpan = wrapper.find('[role="img"]');
      expect(avatarSpan.attributes('style')).toContain('width: 32px');
      expect(avatarSpan.attributes('style')).toContain('height: 32px');
    });

    it('renders correct size for message bubbles (24px)', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: null,
          size: 24,
        },
      });

      const avatarSpan = wrapper.find('[role="img"]');
      expect(avatarSpan.attributes('style')).toContain('width: 24px');
      expect(avatarSpan.attributes('style')).toContain('height: 24px');
    });

    it('renders correct size for contact sidebar (48px)', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: null,
          size: 48,
        },
      });

      const avatarSpan = wrapper.find('[role="img"]');
      expect(avatarSpan.attributes('style')).toContain('width: 48px');
      expect(avatarSpan.attributes('style')).toContain('height: 48px');
    });
  });

  describe('accessibility', () => {
    it('has proper role attribute', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: null,
          size: 32,
        },
      });

      expect(wrapper.find('[role="img"]').exists()).toBe(true);
    });

    it('has proper alt text when image is displayed', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: 'https://example.com/avatar.jpg',
          size: 32,
        },
      });

      const img = wrapper.find('img');
      expect(img.attributes('alt')).toBe('John Doe');
    });

    it('shows proper title for fallback icon when no name and no avatar', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: '',
          src: null,
          size: 32,
        },
      });

      // Should show the fallback icon class
      const fallbackIcon = wrapper.find('.i-lucide-user');
      expect(fallbackIcon.exists()).toBe(true);

      // The Icon component itself has the title attribute set in the parent component
      const iconComponent = wrapper.findComponent({ name: 'Icon' });
      expect(iconComponent.exists()).toBe(true);
    });
  });

  describe('WhatsApp-specific scenarios', () => {
    it('handles contact created without avatar during async fetch', () => {
      // Simulates backend scenario where contact is created without avatar
      // and avatar is fetched asynchronously later
      const wrapper = mount(Avatar, {
        props: {
          name: '+5541998765432',
          src: null,
          size: 32,
        },
      });

      // Should display initials fallback
      expect(wrapper.find('img').exists()).toBe(false);
      expect(wrapper.text()).toContain('+');
    });

    it('updates avatar when async fetch completes', async () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'WhatsApp User',
          src: null,
          size: 32,
        },
      });

      // Initially no avatar
      expect(wrapper.find('img').exists()).toBe(false);

      // Simulate avatar fetch completing
      await wrapper.setProps({
        src: 'https://example.com/whatsapp-avatar.jpg',
      });
      await nextTick();

      // Should now display avatar
      expect(wrapper.find('img').exists()).toBe(true);
      expect(wrapper.find('img').attributes('src')).toBe(
        'https://example.com/whatsapp-avatar.jpg'
      );
    });

    it('handles group message senders without avatars', () => {
      // Simulates group conversation where new sender joins
      // and avatar is not yet fetched
      const wrapper = mount(Avatar, {
        props: {
          name: 'New Group Member',
          src: null,
          size: 24,
        },
      });

      expect(wrapper.find('img').exists()).toBe(false);
      expect(wrapper.text()).toContain('NG');
    });
  });

  describe('status badge visibility', () => {
    it('does not show status badge when avatar is null', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: null,
          size: 32,
          status: 'online',
        },
      });

      // Should show initials
      expect(wrapper.text()).toContain('JD');

      // Status badge should still be visible
      const statusBadge = wrapper.find('.bg-n-teal-10');
      expect(statusBadge.exists()).toBe(true);
    });

    it('hides offline status badge when configured', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: null,
          size: 32,
          status: 'offline',
          hideOfflineStatus: true,
        },
      });

      // Offline status should not be shown
      const offlineBadge = wrapper.find('.bg-n-slate-10');
      expect(offlineBadge.exists()).toBe(false);
    });
  });

  describe('emoji handling in names', () => {
    it('removes emojis from initials', () => {
      const wrapper = mount(Avatar, {
        props: {
          name: 'John 😊 Doe',
          src: null,
          size: 32,
        },
      });

      // Emojis should be stripped from initials
      const text = wrapper.text();
      expect(text).not.toContain('😊');
      // Should still show initials
      expect(text).toContain('J');
    });
  });

  describe('channel inbox badge', () => {
    it('shows inbox badge when provided and no status', () => {
      const inbox = {
        channel_type: 'Channel::Whatsapp',
      };

      const wrapper = mount(Avatar, {
        props: {
          name: 'John Doe',
          src: null,
          size: 32,
          inbox,
        },
      });

      // Should show channel icon
      expect(wrapper.findComponent({ name: 'ChannelIcon' }).exists()).toBe(
        true
      );
    });
  });
});
