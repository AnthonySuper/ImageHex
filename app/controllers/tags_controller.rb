##
# A single-action controller used for tag suggestion.
class TagsController < ApplicationController
  include TrainTrack
  before_action :ensure_user, only: [:edit, :update]
  ##
  # Given a partial tag name in "params['name']", suggests ten possible
  # completed tags in alphabetical order.
  # Renders a JSON data type.
  def suggest
    if params["name"]
      suggestions = Tag.suggest(params["name"].downcase)
      render json: suggestions
    else
      render status: 422, body: nil
    end
  end

  ##
  # Show a page with info about the tags
  def show
    @tag = Tag.friendly.find(params[:id])
    @neighbors = @tag.neighbors.limit(10)
    @images = @tag.images
      .paginate(page: page, per_page: per_page)
      .for_content(content_pref)
  end

  ##
  # Get a list of all tags
  # Maybe somebody will find this usefull?
  def index
    @tags = Tag.all.paginate(page: page, per_page: per_page)
  end

  def new
    @tag = Tag.new
  end

  def create
    @tag = Tag.new(tag_params)
    respond_to do |format|
      if @tag.save
        track @tag
        format.html { redirect_to @tag }
        format.json { render 'show' }
      else
        format.html { render 'edit' }
        format.json { render json: @tag.errors, status: :unproccessible_entity }
      end
    end
  end

  ##
  # Edit this tag's description
  # We really should admin-restrict this at some point
  def edit
    @tag = Tag.friendly.find(params[:id])
  end

  ##
  # Update a tag's description
  # Should be admin-restricted at some point
  def update
    tag = Tag.friendly.find(params[:id])
    track tag
    if tag.update(tag_params)
      track tag
      redirect_to tag
    else
      flash[:warning] = tag.errors.full_messages
      redirect_to action: :edit
    end
  end

  protected

  ##
  # Paramters.
  #
  # Of format:
  #     tag:
  #         description
  def tag_params
    params.require(:tag).permit(:description,
      :importance,
      :name)
  end
end
