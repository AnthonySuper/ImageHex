# frozen_string_literal: true
##
# A controller for actions relating to collections
class CollectionsController < ApplicationController
  before_action :ensure_user, except: [:index, :show]

  include Pundit

  ##
  # @collections: Collections belonging to the current user.
  def mine
    @collections = if t = params[:inspect_image]
                     img = Image.find(t)
                     current_user.collections.with_image_inclusion(img)
                   else
                     current_user.collections
                   end
    render 'index'
  end

  ##
  # "Browse collections" page.
  # @collections:: The collections displayed based on popularity or recency.
  def index
    image_scope = Image.for_content(content_pref)
    @collections = find_index_collections
      .includes(:images)
      .where(collection_images: {image_id: image_scope})
      .references(collection_images: :images)
      .paginate(page: page, per_page: per_page)
  end

  ##
  # Subscribes current_user to the collection with id in params[:id]
  # Requires login.
  # Redirects back afterwards.
  # If "redirect back" means nothing (IE, hitting the back button is impossible
  # since the user's first page in the session was this page), it redirects
  # to the homepage.
  def subscribe
    current_user.subscribe! Collection.find(params[:id])
    redirect_back fallback_location: root_path
  end

  ##
  # Unsubscribe from a collection
  # Member action
  def unsubscribe
    Subscription.where(collection_id: params[:id],
                       user_id: current_user.id)
      .first
      .try(:destroy)
    redirect_to Collection.find(params[:id])
  end

  ##
  # Show a collection, including all info and images within.
  # Sets the following varaibles:
  # @collection:: The collection being viewed
  # @curators:: the users who curate the collection
  # @images:: Images in the collection
  def show
    @collection = Collection.find(params[:id])
    @images = @collection.images
      .order("collection_images.created_at DESC")
      .paginate(page: page, per_page: per_page)
      .for_content(content_pref)
    @curators = @collection.curators
  end

  ##
  # Displays a page to create a new collection.
  # Requires login.
  # Sets the following variables:
  # @collection:: A new collection object for form-building.
  def new
    @collection = Collection.new
  end

  ##
  # POST to create a new collection
  # Redirects to the new action with errors in flash[:warning] on failure,
  # and to the created collection on success.
  def create
    c = Collection.new(collection_params)
    respond_to do |format|
      if c.save
        format.html { redirect_to collection_path(id: c.id), notice: I18n.t("notices.collection_created_successfully") }
      else
        format.html { redirect_to new_collection_path, warning: c.errors.full_messages.join(", ") }
      end
    end
  end

  ##
  # Edit a given collection.
  # @collection:: Collection being edited.
  def edit
    @collection = Collection.find(params[:id])
  end

  ##
  # Update a given collection.
  # @collection:: Collection being updated.
  def update
    @collection = Collection.find(params[:id])
    authorize @collection
    respond_to do |format|
      if @collection.update(collection_params)
        format.html { redirect_to @collection }
        format.json { render :show }
      else
        format.html { render :edit, status: :unproccessible_entity }
        format.json { render @collection.errors, status: :unprocessible_entity }
      end
    end
  end

  ##
  # Delete a given collection.
  # @collection:: Collection being deleted.
  def destroy
    @collection = Collection.find(params[:id])
    authorize @collection
    @collection.destroy
    redirect_to root_path
  end

  protected

  ##
  # Convenience method that finds collections for the "Browse Collections" page.
  # Sorted either by upload date or by popularity.
  def find_index_collections
    case params['order']
    when "created_at"
      Collection.order(created_at: :desc)
    else
      Collection.by_popularity(group_str: "collections.id, images.id")
    end
  end

  ##
  # Parameters needed to create the collection.
  # name:: What to name this collection
  # description:: A short bit of info describing this collection.
  def collection_params
    params.require(:collection)
      .permit(:name, :description)
      .merge(curators: [current_user])
  end
end
