require 'rails_helper'

RSpec.describe Conversation, type: :model do
  context "with an attached commission offer" do
    let(:o) do 
      c = create(:commission_offer)
      c.confirm!
      c
    end
    let(:c){ o.conversation }

    it "exists" do
      expect(c).to_not be(nil)
    end
    it "says it is #for_offer" do
      expect(c).to be_for_offer
    end
  end
  describe "nested attributes" do
    let(:user_a){ create(:user) }
    let(:user_b){ create(:user) }
    let(:users){ [user_a, user_b] }
    let(:users_attributes){ users.map{|u| {user_id: u.id} } }
    it "creates conversation users" do
      expect{
        Conversation.create(conversation_users_attributes: users_attributes)
      }.to change{ConversationUser.count}.by(2)
    end
    it "associates the users properly" do
      c = Conversation.create(conversation_users_attributes: users_attributes)
      expect(c.users).to contain_exactly(*users)
    end
  end

  describe ".mark_read(user)" do
    let(:user_a){ create(:user) }
    let(:user_b){ create(:user) }
    let(:conversation){ 
      create(:conversation, users: [user_a, user_b])
    }
    it "raises an error if the user is not in the conversation" do
      expect{
        conversation.mark_read!(create(:user))
      }.to raise_error(Conversation::UserNotInConversation)
    end
    it "changes the user's last read at time" do
      cu = conversation.conversation_users.where(user: user_a).first
      Timecop.freeze do
        expect{
          conversation.mark_read!(user_a)
        }.to change{cu.reload.last_read_at}.to(Time.now)
      end
    end
  end

  describe ".messages_for_user" do
    let(:user_a){ create(:user) }
    let(:user_b){ create(:user) }
    let(:conversation){ 
      create(:conversation, users: [user_a, user_b])
    }
    it "throws an error if the user isn't in the conversation" do
      expect{
        conversation.messages_for_user(create(:user))
      }.to raise_error(Conversation::UserNotInConversation)
    end
    it "returns messages made after this user's last_read_at" do
      m1 = create(:message,
                  conversation: conversation,
                  user: user_b)
      m2 = create(:message,
                  conversation: conversation,
                  user: user_a)
      conversation.mark_read!(user_a)
      m3 = create(:message,
                  conversation: conversation,
                  user: user_b)
      m4 = create(:message,
                  conversation: conversation,
                  user: user_b)
      res = conversation.messages_for_user(user_a)
      expect(res).to contain_exactly(m3, m4)
    end
  end
end