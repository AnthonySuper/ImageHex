class User < ActiveRecord::Base
  ##
  # Use a friendly id to find by name
  extend FriendlyId
  friendly_id :name, use: :slugged
  ################
  # ASSOCIATIONS #
  ################
  ##
  # Join table: users -> collections
  
  has_many :subscriptions
  has_many :subscribed_collections,
    through: :subscriptions,
    source: :collection

  has_many :images
  has_many :curatorships
  has_many :collections, through: :curatorships
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :confirmable

  ###############
  # VALIDATIONS #
  ###############
  validates :name, presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: /\w+/}
  validates :page_pref, inclusion: {:in => (1..100)}

  #############
  # CALLBACKS #
  #############
  after_create :make_collections


  ####################
  # INSTANCE METHODS #
  ####################
  def image_feed
    Image.where(id: subscribed_collections.joins(:collection_images).pluck(:image_id))
  end
  
  def subscribe! c
    c.subscribers << self
  end
  ## 
  # Convenience method to access the favorites collection for a user
  def favorites
    collections.favorites.first
  end
  ##
  # Add an image to a user's favorites
  def favorite! i
    favorites.images << i
  end


  ## 
  # Add an image to a user's creations
  def created! i
    creations.images << i
  end

  ##
  # Convenience method ot access the creations collection for a user
  def creations
    collections.creations.first
  end
  protected
  def make_collections
    Favorite.create!(users: [self])
    Creation.create!(users: [self])
  end
  enum role: [:normal, :admin]
end
