class Listing < ActiveRecord::Base

  # RELATIONS
  belongs_to :user, required: true

  has_many :listing_images,
    class_name: 'Listing::Image',
    inverse_of: :listing

  has_many :images, 
    through: :listing_images,
    class_name: "::Image"

  has_many :orders

  # VALIDATION
  validates :name,
    presence: true

  validates :description,
    presence: true


  # SCOPES
  scope :open, -> { where(open: true) }

  def self.with_average_prices
    listings = Listing.arel_table
    orders = Order.arel_table
    join = listings.join(orders, Arel::Nodes::OuterJoin)
      .on(orders[:listing_id].eq(listings[:id]))
      .join_sources
    self.joins(join)
      .group("listings.id")
      .select("listings.*, AVG(orders.final_price) AS average_price")
  end

  def completely_safe?
    ! (nsfw_gore? || nsfw_nudity? || nsfw_language? || nsfw_sexuality?)
  end


  def make_open!
    update(open: true)
  end

  def make_closed!
    update(open: false)
  end

  def closed?
    ! open?
  end
end

require_dependency 'listing/image'
