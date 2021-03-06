# frozen_string_literal: true
##
# A user is exactly what it says on the tin: somebody who uses imagehex under a name.
# There are (curently) two types of users: an admin and a normal user.
# This distinction is stored as an enum.
# Admins have power over the entire site and can do basically anything.
# In order to prevent mishaps, you need direct database access to make a
# user an admin.
#
# == Relations
# collections:: collections the user curates. See Collection for more
#               information. All  users are created with a Favorites
#               collection and a Creations collection, which are special.
# subscriptions:: represents all the collections a user is
#                 subscribed to. Using user.image_feed will
#                 give a list of all images in
#                 all collections the user is subscribed to.
# notifications:: Anything the user needs to know. Using user.notifications
#                 .unread gives all
#                 unread notifications.
#
class User < ActiveRecord::Base
  # Use a friendly id to find by name
  extend FriendlyId
  friendly_id :name, use: :slugged

  # Role enum to track user status.
  # normal:: Default user, no special privileges.
  # admin:: Admin user with special privileges, e.g. ability to delete images,
  # comments, collections, etc.
  enum role: [:normal, :admin]

  # Attach the user's avatar to their user.
  # Image evaluated and split into separate styles by Paperclip.
  has_attached_file :avatar,
                    styles: {
                      original: "500x500>#",
                      medium: "300x300>#",
                      small: "200x200>#",
                      tiny: "100x100>#"
                    },
                    path: ($AVATAR_PATH ? $AVATAR_PATH : "avatars/:id_:style.:extension"),
                    default_url: "default-avatar.svg"

  # Validates that the avatar object is a valid image.
  validates_attachment_content_type :avatar,
                                    content_type: %r{\Aimage\/.*\Z}

  # Validates that the avatar object is no more than 2MB.
  validates_with AttachmentSizeValidator,
                 attributes: :avatar,
                 less_than: 2.megabytes

  ##
  # Join table: users -> collections
  has_many :listings

  has_many :conversation_users
  has_many :conversations,
           through: :conversation_users

  has_many :comments

  has_many :subscriptions
  has_many :subscribed_collections,
           through: :subscriptions,
           source: :collection

  has_many :favorites
  has_many :favorite_images, through: :favorites,
    class_name: "Image",
    source: :image

  has_many :image_reports
  has_many :notifications
  has_many :images

  has_many :curatorships
  has_many :collections, through: :curatorships

  has_many :notes

  has_many :user_creations
  has_many :creations, -> { order(created_at: :desc) }, through: :user_creations

  # ArtistSubscriber is a join table of User to User.
  # This is, as you imagine, kind of annoying to deal with.
  # So we split it up into two relationships
  # This is the first. It's the artists this user is subscribed to.
  has_many :artist_subscriptions, foreign_key: :user_id
  # and here we have the actual users
  has_many :subscribed_artists,
           through: :artist_subscriptions,
           source: :artist

  # now we have the artists subscribers.
  # this has many is for when the user is in the role of artist
  has_many :artist_subscribers,
           class_name: :ArtistSubscription,
           foreign_key: :artist_id

  # and here's a list of the users that are subscribed to us
  has_many :subscribers,
           through: :artist_subscribers,
           source: :user

  has_many :orders

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable

  # Two-factor Authenticatable
  devise :two_factor_authenticatable,
         otp_secret_encryption_key: ENV['TWO_FACTOR_KEY'],
         otp_allowed_drift: 0

  # Two-factor Backupable
  # Generates 10 backup codes of length 16 characters for the user.
  # For use if/when the user loses access to their two-factor device.
  devise :two_factor_backupable,
         otp_backup_code_length: 16,
         otp_number_of_backup_codes: 10

  attr_accessor :otp_backup_attempt

  ###############
  # VALIDATIONS #
  ###############

  validates :name, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A([[:alpha:]]|\w)+\z/ },
                   length: { in: 2..25 }
  validates :page_pref, inclusion: { in: (10..100) }

  #############
  # CALLBACKS #
  #############

  before_save :coerce_content_pref!
  before_validation :coerce_notifications_pref!

  #################
  # CLASS METHODS #
  #################

  def self.popular_creators(interval = 14.days.ago..Time.now)
    joins(creations: :collection_images)
      .group("users.id")
      .where(collection_images: { created_at: interval })
      .order("COUNT(collection_images) DESC")
  end

  def self.recent_creators
    joins(:creations)
      .group("users.id")
      .order("MAX(user_creations.created_at) DESC")
  end

  def self.search(query)
    q = all
    return q unless query
    q = q.with_similar_name(query[:name]) if query[:name]
    q = q.unblocked_by(query[:unblocked_by]) if query[:unblocked_by]
    q
  end

  def self.with_similar_name(name)
    where("name ILIKE ?", "#{name}%")
  end

  ##
  # Currently not implemented, will be soon
  def self.unblocked_by(user)
    id = case user
         when User
           user.id
         when Integer, String
           Integer(user)
         else
           fail ArgumentError, "need a user object or an id"
         end
    all
  end

  ####################
  # INSTANCE METHODS #
  ####################

  def should_generate_new_friendly_id?
    name_changed?
  end

  def admin?
    role == "admin"
  end

  def has_filled_commissions?
    count = listings
      .joins(:offers)
      .where(commission_offers: { filled: true })
      .count
    count > 0
  end

  # Enable Two-Factor Authentication
  # Generates the user's OTP Secret.
  def enable_twofactor
    self.otp_secret = User.generate_otp_secret
    save
  end

  # Confirm Two-Factor Authentication
  # If the user-provided key generated by their 2FA app from the QR code on the
  # 2FA setup screen is incorrect, do not allow them to continue. Otherwise,
  # enable 2FA, generate the backup codes, and then display them.
  def confirm_twofactor(key)
    return false unless validate_and_consume_otp!(key)
    self.otp_required_for_login = true
    self.two_factor_verified = true
    backup_codes = generate_otp_backup_codes!
    save
    backup_codes
  end

  ##
  # See if the user is subscribed to a collection
  # Returns true or false
  # c:: the collection we are checking
  def subscribed_to?(c)
    c.subscribers.include? self
  end

  ##
  # Quickly get a user avatar, pre-resized
  def avatar_img
    avatar.url(:medium)
  end

  ##
  # Get a user's avatar thumbnail, pre-resized
  def avatar_img_thumb
    avatar.url(:tiny)
  end

  ##
  # Get all images in all collections this user is subscribed to.
  def image_feed
    Image.feed_for(self)
  end

  def note_feed
    Note.feed_for(self)
  end

  ##
  # Add a collection to the user's subscriptions.
  # c:: The collection to add.
  def subscribe!(c)
    c.subscribers << self
  end
  
  ##
  # Remove a collection from the user's subscriptions.
  # c:: The collection to add.
  def unsubscribe!(c)
    c.subscribers.destroy(self)
  end

  def favorited?(img)
    self.favorite_images.include? img
  end

  
  ##
  # Add an image to a user's creationed collection.
  # i:: The image the use will be credit for creating.
  def created!(i)
    creations << i
  end

  ##
  # Get a user's curatorship on a collection, if it exists
  # c:: The collection requested.
  def curatorship_for(c)
    Curatorship.find_by(user: self, collection: c)
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  ## 
  # Security: We don't actually want as_json to be called on user
  # as it can leak private details. Just in case we call it on accident,
  # we force it to only include the id and the name.
  def as_json(options)
    super(only: [:name, :id])
  end

  protected

  ##
  # Rails passes the true and false values from checkboxes as "0" and "1".
  # This method converts them into the proper "true" or "false".
  def coerce_content_pref!
    return unless content_pref
    self.content_pref = content_pref.map do |k, v|
      next unless k.start_with?("nsfw")
      if v.is_a? String
        [k, v == "0" ? false : true]
      else
        [k, v]
      end
    end.to_h
  end

  def coerce_notifications_pref!
    return unless notifications_pref
    map = notifications_pref.map do |k, v|
      [k, !(v == "0")]
    end
    self.notifications_pref = Hash[map]
  end
end
