class ConversationUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :conversation
  validates :user, presence: true
  validates :conversation, presence: true
  validate :user_is_involved_in_commission,
    :if => :conversation_for_offer?
  before_create :set_initial_read_date

  def conversation_for_offer?
    conversation.for_offer?
  end

  def user_is_involved_in_commission
    unless conversation.commission_offer.involves?(user)
      errors.add(:base, "Not involved with that user")
    end
  end

  protected
  def set_initial_read_date
    self.last_read_at = Time.now
  end
end