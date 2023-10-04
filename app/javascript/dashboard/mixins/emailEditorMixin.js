// emailHandlingMixin.js

export default {
  data() {
    return {
      ccEmails: '',
      bccEmails: '',
      toEmails: '',
    };
  },
  methods: {
    setCcEmails(value) {
      this.bccEmails = value.bccEmails;
      this.ccEmails = value.ccEmails;
    },
    setCCAndToEmailsFromLastChat() {
      if (!this.lastEmail) return;

      const {
        content_attributes: { email: emailAttributes = {} },
      } = this.lastEmail;

      const conversationContact = this.currentChat?.meta?.sender?.email || '';
      let cc = emailAttributes.cc ? [...emailAttributes.cc] : [];
      let to = [];

      if (cc.includes(conversationContact)) {
        cc = cc.filter(email => email !== conversationContact);
      }

      if (!emailAttributes.from.includes(conversationContact)) {
        to.push(...emailAttributes.from);
        cc.push(conversationContact);
      }

      let bcc = (emailAttributes.bcc || []).filter(
        email => email !== conversationContact
      );

      bcc = [...new Set(bcc)];
      cc = [...new Set(cc)];
      to = [...new Set(to)];

      this.ccEmails = cc.join(', ');
      this.bccEmails = bcc.join(', ');
      this.toEmails = to.join(', ');
    },
    clearEmailField() {
      this.ccEmails = '';
      this.bccEmails = '';
      this.toEmails = '';
    },
  },
};
