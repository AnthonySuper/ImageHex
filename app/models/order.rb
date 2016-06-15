class Order < ActiveRecord::Base
  belongs_to :listing
  belongs_to :user

  belongs_to :image,
    required: false

  has_many :order_options,
    class_name: "Order::Option",
    inverse_of: :order

  has_many :options,
    class_name: "Listing::Option",
    through: :order_options

  has_many :references,
    class_name: "Order::Reference",
    inverse_of: :order

  has_one :conversation

  accepts_nested_attributes_for :references

  validates :user, presence: true
  validates :listing, presence: true
  validates :final_price,
    presence: true,
    :if => :accepted?

  validate :not_order_to_self
  validate :order_has_references
  validate :image_is_eligable

  before_validation :calculate_final_price, if: :final_price_needs_calculation?

  after_save :create_conversation, if: :needs_conversation_creation

  def references_by_category
    h = Hash.new{|hash, key| hash[key] = []}
    self.references.each do |ref|
      h[ref.category] << ref
    end
    h
  end

  def calculated_final_price
    raise "Cannot calculate quote price" if self.listing.quote_only?
    self.listing.base_price + options_price + references_price
  end

  private

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
    if references.blank?
      errors.add(:references, "need at least 1")
    end
  end

  def not_order_to_self
    unless user != listing.user
      errors.add(:user, "created this listing")
    end
  end

  def calculate_final_price
    return unless final_price_needs_calculation?
    self.final_price = calculated_final_price
  end

  def final_price_needs_calculation?
    (self.confirmed? &&
     ! self.listing.quote_only &&
     self.final_price.nil?)
  end

  def options_price
    (options.map(&:price).reduce(:+) || 0)
  end

  def references_price
    (references_by_category.map do |val|
      category, refs = val
      paid_count = (refs.count - category.free_count)
      if paid_count > 0 then
        paid_count * category.price
      else
        0
      end
    end.reduce(:+) || 0)
  end
end
