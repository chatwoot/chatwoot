import { getInboxClassByType } from '../inbox';

describe('#Inbox Helpers', () => {
  describe('getInboxClassByType', () => {
    it('should return correct class for web widget', () => {
      expect(getInboxClassByType('Channel::WebWidget')).toEqual('ion-earth');
    });
    it('should return correct class for fb page', () => {
      expect(getInboxClassByType('Channel::FacebookPage')).toEqual(
        'ion-social-facebook'
      );
    });
    it('should return correct class for  twitter profile', () => {
      expect(getInboxClassByType('Channel::TwitterProfile')).toEqual(
        'ion-social-twitter'
      );
    });
    it('should return correct class for twilio sms', () => {
      expect(getInboxClassByType('Channel::TwilioSms', '')).toEqual(
        'ion-android-textsms'
      );
    });
    it('should return correct class for whatsapp', () => {
      expect(getInboxClassByType('Channel::TwilioSms', 'whatsapp')).toEqual(
        'ion-social-whatsapp-outline'
      );
    });
    it('should return correct class for Api', () => {
      expect(getInboxClassByType('Channel::Api')).toEqual('ion-cloud');
    });
    it('should return correct class for Email', () => {
      expect(getInboxClassByType('Channel::Email')).toEqual('ion-email');
    });
  });
});
