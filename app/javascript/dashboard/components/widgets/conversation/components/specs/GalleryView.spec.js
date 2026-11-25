import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { withFullI18n } from 'test-i18n';
import GalleryView from '../GalleryView.vue';

withFullI18n();

// The conversation attachments endpoint carries the sender and the message
// time; the attachment inside a message payload carries neither.
const listed = (id, messageId, createdAt, sender) => ({
  id,
  message_id: messageId,
  file_type: 'image',
  data_url: `https://example.com/${id}.png`,
  created_at: createdAt,
  sender: { thumbnail: '', ...sender },
});

const fromBubble = (id, messageId) => ({
  id,
  message_id: messageId,
  file_type: 'image',
  data_url: `https://example.com/${id}.png`,
});

const mountGallery = ({ attachment, allAttachments }) => {
  const store = createStore({
    getters: { getCurrentUser: () => ({ id: 1 }) },
  });
  return mount(GalleryView, {
    props: { attachment, allAttachments, show: true },
    global: {
      plugins: [store],
      stubs: {
        TeleportWithDirection: { template: '<div><slot /></div>' },
        'woot-modal': { template: '<div><slot /></div>' },
        Avatar: true,
      },
    },
  });
};

describe('GalleryView', () => {
  const allAttachments = [
    listed(11, 501, 1_700_000_000, { id: 1, type: 'user', name: 'John' }),
    listed(12, 502, 1_700_090_000, { id: 7, type: 'contact', name: 'Bruno' }),
    listed(13, 502, 1_700_090_000, { id: 7, type: 'contact', name: 'Bruno' }),
    listed(14, 503, 1_700_095_000, { id: 1, type: 'contact', name: 'Carla' }),
  ];

  it('shows the sender and the time of an attachment opened from its bubble', async () => {
    const wrapper = mountGallery({
      attachment: fromBubble(12, 502),
      allAttachments,
    });

    await nextTick();
    const header = wrapper.find('header').text();
    expect(header).toContain('Bruno');
    expect(header).toMatch(/2023/);
  });

  it('starts the counter on the opened attachment, not on the first one of its message', () => {
    const wrapper = mountGallery({
      attachment: fromBubble(13, 502),
      allAttachments,
    });

    expect(wrapper.text()).toContain('3 / 4');
  });

  it('starts on the first position when the opened attachment is not listed', () => {
    const wrapper = mountGallery({
      attachment: fromBubble(99, 777),
      allAttachments,
    });

    expect(wrapper.text()).toContain('1 / 4');
  });

  it('names a contact whose id matches the current user by their own name', async () => {
    const wrapper = mountGallery({
      attachment: fromBubble(14, 503),
      allAttachments,
    });
    await nextTick();

    expect(wrapper.find('header').text()).toContain('Carla');
  });

  it('calls the current user "You"', async () => {
    const wrapper = mountGallery({
      attachment: fromBubble(11, 501),
      allAttachments,
    });
    await nextTick();

    expect(wrapper.find('header').text()).toContain('You');
  });
});
