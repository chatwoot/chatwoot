import camelcaseKeys from 'camelcase-keys';

export default camelcaseKeys(
  [
    {
      id: 60913,
      content:
        'Dear Sam,\n\nWe are looking for high-quality cotton fabric for our T-shirt production.\nPlease find attached a document with our specifications and requirements.\nCould you provide us with a quotation and lead time?\n\nLooking forward to your response.\n\nBest regards,\nAlex\nT-Shirt Co.',
      inbox_id: 992,
      conversation_id: 134,
      message_type: 0,
      content_type: 'incoming_email',
      status: 'sent',
      content_attributes: {
        email: {
          bcc: null,
          cc: null,
          content_type:
            'multipart/mixed; boundary=00000000000098e88e0628704c8b',
          date: '2024-12-04T17:13:53+05:30',
          from: ['alex@paperlayer.test'],
          html_content: {
            full: '<div dir="ltr"><p>Dear Sam,</p><p>We are looking for high-quality cotton fabric for our T-shirt production. Please find attached a document with our specifications and requirements. Could you provide us with a quotation and lead time?</p><p>Looking forward to your response.</p><p>Best regards,<br>Alex<br>T-Shirt Co.</p></div>\n',
            reply:
              'Dear Sam,\n\nWe are looking for high-quality cotton fabric for our T-shirt production. Please find attached a document with our specifications and requirements. Could you provide us with a quotation and lead time?\n\nLooking forward to your response.\n\nBest regards,\nAlex\nT-Shirt Co.',
            quoted:
              'Dear Sam,\n\nWe are looking for high-quality cotton fabric for our T-shirt production. Please find attached a document with our specifications and requirements. Could you provide us with a quotation and lead time?\n\nLooking forward to your response.\n\nBest regards,\nAlex\nT-Shirt Co.',
          },
          in_reply_to: null,
          message_id:
            'CAM_Qp+-tdJ2Muy4XZmQfYKOPzsFwrH5H=6j=snsFZEDw@mail.gmail.com',
          multipart: true,
          number_of_attachments: 2,
          subject: 'Inquiry and Quotation for Cotton Fabric',
          text_content: {
            full: 'Dear Sam,\n\nWe are looking for high-quality cotton fabric for our T-shirt production.\nPlease find attached a document with our specifications and requirements.\nCould you provide us with a quotation and lead time?\n\nLooking forward to your response.\n\nBest regards,\nAlex\nT-Shirt Co.\n',
            reply:
              'Dear Sam,\n\nWe are looking for high-quality cotton fabric for our T-shirt production.\nPlease find attached a document with our specifications and requirements.\nCould you provide us with a quotation and lead time?\n\nLooking forward to your response.\n\nBest regards,\nAlex\nT-Shirt Co.',
            quoted:
              'Dear Sam,\n\nWe are looking for high-quality cotton fabric for our T-shirt production.\nPlease find attached a document with our specifications and requirements.\nCould you provide us with a quotation and lead time?\n\nLooking forward to your response.\n\nBest regards,\nAlex\nT-Shirt Co.',
          },
          to: ['sam@cottonmart.test'],
        },
        cc_email: null,
        bcc_email: null,
      },
      created_at: 1733312661,
      private: false,
      source_id: 'CAM_Qp+-tdJ2Muy4XZmQfYKOPzsFwrH5H=6j=snsFZEDw@mail.gmail.com',
      sender: {
        additional_attributes: {
          source_id: 'email:CAM_Qp+8beyon41DA@mail.gmail.com',
        },
        custom_attributes: {},
        email: 'alex@paperlayer.test',
        id: 111256,
        identifier: null,
        name: 'Alex',
        phone_number: null,
        thumbnail: '',
        type: 'contact',
      },
      attachments: [
        {
          id: 826,
          message_id: 60913,
          file_type: 'file',
          account_id: 51,
          extension: null,
          data_url:
            'https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdFdKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--10170e22f42401a9259e17eba6e59877127353d0/requirements.pdf',
          thumb_url:
            'https://staging.chatwoot.com/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdFdKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--10170e22f42401a9259e17eba6e59877127353d0/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCam9UY21WemFYcGxYM1J2WDJacGJHeGJCMmtCK2pBPSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--31a6ed995cc4ac2dd2fa023068ee23b23efa1efb/requirements.pdf',
          file_size: 841909,
          width: null,
          height: null,
        },
        {
          id: 18,
          message_id: 5307,
          file_type: 'file',
          account_id: 2,
          extension: null,
          data_url:
            'http://localhost:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBaUVLIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--4f7e671db635b73d12ee004e87608bc098ef6b3b/quantity-requirements.xls',
          thumb_url:
            'http://localhost:3000/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBaUVLIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--4f7e671db635b73d12ee004e87608bc098ef6b3b/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCam9UY21WemFYcGxYM1J2WDJacGJHeGJCMmtCK2pBPSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--5c454d5f03daf1f9f4068cb242cf9885cc1815b6/all-files.zip',
          file_size: 99844,
          width: null,
          height: null,
        },
      ],
    },
    {
      id: 60914,
      content:
        'Dear Alex,\r\n\r\nThank you for your inquiry. Please find attached our quotation based on your requirements. Let us know if you need further details or wish to discuss specific customizations.\r\n\r\nBest regards,  \r\nSam  \r\nFabricMart',
      account_id: 51,
      inbox_id: 992,
      conversation_id: 134,
      message_type: 1,
      created_at: 1733312726,
      updated_at: '2024-12-04T11:45:34.451Z',
      private: false,
      status: 'sent',
      source_id:
        'conversation/758d1f24-dc76-4abc-9c41-255ed8974f8e/messages/60914@reply.chatwoot.dev',
      content_type: 'text',
      content_attributes: {
        cc_emails: [],
        bcc_emails: [],
        to_emails: [],
      },
      sender_type: 'User',
      sender_id: 1,
      external_source_ids: {},
      additional_attributes: {},
      processed_message_content:
        'Dear Alex,\r\n\r\nThank you for your inquiry. Please find attached our quotation based on your requirements. Let us know if you need further details or wish to discuss specific customizations.\r\n\r\nBest regards,  \r\nSam  \r\nFabricMart',
      sentiment: {},
      conversation: {
        assignee_id: 110,
        unread_count: 0,
        last_activity_at: 1733312726,
        contact_inbox: {
          source_id: 'alex@paperlayer.test',
        },
      },
      attachments: [
        {
          id: 827,
          message_id: 60914,
          file_type: 'file',
          account_id: 51,
          extension: null,
          data_url:
            'https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGFKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--940f9c3df19ce042ef3447809c9c451cfa4e905b/quotation.pdf',
          thumb_url:
            'https://staging.chatwoot.com/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGFKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--940f9c3df19ce042ef3447809c9c451cfa4e905b/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCam9UY21WemFYcGxYM1J2WDJacGJHeGJCMmtCK2pBPSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--31a6ed995cc4ac2dd2fa023068ee23b23efa1efb/quotation.pdf',
          file_size: 841909,
          width: null,
          height: null,
        },
      ],
      sender: {
        id: 110,
        name: 'Alex',
        available_name: 'Alex',
        avatar_url:
          'https://staging.chatwoot.com/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBbktJIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--25806e8b52810484d3d6cb53af9e2a1c0cf1b43d/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2RTNKbGMybDZaVjkwYjE5bWFXeHNXd2RwQWZvdyIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--988d66f5e450207265d5c21bb0edb3facb890a43/slick-deploy.png',
        type: 'user',
        availability_status: 'online',
        thumbnail:
          'https://staging.chatwoot.com/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBbktJIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--25806e8b52810484d3d6cb53af9e2a1c0cf1b43d/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2RTNKbGMybDZaVjkwYjE5bWFXeHNXd2RwQWZvdyIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--988d66f5e450207265d5c21bb0edb3facb890a43/slick-deploy.png',
      },
    },
    {
      id: 60915,
      content:
        'Dear Sam,\n\nThank you for the quotation. Could you share images or samples of the\nfabric for us to review before proceeding?\n\nBest,\nAlex\n\nOn Wed, 4 Dec 2024 at 17:15, Sam from CottonMart <sam@cottonmart.test> wrote:\n\n> Dear Alex,\n>\n> Thank you for your inquiry. Please find attached our quotation based on\n> your requirements. Let us know if you need further details or wish to\n> discuss specific customizations.\n>\n> Best regards,\n> Sam\n> FabricMart\n> attachment [click here to view\n> <https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGFKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--940f9c3df19ce042ef3447809c9c451cfa4e905b/quotation.pdf>]\n>',
      account_id: 51,
      inbox_id: 992,
      conversation_id: 134,
      message_type: 0,
      created_at: 1733312835,
      updated_at: '2024-12-04T11:47:15.876Z',
      private: false,
      status: 'sent',
      source_id: 'CAM_Qp+_70EiYJ_nKMgJ6MZaD58Tq3E57QERcZgnd10g@mail.gmail.com',
      content_type: 'incoming_email',
      content_attributes: {
        email: {
          bcc: null,
          cc: null,
          content_type:
            'multipart/alternative; boundary=0000000000007191be06287054c4',
          date: '2024-12-04T17:16:07+05:30',
          from: ['alex@paperlayer.test'],
          html_content: {
            full: '<div dir="ltr"><p>Dear Sam,</p><p>Thank you for the quotation. Could you share images or samples of the fabric for us to review before proceeding?</p><p>Best,<br>Alex</p></div><br><div class="gmail_quote gmail_quote_container"><div dir="ltr" class="gmail_attr">On Wed, 4 Dec 2024 at 17:15, Sam from CottonMart &lt;<a href="mailto:sam@cottonmart.test">sam@cottonmart.test</a>&gt; wrote:<br></div><blockquote class="gmail_quote" style="margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex">  <p>Dear Alex,</p>\n<p>Thank you for your inquiry. Please find attached our quotation based on your requirements. Let us know if you need further details or wish to discuss specific customizations.</p>\n<p>Best regards,<br>\nSam<br>\nFabricMart</p>\n\n    attachment [<a href="https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGFKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--940f9c3df19ce042ef3447809c9c451cfa4e905b/quotation.pdf" target="_blank">click here to view</a>]\n</blockquote></div>\n',
            reply:
              'Dear Sam,\n\nThank you for the quotation. Could you share images or samples of the fabric for us to review before proceeding?\n\nBest,\nAlex\n\nOn Wed, 4 Dec 2024 at 17:15, Sam from CottonMart <sam@cottonmart.test> wrote:\n>',
            quoted:
              'Dear Sam,\n\nThank you for the quotation. Could you share images or samples of the fabric for us to review before proceeding?\n\nBest,\nAlex',
          },
          in_reply_to:
            'conversation/758d1f24-dc76-4abc-9c41-255ed8974f8e/messages/60914@reply.chatwoot.dev',
          message_id:
            'CAM_Qp+_70EiYJ_nKMgJ6MZaD58Tq3E57QERcZgnd10g@mail.gmail.com',
          multipart: true,
          number_of_attachments: 0,
          subject: 'Re: Inquiry and Quotation for Cotton Fabric',
          text_content: {
            full: 'Dear Sam,\n\nThank you for the quotation. Could you share images or samples of the\nfabric for us to review before proceeding?\n\nBest,\nAlex\n\nOn Wed, 4 Dec 2024 at 17:15, Sam from CottonMart <sam@cottonmart.test>\nwrote:\n\n> Dear Alex,\n>\n> Thank you for your inquiry. Please find attached our quotation based on\n> your requirements. Let us know if you need further details or wish to\n> discuss specific customizations.\n>\n> Best regards,\n> Sam\n> FabricMart\n> attachment [click here to view\n> <https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGFKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--940f9c3df19ce042ef3447809c9c451cfa4e905b/quotation.pdf>]\n>\n',
            reply:
              'Dear Sam,\n\nThank you for the quotation. Could you share images or samples of the\nfabric for us to review before proceeding?\n\nBest,\nAlex\n\nOn Wed, 4 Dec 2024 at 17:15, Sam from CottonMart <sam@cottonmart.test> wrote:\n\n> Dear Alex,\n>\n> Thank you for your inquiry. Please find attached our quotation based on\n> your requirements. Let us know if you need further details or wish to\n> discuss specific customizations.\n>\n> Best regards,\n> Sam\n> FabricMart\n> attachment [click here to view\n> <https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGFKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--940f9c3df19ce042ef3447809c9c451cfa4e905b/quotation.pdf>]\n>',
            quoted:
              'Dear Sam,\n\nThank you for the quotation. Could you share images or samples of the\nfabric for us to review before proceeding?\n\nBest,\nAlex',
          },
          to: ['sam@cottonmart.test'],
        },
        cc_email: null,
        bcc_email: null,
      },
      sender_type: 'Contact',
      sender_id: 111256,
      external_source_ids: {},
      additional_attributes: {},
      processed_message_content:
        'Dear Sam,\n\nThank you for the quotation. Could you share images or samples of the\nfabric for us to review before proceeding?\n\nBest,\nAlex',
      sentiment: {},
      conversation: {
        assignee_id: 110,
        unread_count: 1,
        last_activity_at: 1733312835,
        contact_inbox: {
          source_id: 'alex@paperlayer.test',
        },
      },
      sender: {
        additional_attributes: {
          source_id: 'email:CAM_Qp+8beyon41DA@mail.gmail.com',
        },
        custom_attributes: {},
        email: 'alex@paperlayer.test',
        id: 111256,
        identifier: null,
        name: 'Alex',
        phone_number: null,
        thumbnail: '',
        type: 'contact',
      },
    },
    {
      message_type: 1,
      content_type: 'text',
      source_id:
        'conversation/758d1f24-dc76-4abc-9c41-255ed8974f8e/messages/60916@reply.chatwoot.dev',
      processed_message_content:
        "Dear Alex,\r\n\r\nPlease find attached images of our cotton fabric samples. Let us know if you'd like physical samples sent to you. \r\n\r\nWarm regards,  \r\nSam",
      id: 60916,
      content:
        "Dear Alex,\r\n\r\nPlease find attached images of our cotton fabric samples. Let us know if you'd like physical samples sent to you. \r\n\r\nWarm regards,  \r\nSam",
      account_id: 51,
      inbox_id: 992,
      conversation_id: 134,
      created_at: 1733312866,
      updated_at: '2024-12-04T11:47:53.564Z',
      private: false,
      status: 'sent',
      content_attributes: {
        cc_emails: [],
        bcc_emails: [],
        to_emails: [],
      },
      sender_type: 'User',
      sender_id: 1,
      external_source_ids: {},
      additional_attributes: {},
      sentiment: {},
      conversation: {
        assignee_id: 110,
        unread_count: 0,
        last_activity_at: 1733312866,
        contact_inbox: {
          source_id: 'alex@paperlayer.test',
        },
      },
      attachments: [
        {
          id: 828,
          message_id: 60916,
          file_type: 'image',
          account_id: 51,
          extension: null,
          data_url:
            'https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGVKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--62ee3b99421bfe7d8db85959ae99ab03a899f351/image.png',
          thumb_url:
            'https://staging.chatwoot.com/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGVKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--62ee3b99421bfe7d8db85959ae99ab03a899f351/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2RTNKbGMybDZaVjkwYjE5bWFXeHNXd2RwQWZvdyIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--988d66f5e450207265d5c21bb0edb3facb890a43/image.png',
          file_size: 1617507,
          width: 1600,
          height: 900,
        },
      ],
      sender: {
        id: 110,
        name: 'Alex',
        available_name: 'Alex',
        avatar_url:
          'https://staging.chatwoot.com/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBbktJIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--25806e8b52810484d3d6cb53af9e2a1c0cf1b43d/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2RTNKbGMybDZaVjkwYjE5bWFXeHNXd2RwQWZvdyIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--988d66f5e450207265d5c21bb0edb3facb890a43/slick-deploy.png',
        type: 'user',
        availability_status: 'online',
        thumbnail:
          'https://staging.chatwoot.com/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBbktJIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--25806e8b52810484d3d6cb53af9e2a1c0cf1b43d/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2RTNKbGMybDZaVjkwYjE5bWFXeHNXd2RwQWZvdyIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--988d66f5e450207265d5c21bb0edb3facb890a43/slick-deploy.png',
      },
      previous_changes: {
        updated_at: ['2024-12-04T11:47:46.879Z', '2024-12-04T11:47:53.564Z'],
        source_id: [
          null,
          'conversation/758d1f24-dc76-4abc-9c41-255ed8974f8e/messages/60916@reply.chatwoot.dev',
        ],
      },
    },
    {
      id: 60917,
      content:
        "Great we were looking for something in a different finish see image attached\n\n[image: image.png]\n\nLet me know if you have different finish options?\n\nBest Regards\n\nOn Wed, 4 Dec 2024 at 17:17, Sam from CottonMart <sam@cottonmart.test> wrote:\n\n> Dear Alex,\n>\n> Please find attached images of our cotton fabric samples. Let us know if\n> you'd like physical samples sent to you.\n>\n> Warm regards,\n> Sam\n> attachment [click here to view\n> <https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGVKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--62ee3b99421bfe7d8db85959ae99ab03a899f351/image.png>]\n>",
      account_id: 51,
      inbox_id: 992,
      conversation_id: 134,
      message_type: 0,
      created_at: 1733312969,
      updated_at: '2024-12-04T11:49:29.337Z',
      private: false,
      status: 'sent',
      source_id: 'CAM_Qp+8LuzLTWZXkecjzJAgmb9RAQGm+qTmg@mail.gmail.com',
      content_type: 'incoming_email',
      content_attributes: {
        email: {
          bcc: null,
          cc: null,
          content_type:
            'multipart/related; boundary=0000000000007701030628705e31',
          date: '2024-12-04T17:18:54+05:30',
          from: ['alex@paperlayer.test'],
          html_content: {
            full: '<div dir="ltr">Great we were looking for something in a different finish see image attached<br><br><img src="https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGlKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--408309fa40f1cfea87ee3320a062a5d16ce09d4e/image.png" alt="image.png" width="472" height="305"><br><div><br></div><div>Let me know if you have different finish options?<br><br>Best Regards</div></div><br><div class="gmail_quote gmail_quote_container"><div dir="ltr" class="gmail_attr">On Wed, 4 Dec 2024 at 17:17, Sam from CottonMart &lt;<a href="mailto:sam@cottonmart.test">sam@cottonmart.test</a>&gt; wrote:<br></div><blockquote class="gmail_quote" style="margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex">  <p>Dear Alex,</p>\n<p>Please find attached images of our cotton fabric samples. Let us know if you&#39;d like physical samples sent to you.</p>\n<p>Warm regards,<br>\nSam</p>\n\n    attachment [<a href="https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGVKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--62ee3b99421bfe7d8db85959ae99ab03a899f351/image.png" target="_blank">click here to view</a>]\n</blockquote></div>\n',
            reply:
              'Great we were looking for something in a different finish see image attached\n\n[image.png]\n\nLet me know if you have different finish options?\n\nBest Regards\n\nOn Wed, 4 Dec 2024 at 17:17, Sam from CottonMart <sam@cottonmart.test> wrote:\n>',
            quoted:
              'Great we were looking for something in a different finish see image attached\n\n[image.png]\n\nLet me know if you have different finish options?\n\nBest Regards',
          },
          in_reply_to:
            'conversation/758d1f24-dc76-4abc-9c41-255ed8974f8e/messages/60916@reply.chatwoot.dev',
          message_id: 'CAM_Qp+8LuzLTWZXkecjzJAgmb9RAQGm+qTmg@mail.gmail.com',
          multipart: true,
          number_of_attachments: 1,
          subject: 'Re: Inquiry and Quotation for Cotton Fabric',
          text_content: {
            full: "Great we were looking for something in a different finish see image attached\n\n[image: image.png]\n\nLet me know if you have different finish options?\n\nBest Regards\n\nOn Wed, 4 Dec 2024 at 17:17, Sam from CottonMart <sam@cottonmart.test> wrote:\n\n> Dear Alex,\n>\n> Please find attached images of our cotton fabric samples. Let us know if\n> you'd like physical samples sent to you.\n>\n> Warm regards,\n> Sam\n> attachment [click here to view\n> <https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGVKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--62ee3b99421bfe7d8db85959ae99ab03a899f351/image.png>]\n>",
            reply:
              "Great we were looking for something in a different finish see image attached\n\n[image: image.png]\n\nLet me know if you have different finish options?\n\nBest Regards\n\nOn Wed, 4 Dec 2024 at 17:17, Sam from CottonMart <sam@cottonmart.test> wrote:\n\n> Dear Alex,\n>\n> Please find attached images of our cotton fabric samples. Let us know if\n> you'd like physical samples sent to you.\n>\n> Warm regards,\n> Sam\n> attachment [click here to view\n> <https://staging.chatwoot.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdGVKIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--62ee3b99421bfe7d8db85959ae99ab03a899f351/image.png>]\n>",
            quoted:
              'Great we were looking for something in a different finish see image attached\n\n[image: image.png]\n\nLet me know if you have different finish options?\n\nBest Regards',
          },
          to: ['sam@cottonmart.test'],
        },
        cc_email: null,
        bcc_email: null,
      },
      sender_type: 'Contact',
      sender_id: 111256,
      external_source_ids: {},
      additional_attributes: {},
      processed_message_content:
        'Great we were looking for something in a different finish see image attached\n\n[image: image.png]\n\nLet me know if you have different finish options?\n\nBest Regards',
      sentiment: {},
      conversation: {
        assignee_id: 110,
        unread_count: 1,
        last_activity_at: 1733312969,
        contact_inbox: {
          source_id: 'alex@paperlayer.test',
        },
      },
      sender: {
        additional_attributes: {
          source_id: 'email:CAM_Qp+8beyon41DA@mail.gmail.com',
        },
        custom_attributes: {},
        email: 'alex@paperlayer.test',
        id: 111256,
        identifier: null,
        name: 'Alex',
        phone_number: null,
        thumbnail: '',
        type: 'contact',
      },
    },
  ],
  { deep: true }
);
