# frozen_string_literal: true
class Message < ActiveRecord::Base
  belongs_to :user
  belongs_to :conversation,
    touch: :last_message_at

  after_create :notify_cables

  ##
  # The next two methods are kind of hacks
  # Basically, we somtimes select a calcualted READ value in SQL, and
  # sometimes we don't. So we basically fake having it *always* selected
  # by defining dummy methods
  def read?
    attributes["read"]
  end

  def read
    attributes["read"]
  end

  ##########
  # SCOPES #
  ##########
  def self.unread_for(user)
    joins("INNER JOIN conversation_users ON conversation_users.conversation_id = messages.conversation_id")
      .where(conversation_users: { user_id: user.id })
      .where("messages.created_at > conversation_users.last_read_at")
      .select("messages.*, false AS read")
  end

  def self.with_read_status_for(user)
    joins("INNER JOIN conversation_users ON conversation_users.conversation_id = messages.conversation_id")
      .where(conversation_users: { user_id: user.id })
      .select("messages.*, (messages.created_at < conversation_users.last_read_at) AS read")
  end

  def self.created_after(timestamp)
    where("messages.created_at > ?", timestamp)
  end

  def self.created_before(timestamp)
    where("messages.created_at < ?",timestamp)
  end

  private

  def notify_cables
    NewMessageJob.perform_now(self)
  end

end
