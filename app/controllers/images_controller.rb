class ImagesController < ApplicationController
  # Load the image via our id
  before_action :load_image, only: [:update, :edit, :destroy, :show]
  # Ensure a user is logged in. Defined in the application controller
  before_action :ensure_user, only: [:new, :create, :update, :edit, :destroy]

  def search
    groups = params[:query].map{|x| TagGroup.by_tag_names x}
    @images = Image.from_groups groups
  end
  
  def new
    @image = Image.new
  end

  def report
    @report = Report.new(report_params)
  end
  def create
    @image = Image.new(image_params)
    if @image.save
      redirect_to @image
    else
      # If their image is incorrect, redirect_to the new page again.
      flash[:warning] = @image.errors.full_messages.join(', ')
      redirect_to action: :new
    end
  end

  def update
  end

  def edit
  end

  def destroy
  end

  def index
    puts params
    @images = Image.paginate(page: page, per_page: per_page).order('created_at DESC')
  end

  def show
    @image = Image.find(params[:id])
  end
  protected
  # Load the image with the current id into params[:image]
  def load_image
    @image = Image.find(params[:id])
  end
  def image_params
    params.require(:image)
    .permit(:f, :license, :medium) # Attributes the user adds
    .merge(user_id: current_user.id) # We add the user id
  end

  ##
  # Parameters for our report
  def report_params
    params.require(:report)
      .permit(:severity, :message)
      .merge(user_id: current_user.id, image_id: params[:id])
  end

end
