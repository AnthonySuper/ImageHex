class OrdersController < ApplicationController
  include Pundit
  before_action :ensure_user
  before_action :load_listing

  def index
    @orders = @listing.orders  
  end

  def new
    @order = @listing.orders.build(user: current_user)
    authorize @order
  end

  def confirm
    @order = Order.find(params[:id])
    authorize @order
    respond_to do |format|
      if @order.update(confirmed: true)
        format.html { redirect_to [@listing, @order], notice: "Confirmed" }
        format.json { render json: {success: true} }
      else
        format.html do 
          redirect_to [@listing, @order], warning: "Couldn't confirm!"
        end
        format.json { render json: {success: false} }
      end
    end
  end

  def create
    @order = @listing.orders.build(user: current_user)
    authorize @order
    respond_to do |format|
      if @order.save
        format.html { redirect_to [@listing, @order] }
        format.json { render 'show' }
      else
        format.html { render 'edit' }
        format.json { render json: @order.errors, status: 422 }
      end
    end
  end


  protected
  def load_listing
    @listing = Listing.find(params[:listing_id])
  end

  def order_params
    params.require(:order)
      .permit(:description,
              option_attributes: [option_params],
              reference_attributes: [reference_params])
              
  end

  def option_params
    [:listing_option_id,
      :id,
      :_destroy]
  end

  def reference_params
    [:description,
      image_attributes: [reference_image_params]]
  end

  def reference_image_params
    [:description,
      :img,
      :id,
      :_destroy]
  end
end
