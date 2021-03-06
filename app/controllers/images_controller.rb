# frozen_string_literal: true
##
# As the name implies, this contorller handles all actions for images.
class ImagesController < ApplicationController

  include Pundit
  rescue_from Pundit::NotAuthorizedError, with: :unauthorized
  # Load the image via our id
  before_action :load_image, 
    only: [:comment, 
      :created, 
      :update, 
      :edit, 
      :destroy, 
      :show]
  # Ensure a user is logged in. Defined in the application controller
  before_action :ensure_user, 
    except: [:index, 
      :show, 
      :search, 
      :comments]

  ##
  # Create a new comment on the image in params[:id]
  # Redirects to the image if the comment is invalid.
  # Must be a POST request.
  # User must be logged in.
  # @comment:: The comment being submitted.
  def comment
    @comment = Comment.new(comment_params)
    respond_to do |format|
      if @comment.save
        format.html do 
          redirect_to @image, 
            notice: I18n.t("notices.your_comment_was_submitted_successfully")
        end
      else
        format.html do 
          redirect_to @image, 
            warning: @comment.errors.full_messages.join(', ')
        end
      end
    end
  end

  def comments
    @comments = Image.find(params[:id]).comments
      .includes(:user)
      .paginate(page: page, per_page: 20)
    case params[:sort]
    when "desc"
      @comments = @comments.order(created_at: :desc)
    else
      @comments = @comments.order(:created_at)
    end
  end

  ##
  # The current user adds the image to his "Created" collection,
  # which means he or she was involved in the creation of the image.
  # Image must be in params[:id]. User must be logged in.
  # @image:: Image being created.
  def created
    authorize @image
    current_user.created! @image
    redirect_to(@image)
  end

  ##
  # Find images via the Image#search method.
  # Query should be in params[:query].
  # @query:: The search term input by the user.
  # @images:: The images the recieved in response to the query.
  def search
    @query = SearchQuery.new(params)
    @images = Image.search(@query)
      .order(created_at: :desc)
      .paginate(page: page, per_page: per_page)
      .for_content(content_pref)
    respond_to do |format|
      format.html
      format.json { render 'index' }
    end
  end

  ##
  # Page to begin uploading a new image.
  # User must be logged in.
  # Sets the following variables:
  # @image:: A new image object, used to build the form.
  def new
    @image = Image.new(created_by_uploader: true)
  end

  ##
  # Report an image that is unsuitable for ImageHex.
  # Image should be in params[:id]. User must be logged in.
  # @image:: The image being reported.
  # @report:: A new report object created for submission by the user.
  def report
    @image = Image.find(params[:id])
    @report = ImageReport.new(report_params)
    respond_to do |format|
      if @report.save
        format.html do
          redirect_to @image, 
            notice: I18n.t("notices.report_submitted_thank_you")
        end
      else
        format.html do
          redirect_to @image, 
            warning: @report.errors.full_messages.join(", ")
        end
      end
    end
  end

  ##
  # POST to create a new image. User must be logged in.
  #
  # If image is invalid, will redirect to the new action with errors set in
  # flash[:warning].
  # @image:: An image object being created.
  def create
    @image = Image.new(image_params)
    respond_to do |format|
      if @image.save
        format.html do
          redirect_to @image, 
            notice: I18n.t("notices.image_uploaded_successfully")
        end
        format.json { render :show }
      else
        # If their image is incorrect, redirect_to the new page again.
        format.html do 
          redirect_to new_image_path, 
            warning: @image.errors.full_messages.join(', ')
        end
      end
    end
  end

  ##
  # Modify an uploaded image with a PUT.
  # @image:: The image being updated.
  def update
    authorize @image
    @image.update(image_update_params)
    redirect_to @image
  end

  ##
  # GET to acquire a page where you can edit an image.
  # Does nothing currently.
  # TODO: Make an Edit Image page.
  def edit
    authorize @image
  end

  ##
  # DELETE to remove an image.
  # @image:: The image being deleted.
  def destroy
    @image = Image.find(params[:id])
    authorize @image
    @image.destroy
    redirect_to action: :index
  end

  ##
  # Obtain all images, in order of uploading.
  # Paginated according to user preferences.
  # Sets the following varaibles:
  # @images:: the paginated list of images.
  def index
    @images = Image.browse(params)
      .for_content(content_pref)
      .paginate(page: page, per_page: per_page)
  end


  def feed
    @images = Image.feed_for(current_user)
      .limit(30)
    if params[:fetch_after]
      time = Time.at(params[:fetch_after].to_f)
      @images = @images.where("sort_created_at < ?", time)
    end
  end

  ##
  # Show a image.
  # Sets the following variables:
  # @image:: The image being shown
  # @groups:: Tag groups on the image. Should be refactored out at some point.
  def show
    @favorite = if user_signed_in?
                  current_user.favorites.where(image_id: @image.id).first
                else
                  nil
                end

    @groups = TagGroup.where(image: @image).includes(:tags)
    @collections = current_user.try(:collections)
  end

  protected

  # Load the image with params[:id] into @image.
  # FIXME: Should be refactored out.
  def load_image
    @image = Image.find(params[:id])
  end

  def image_update_params
    params.require(:image)
      .permit(:license,
              :medium,
              :replies_to_inbox,
              :description)
  end

  ##
  # Protected parameters for the image.
  def image_params
    params.require(:image)
      .permit(:f,
              :license,
              :medium,
              :replies_to_inbox,
              :source,
              :description,
              :nsfw_gore,
              :nsfw_nudity,
              :nsfw_sexuality,
              :nsfw_language,
              :created_by_uploader) # stuff the user adds
      .merge(user_id: current_user.id) # We add the user id
  end

  ##
  # Parameters for our report
  def report_params
    params.require(:report)
      .permit(:reason, :message)
      .merge(user_id: current_user.id)
      .merge(image_id: params[:id])
  end

  ##
  # Parameters for a comment
  def comment_params
    params.require(:comment)
      .permit(:body)
      .merge(user_id: current_user.id)
      .merge(commentable: @image)
  end
end
