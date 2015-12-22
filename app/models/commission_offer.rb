class CommissionOffer < ActiveRecord::Base
  belongs_to :commission_product
  belongs_to :user
  has_many :subjects, class_name: "CommissionSubject",
    inverse_of: :commission_offer
  has_many :backgrounds, class_name: "CommissionBackground",
    inverse_of: :commission_offer
  accepts_nested_attributes_for :subjects
  accepts_nested_attributes_for :backgrounds

  validates :user, presence: true
  validates :commission_product, presence: true

  validate :has_acceptable_subject_count
  validate :background_is_acceptable
  validate :not_offering_to_self

  before_save :calculate_price

  def has_background?
    backgrounds.length > 0 
  end

  def has_subjects?
    subjects.length > 0
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