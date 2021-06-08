import integrationAPI from '../integrations';
import ApiClient from '../ApiClient';
import describeWithAPIMock from './apiSpecHelper';

describe('#integrationAPI', () => {
  it('creates correct instance', () => {
    expect(integrationAPI).toBeInstanceOf(ApiClient);
    expect(integrationAPI).toHaveProperty('get');
    expect(integrationAPI).toHaveProperty('show');
    expect(integrationAPI).toHaveProperty('create');
    expect(integrationAPI).toHaveProperty('update');
    expect(integrationAPI).toHaveProperty('delete');
    expect(integrationAPI).toHaveProperty('connectSlack');
    expect(integrationAPI).toHaveProperty('createHook');
    expect(integrationAPI).toHaveProperty('deleteHook');
  });
  describeWithAPIMock('API calls', context => {
    it('#connectSlack', () => {
      const code = 'SDNFJNSDFNDSJN';
      integrationAPI.connectSlack(code);
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/slack',
        {
          code,
        }
      );
    });

    it('#delete', () => {
      integrationAPI.delete(2);
      expect(context.axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/integrations/2'
      );
    });

    it('#createHook', () => {
      const hookData = {
        app_id: 'fullcontact',
        settings: { api_key: 'SDFSDGSVE' },
      };
      integrationAPI.createHook(hookData);
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/hooks',
        hookData
      );
    });

    it('#deleteHook', () => {
      integrationAPI.deleteHook(2);
      expect(context.axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/integrations/hooks/2'
      );
    });
  });
});
