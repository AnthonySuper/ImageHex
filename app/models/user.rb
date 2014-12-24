class User < ActiveRecord::Base
  ################
  # ASSOCIATIONS #
  ################
  has_many :images
  has_many :collections 
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :confirmable

  ###############
  # VALIDATIONS #
  ###############
  validates :name, presence: true,  uniqueness: {case_sensitive: false}
  validates :page_pref, inclusion: {:in => (1..100)}

  #############
  # CALLBACKS #
  #############
  after_create :make_collections


  ####################
  # INSTANCE METHODS #
  ####################

  ##
  # The collection that holds our favorites
  def favorites_collection
  end
  ##
  # Add an image to a user's favorites
  def favorite! i
  end

  ##
  # All the images in a user's favorites collection
  def favorites
  end

  ##
  # The collection that holds all images our user has created
  def creations_collection
  end

  ## 
  # Add an image to a user's creations
  def created! i
  end

  def creations
  end
  protected
  def make_collections
    Favorite.create!(user: self)
    Creation.create!(user: self)
  end
  enum role: [:normal, :admin]
end
