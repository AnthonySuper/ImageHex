class Order < ActiveRecord::Base
  belongs_to :listing

  belongs_to :user

  belongs_to :image,
    required: false

  has_many :groups,
    class_name: "Order::Group",
    inverse_of: :order
  
  has_many :reference_images,
    class_name: "Order::Group::Image",
    through: :groups,
    source: :images

  has_one :conversation

  accepts_nested_attributes_for :groups,
    allow_destroy: true

  validates :user, presence: true

  validates :listing, presence: true

  validates :final_price,
    presence: true,
    :if => :accepted?

  validate :not_order_to_self

  validate :order_has_references

  validate :image_is_eligable

  after_save :create_conversation, 
    :if => :needs_conversation_creation

  ##########
  # SCOPES #
  ##########

  def self.to_user(user)
    joins(listing: :user)
      .references(listing: :user)
      .where(listings: {user_id: user})
  end

  def self.unfilled
    where(image_id: nil)
  end

  def self.confirmed
    where(confirmed: true)
  end

  def self.unrejected
    where(rejected: false)
  end

  def self.active
    confirmed.unrejected.unfilled
  end

  ####################
  # INSTANCE METHODS #
  ####################


  def filled?
    ! image.nil?
  end

  def fill(img)
    fail TypeError, "That's not an image" unless img.is_a? Image
    self.class.transaction do 
      update!(image: img,
              filled_at: Time.zone.now)
      Notification.create(user: self.user,
                          kind: :order_filled,
                          subject: self)
    end
  end

  def accept(params)
    attrs = {
      accepted: true,
      accepted_at: Time.current
    }
    attrs[:final_price] = params[:quote_price]
    result = true
    begin
      Order.transaction do
        self.update!(attrs)
        notify_acceptance!
      end
    rescue ActiveRecord::RecordInvalid
      result = false
    end
    result
  end

  def confirm
    result = true
    begin
      Order.transaction do 
        update(confirmed: true,
               confirmed_at: Time.current)
        notify_confirmation!
      end
    rescue ActiveRecord::RecordInvalid
      result = false
    end
    result
  end

  def reject
    result = true
    begin
      Order.transaction do
        update!(rejected: true,
                rejected_at: Time.current)
        notify_rejection!
      end
    rescue ActiveRecord::RecordInvalid
      result = false
    end
    result
  end

  private

  def notify_acceptance!
    Notification.create!(kind: :order_accepted,
                         user: self.user,
                         subject: self)
  end

  def notify_confirmation!
    Notification.create!(kind: :order_confirmed,
                         user: self.listing.user,
                         subject: self)
  end

  def notify_rejection!
    Notification.create!(kind: :order_rejected,
                         user: self.user,
                         subject: self)
  end

  def needs_conversation_creation
    self.conversation.nil? && self.confirmed?
  end

  def create_conversation
    Conversation.create(name: "Order Conversation",
                        users: [self.user, self.listing.user],
                        order: self)
  end

  def image_is_eligable
    return unless self.image
    unless self.image.created_at > self.charged_at
      errors.add(:image,
                 "was created before this order was charged")
    end
  end

  def order_has_references
    if groups.blank?
      errors.add(:groups, "need at least 1")
    end
  end

  def not_order_to_self
    unless user != listing.user
      errors.add(:user, "created this listing")
    end
  end
end
