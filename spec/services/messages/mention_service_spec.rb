require 'rails_helper'

describe Messages::MentionService do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:first_agent) { create(:user, account: account) }
  let!(:second_agent) { create(:user, account: account) }
  let!(:third_agent) { create(:user, account: account) }
  let!(:admin_user) { create(:user, account: account, role: :administrator) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let!(:team) { create(:team, account: account, name: 'Support Team') }
  let!(:empty_team) { create(:team, account: account, name: 'Empty Team') }
  let(:builder) { double }

  before do
    create(:inbox_member, user: first_agent, inbox: inbox)
    create(:inbox_member, user: second_agent, inbox: inbox)
    create(:team_member, user: first_agent, team: team)
    create(:team_member, user: second_agent, team: team)
    conversation.reload
    allow(NotificationBuilder).to receive(:new).and_return(builder)
    allow(builder).to receive(:perform)
    allow(Conversations::UserMentionJob).to receive(:perform_later)
  end

  describe '#perform' do
    context 'when message is not private' do
      it 'does not process mentions for public messages' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hi (mention://user/#{first_agent.id}/#{first_agent.name})",
          private: false
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).not_to have_received(:new)
        expect(Conversations::UserMentionJob).not_to have_received(:perform_later)
      end
    end

    context 'when message has no content' do
      it 'does not process mentions for empty messages' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: nil,
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).not_to have_received(:new)
        expect(Conversations::UserMentionJob).not_to have_received(:perform_later)
      end
    end

    context 'when message has no mentions' do
      it 'does not process messages without mentions' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: 'just a regular message',
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).not_to have_received(:new)
        expect(Conversations::UserMentionJob).not_to have_received(:perform_later)
      end
    end
  end

  describe 'user mentions' do
    context 'when message contains single user mention' do
      it 'creates notifications for inbox member who was mentioned' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hi (mention://user/#{first_agent.id}/#{first_agent.name})",
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention',
          user: first_agent,
          account: account,
          primary_actor: message.conversation,
          secondary_actor: message
        )
        expect(Conversations::UserMentionJob).to have_received(:perform_later).with(
          [first_agent.id.to_s],
          conversation.id,
          account.id
        )
      end

      it 'adds mentioned user as conversation participant' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hi (mention://user/#{first_agent.id}/#{first_agent.name})",
          private: true
        )

        described_class.new(message: message).perform

        expect(conversation.conversation_participants.map(&:user_id)).to include(first_agent.id)
      end
    end

    context 'when message contains multiple user mentions' do
      let(:message) do
        build(
          :message,
          conversation: conversation,
          account: account,
          content: "hey (mention://user/#{second_agent.id}/#{second_agent.name}) " \
                   "and (mention://user/#{first_agent.id}/#{first_agent.name}), please look into this?",
          private: true
        )
      end

      it 'creates notifications for all mentioned inbox members' do
        described_class.new(message: message).perform

        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention',
          user: second_agent,
          account: account,
          primary_actor: message.conversation,
          secondary_actor: message
        )
        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention',
          user: first_agent,
          account: account,
          primary_actor: message.conversation,
          secondary_actor: message
        )
      end

      it 'adds all mentioned users to the participants list' do
        described_class.new(message: message).perform
        expect(conversation.conversation_participants.map(&:user_id)).to contain_exactly(first_agent.id, second_agent.id)
      end

      it 'passes unique user IDs to UserMentionJob' do
        described_class.new(message: message).perform
        expect(Conversations::UserMentionJob).to have_received(:perform_later).with(
          contain_exactly(first_agent.id.to_s, second_agent.id.to_s),
          conversation.id,
          account.id
        )
      end
    end

    context 'when mentioned user is not an inbox member' do
      let!(:non_member_user) { create(:user, account: account) }

      it 'does not create notifications for non-inbox members' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hi (mention://user/#{non_member_user.id}/#{non_member_user.name})",
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).not_to have_received(:new)
        expect(Conversations::UserMentionJob).not_to have_received(:perform_later)
      end
    end

    context 'when mentioned user is an admin' do
      it 'creates notifications for admin users even if not inbox members' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hi (mention://user/#{admin_user.id}/#{admin_user.name})",
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention',
          user: admin_user,
          account: account,
          primary_actor: message.conversation,
          secondary_actor: message
        )
      end
    end

    context 'when same user is mentioned multiple times' do
      it 'creates only one notification per user' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hi (mention://user/#{first_agent.id}/#{first_agent.name}) and again (mention://user/#{first_agent.id}/#{first_agent.name})",
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).to have_received(:new).once
        expect(Conversations::UserMentionJob).to have_received(:perform_later).with(
          [first_agent.id.to_s],
          conversation.id,
          account.id
        )
      end
    end
  end

  describe 'team mentions' do
    context 'when message contains single team mention' do
      it 'creates notifications for all team members who are inbox members' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hey (mention://team/#{team.id}/#{team.name}) please help",
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention',
          user: first_agent,
          account: account,
          primary_actor: message.conversation,
          secondary_actor: message
        )
        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention',
          user: second_agent,
          account: account,
          primary_actor: message.conversation,
          secondary_actor: message
        )
      end

      it 'adds all team members as conversation participants' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hey (mention://team/#{team.id}/#{team.name}) please help",
          private: true
        )

        described_class.new(message: message).perform

        expect(conversation.conversation_participants.map(&:user_id)).to contain_exactly(first_agent.id, second_agent.id)
      end

      it 'passes team member IDs to UserMentionJob' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hey (mention://team/#{team.id}/#{team.name}) please help",
          private: true
        )

        described_class.new(message: message).perform

        expect(Conversations::UserMentionJob).to have_received(:perform_later).with(
          contain_exactly(first_agent.id.to_s, second_agent.id.to_s),
          conversation.id,
          account.id
        )
      end
    end

    context 'when team has members who are not inbox members' do
      let!(:non_inbox_team_member) { create(:user, account: account) }

      before do
        create(:team_member, user: non_inbox_team_member, team: team)
      end

      it 'only notifies team members who are also inbox members' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hey (mention://team/#{team.id}/#{team.name}) please help",
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention', user: first_agent, account: account,
          primary_actor: message.conversation, secondary_actor: message
        )
        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention', user: second_agent, account: account,
          primary_actor: message.conversation, secondary_actor: message
        )
        expect(NotificationBuilder).not_to have_received(:new).with(
          notification_type: 'conversation_mention', user: non_inbox_team_member, account: account,
          primary_actor: message.conversation, secondary_actor: message
        )
      end
    end

    context 'when team has admin members' do
      before do
        create(:team_member, user: admin_user, team: team)
      end

      it 'includes admin team members in notifications' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hey (mention://team/#{team.id}/#{team.name}) please help",
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention',
          user: admin_user,
          account: account,
          primary_actor: message.conversation,
          secondary_actor: message
        )
      end
    end

    context 'when team is empty' do
      it 'does not create any notifications for empty teams' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hey (mention://team/#{empty_team.id}/#{empty_team.name}) please help",
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).not_to have_received(:new)
        expect(Conversations::UserMentionJob).not_to have_received(:perform_later)
      end
    end

    context 'when team does not exist' do
      it 'does not create notifications for non-existent teams' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: 'hey (mention://team/99999/NonExistentTeam) please help',
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).not_to have_received(:new)
        expect(Conversations::UserMentionJob).not_to have_received(:perform_later)
      end
    end

    context 'when same team is mentioned multiple times' do
      it 'creates only one notification per team member' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hey (mention://team/#{team.id}/#{team.name}) and again (mention://team/#{team.id}/#{team.name})",
          private: true
        )

        described_class.new(message: message).perform

        expect(NotificationBuilder).to have_received(:new).exactly(2).times
        expect(Conversations::UserMentionJob).to have_received(:perform_later).with(
          contain_exactly(first_agent.id.to_s, second_agent.id.to_s),
          conversation.id,
          account.id
        )
      end
    end
  end

  describe 'mixed user and team mentions' do
    context 'when message contains both user and team mentions' do
      it 'creates notifications for both individual users and team members' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hey (mention://user/#{third_agent.id}/#{third_agent.name}) and (mention://team/#{team.id}/#{team.name})",
          private: true
        )

        # Make third_agent an inbox member
        create(:inbox_member, user: third_agent, inbox: inbox)

        described_class.new(message: message).perform

        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention', user: third_agent, account: account,
          primary_actor: message.conversation, secondary_actor: message
        )
        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention', user: first_agent, account: account,
          primary_actor: message.conversation, secondary_actor: message
        )
        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention', user: second_agent, account: account,
          primary_actor: message.conversation, secondary_actor: message
        )
      end

      it 'avoids duplicate notifications when user is mentioned directly and via team' do
        message = build(
          :message,
          conversation: conversation,
          account: account,
          content: "hey (mention://user/#{first_agent.id}/#{first_agent.name}) and (mention://team/#{team.id}/#{team.name})",
          private: true
        )

        described_class.new(message: message).perform

        # first_agent should only receive one notification despite being mentioned directly and via team
        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention',
          user: first_agent,
          account: account,
          primary_actor: message.conversation,
          secondary_actor: message
        ).once
        expect(NotificationBuilder).to have_received(:new).with(
          notification_type: 'conversation_mention',
          user: second_agent,
          account: account,
          primary_actor: message.conversation,
          secondary_actor: message
        ).once
      end
    end
  end

  describe 'cross-account validation' do
    let!(:other_account) { create(:account) }
    let!(:other_team) { create(:team, account: other_account) }
    let!(:other_user) { create(:user, account: other_account) }

    before do
      create(:team_member, user: other_user, team: other_team)
    end

    it 'does not process mentions for teams from other accounts' do
      message = build(
        :message,
        conversation: conversation,
        account: account,
        content: "hey (mention://team/#{other_team.id}/#{other_team.name})",
        private: true
      )

      described_class.new(message: message).perform

      expect(NotificationBuilder).not_to have_received(:new)
      expect(Conversations::UserMentionJob).not_to have_received(:perform_later)
    end

    it 'does not process mentions for users from other accounts' do
      message = build(
        :message,
        conversation: conversation,
        account: account,
        content: "hey (mention://user/#{other_user.id}/#{other_user.name})",
        private: true
      )

      described_class.new(message: message).perform

      expect(NotificationBuilder).not_to have_received(:new)
      expect(Conversations::UserMentionJob).not_to have_received(:perform_later)
    end
  end
end
