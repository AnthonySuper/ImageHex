# frozen_string_literal: true
##
# Collection is a way to organize images outside of the content within.
# An example of this might be all images that happened at a particular place
# in time, all images which have subjective quality in the opinion of a user
# (something like "beautiful"), or all the pages of a comic.
#
# It is an abstract class that uses STI to implement different functionality
# on child classes.
#
# == Relationships
# subscribers:: All users subscribed to this collection. Related via the join
#               table subscriptions.
# curators:: All the users who curate this collection. There's different levels
# images:: All images in this collection. Join table'd via collection_images.
#
# == Scopes
# favorites:: All collections of the Favorite variety.
class Collection < ActiveRecord::Base
  ################
  # ASSOCIATIONS #
  ################

  # Join table: User -> Collection
  has_many :subscriptions
  has_many :subscribers, through: :subscriptions, source: :user
  # Join table: User -> Collection
  has_many :curatorships
  has_many :curators, through: :curatorships, source: :user
  # Join table: Collection -> Images
  has_many :collection_images
  has_many :images,
           through: :collection_images

  ###############
  # VALIDATIONS #
  ###############

  validates :name, presence: true

  after_create :make_admins

  ##########
  # SCOPES #
  ##########

  ##
  # Get a list of collections ordered by how popular they are, in terms of
  # subscribers.
  def self.by_popularity(inter = 2.weeks.ago..Time.now, 
                         group_str: "collections.id")
    subs = Subscription.arel_table
    col = arel_table
    j = col.join(subs, Arel::Nodes::OuterJoin)
      .on(subs[:collection_id].eq(col[:id]), subs[:created_at].between(inter))
      .join_sources
    res = joins(j)
      .group(group_str)
      .order("COUNT(subscriptions) DESC")
  end

  ##
  # Get this scope, but with an additional column representing if this
  # collection contains the passed image
  # @param [Image] i the image
  def self.with_image_inclusion(i)
    ##
    # Using string interpolation is SQL is scary.
    # However, we force it to be an integer first, so it's less scary.
    select(%{
      collections.*, (collections.id IN
        (SELECT collections.id FROM collections
        INNER JOIN collection_images
          ON collection_images.collection_id = collections.id
        WHERE collection_images.image_id = #{i.id.to_i}))
        AS contains_image})
  end

  def self.without_image(i)
    where.not(id: i.collections)
  end

  def self.with_image(i)
    where(id: i.collections)
  end

  ####################
  # INSTANCE METHODS #
  ####################

  ##
  # Does a user curate this collection?
  # +u+:: the user
  # Example usage:
  #   collection.curated?(User.first) #=> true
  #   collection.curate?(User.last) #=> false
  def curated?(u)
    curators.include?(u)
  end

  protected

  def make_admins
    curatorships.update_all(level: 2)
  end
end
