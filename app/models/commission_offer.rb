class CommissionOffer < ActiveRecord::Base
  belongs_to :commission_product
  belongs_to :user
  has_many :subjects, class_name: "CommissionSubject",
    inverse_of: :commission_offer
  has_many :backgrounds, class_name: "CommissionBackground",
    inverse_of: :commission_offer

  has_many :commission_images
  has_many :images, through: :commission_images

  accepts_nested_attributes_for :subjects
  accepts_nested_attributes_for :backgrounds

  validates :user, presence: true
  validates :commission_product, presence: true

  validate :has_acceptable_subject_count
  validate :background_is_acceptable
  validate :not_offering_to_self

  has_one :conversation

  before_save :calculate_price

  def calculate_fee
    if offeree.has_filled_commissions?
      (total_price * 0.12).floor + 0.30
    else
      0
    end
  end

  def has_background?
    backgrounds.length > 0 
  end

  def offeree
    commission_product.user
  end

  def has_subjects?
    subjects.length > 0
  end

  def offeree_name
    offeree.name
  end

  def involves?(u)
    offeree == u || self.user == u
  end

  def confirm!
    transaction do 
      self.confirmed = true
      self.touch(:confirmed_at)
      self.save
      Notification.create(user: offeree,
                          subject: self,
                          kind: :commission_offer_confirmed)
      Conversation.create(commission_offer: self,
                          users: [user,
                            offeree])
    end
  end

  def accept!
    return false unless confirmed?
    transaction do
      self.accepted = true
      self.touch(:accepted_at)
      self.save
      Notification.create(user: self.user,
                          subject: self,
                          kind: :commission_offer_accepted)
    end
  end

  ##
  # Don't do this in a transaction because we'd rather not notify and make
  # the charge than do neither
  def charge!(stripe_charge_id)
    time_due = commission_product.weeks_to_completion.weeks.from_now
    self.update(stripe_charge_id: stripe_charge_id,
                charged: true,
                charged_at: Time.now,
                due_at: time_due)
    Notification.create(user: offeree,
                        subject: self,
                        kind: :commission_offer_charged)
  end

  def fill!(image)
    self.class.transaction do 
      self.images << image
      Notification.create(user: user,
                          kind: :commission_offer_filled,
                          subject: self)
      self.update(filled_at: Time.now,
                  filled: true)
    end
  end

  protected
  def not_offering_to_self
    if user_id == commission_product.try(:user_id)
      errors.add('user', "cannot offer to yourself!")
    end
  end
  def background_is_acceptable
    return unless commission_product
    if has_background? && ! commission_product.allow_background?
      errors.add(:backgrounds, "have too many")
    end
  end

  def has_acceptable_subject_count
    return unless commission_product
    if (s = commission_product.try(:maximum_subjects)) && subjects.size > s
      errors.add(:subjects, "have more than this product's maximum")
    end
    unless commission_product.allow_further_subjects?
      if subjects.size > commission_product.included_subjects
        errors.add(:subject, "have too many")
      end
    end
  end

  def calculate_price
    p = commission_product
    i = p.base_price
    subject_charge_count = subjects.size - p.included_subjects
    i += p.subject_price * subject_charge_count if subject_charge_count > 0
    if has_background? && p.charge_for_background? 
      i += p.background_price
    end
    self.total_price = i 
  end
end