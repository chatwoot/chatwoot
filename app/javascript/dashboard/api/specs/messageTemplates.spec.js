import MessageTemplatesAPI from '../messageTemplates';
import ApiClient from '../ApiClient';

describe('#MessageTemplatesAPI', () => {
  it('creates correct instance', () => {
    expect(MessageTemplatesAPI).toBeInstanceOf(ApiClient);
    expect(MessageTemplatesAPI).toHaveProperty('get');
    expect(MessageTemplatesAPI).toHaveProperty('show');
    expect(MessageTemplatesAPI).toHaveProperty('create');
    expect(MessageTemplatesAPI).toHaveProperty('update');
    expect(MessageTemplatesAPI).toHaveProperty('delete');
    expect(MessageTemplatesAPI).toHaveProperty('getFiltered');
    expect(MessageTemplatesAPI).toHaveProperty('getByInbox');
    expect(MessageTemplatesAPI).toHaveProperty('getByStatus');
    expect(MessageTemplatesAPI).toHaveProperty('getApproved');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
      vi.clearAllMocks();
    });

    describe('#getFiltered', () => {
      it('calls API with no filters', () => {
        MessageTemplatesAPI.getFiltered();
        expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/message_templates');
      });

      it('calls API with empty filters', () => {
        MessageTemplatesAPI.getFiltered({});
        expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/message_templates');
      });

      it('calls API with inbox_id filter', () => {
        MessageTemplatesAPI.getFiltered({ inbox_id: 1 });
        expect(axiosMock.get).toHaveBeenCalledWith(
          '/api/v1/message_templates?inbox_id=1'
        );
      });

      it('calls API with channel_type filter', () => {
        MessageTemplatesAPI.getFiltered({ channel_type: 'Channel::Whatsapp' });
        expect(axiosMock.get).toHaveBeenCalledWith(
          '/api/v1/message_templates?channel_type=Channel%3A%3AWhatsapp'
        );
      });

      it('calls API with language filter', () => {
        MessageTemplatesAPI.getFiltered({ language: 'en' });
        expect(axiosMock.get).toHaveBeenCalledWith(
          '/api/v1/message_templates?language=en'
        );
      });

      it('calls API with status filter', () => {
        MessageTemplatesAPI.getFiltered({ status: 'approved' });
        expect(axiosMock.get).toHaveBeenCalledWith(
          '/api/v1/message_templates?status=approved'
        );
      });

      it('calls API with multiple filters', () => {
        MessageTemplatesAPI.getFiltered({
          inbox_id: 1,
          channel_type: 'Channel::Whatsapp',
          language: 'en',
          status: 'approved',
        });
        expect(axiosMock.get).toHaveBeenCalledWith(
          '/api/v1/message_templates?inbox_id=1&channel_type=Channel%3A%3AWhatsapp&language=en&status=approved'
        );
      });

      it('ignores undefined filter values', () => {
        MessageTemplatesAPI.getFiltered({
          inbox_id: 1,
          channel_type: undefined,
          language: '',
          status: 'approved',
        });
        expect(axiosMock.get).toHaveBeenCalledWith(
          '/api/v1/message_templates?inbox_id=1&status=approved'
        );
      });
    });

    describe('#getByInbox', () => {
      it('calls getFiltered with inbox_id', () => {
        const spy = vi.spyOn(MessageTemplatesAPI, 'getFiltered');
        MessageTemplatesAPI.getByInbox(123);
        expect(spy).toHaveBeenCalledWith({ inbox_id: 123 });
      });
    });

    describe('#getByStatus', () => {
      it('calls getFiltered with status', () => {
        const spy = vi.spyOn(MessageTemplatesAPI, 'getFiltered');
        MessageTemplatesAPI.getByStatus('pending');
        expect(spy).toHaveBeenCalledWith({ status: 'pending' });
      });
    });

    describe('#getApproved', () => {
      it('calls getFiltered with approved status', () => {
        const spy = vi.spyOn(MessageTemplatesAPI, 'getFiltered');
        MessageTemplatesAPI.getApproved();
        expect(spy).toHaveBeenCalledWith({ status: 'approved' });
      });
    });

    describe('#create', () => {
      it('sends POST request with template data', () => {
        const templateData = {
          name: 'Test Template',
          category: 'MARKETING',
          language: 'en',
        };
        MessageTemplatesAPI.create(templateData);
        expect(axiosMock.post).toHaveBeenCalledWith(
          '/api/v1/message_templates',
          templateData
        );
      });
    });

    describe('#show', () => {
      it('sends GET request for specific template', () => {
        MessageTemplatesAPI.show(123);
        expect(axiosMock.get).toHaveBeenCalledWith(
          '/api/v1/message_templates/123'
        );
      });
    });

    describe('#update', () => {
      it('sends PATCH request with updated data', () => {
        const updateData = { name: 'Updated Template' };
        MessageTemplatesAPI.update(123, updateData);
        expect(axiosMock.patch).toHaveBeenCalledWith(
          '/api/v1/message_templates/123',
          updateData
        );
      });
    });

    describe('#delete', () => {
      it('sends DELETE request for template', () => {
        MessageTemplatesAPI.delete(123);
        expect(axiosMock.delete).toHaveBeenCalledWith(
          '/api/v1/message_templates/123'
        );
      });
    });
  });
});
