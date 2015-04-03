##
# A user is exactly what it says on the tin: somebody who uses imagehex under a name.
# There are (curently) two types of users: an admin and a normal user.
# This distinction is stored as an enum.
# Admins have power over the entire site and can do basically anything.
# In order to prevent mishaps, you need direct database access to make a
# user an admin.
# 
# User names must match the regex /w+/, so they only allow A-Z,a-z, and _. 
# User names must be unique. "Aa" is considered the same name as "aA".
#
# Users have a few relations:
#   * Every user is created with a "favorites" collection and a "creations"
#     collection. These collections represent things the user has favorite,
#     and things they've made themselves.
#   * A "subscriptions" relationship represents all the collections a user is
#     subscribed to. Using user.image_feed will give a list of all images in
#     that collection.
#   * Users have notifications. Using user.notifications.unread gives all
#     unread notifications.
#

class User < ActiveRecord::Base
  # Use a friendly id to find by name
  extend FriendlyId
  friendly_id :name, use: :slugged

  enum role: [:normal, :admin]
  ################
  # ASSOCIATIONS #
  ################
  has_one :user_page, autosave: true
    # Accept nested attributes for the page
  accepts_nested_attributes_for :user_page, update_only: true
 
  ##
  # ID of the avatar is in avatar_id.
  belongs_to :avatar, class_name: "Image"
  ##
  # Join table: users -> collections
  has_many :subscriptions
  has_many :subscribed_collections,
    through: :subscriptions,
    source: :collection

  has_many :notifications
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
  validates_associated :user_page
  #############
  # CALLBACKS #
  #############
  after_create :make_collections
  before_create :make_page
  before_validation :resolve_page_body
  after_initialize :load_page_body
  ##############
  # ATTRIBUTES #
  ##############
  attr_accessor :page_body
  ####################
  # INSTANCE METHODS #
  ####################
  
  def avatar_img
    avatar.f(:medium)
  end
  ##
  # Get all images in all collections this user is subscribed to.
  def image_feed
    Image.feed_for(self)
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

  def favorited?(image)
    favorites.images.include? image
  end

  ##
  # Add an image to a user's creationed collection.
  def created! i
    creations.images << i
  end

  ##
  # Convenience method ot access the creations collection for a user
  def creations
    collections.creations.first
  end
  protected

  def load_page_body
    page_body = self.user_page.body if self.user_page
  end

  def make_page
    build_user_page(body: I18n.t(".user_hasn't_made_a_page", username: "@#{name}" ) )
  end

  def resolve_page_body
    return unless page_body
    user_page.body = page_body
    user_page.save
  end
  ##
  # All users have to have a Favorite collection and a Created collection.
  # This method makes both of those collections in a callback on user creation.
  def make_collections
    Favorite.create!(curators: [self])
    Creation.create!(curators: [self])
  end

end
