class OrdersController < ApplicationController
  include Pundit
  before_action :ensure_user
  before_action :load_listing, except: :mine

  def index
    if @listing.user != current_user
      raise Pundit::NotAuthorizedError
    end
    @orders = @listing.orders
  end

  def mine
    @orders = current_user.orders
  end

  def show
    @order = @listing.orders.find(params[:id])
  end

  def edit
    @order = @listing.orders.find(params[:id])
    authorize @order
  end

  def purchase
    @order = @listing.orders.find(params[:id])
    authorize @order
    OrderChargeService.new(@order, params[:stripeToken]).perform
    redirect_to [@listing, @order]
  end

  def fill
    @order = @listing.orders.find(params[:id])
    authorize @order
    respond_to do |format|
      if @order.fill(Image.find(params[:image_id]))
        format.html { redirect_to [@listing, @order] }
        format.json { render 'show' }
      else
        format.html { render 'show', errors: @order.errors }
        format.json { render json: @order.errors, status: 401 }
      end
    end
  end

  def accept
    @order = @listing.orders.find(params[:id])
    authorize @order
    result = @order.accept(params)
    respond_to do |format|
      if result
        format.html { redirect_to [@listing, @order] }
        format.json { render json: {success: true} }
      else
        format.html do
          edirect_to [@listing, @order], notice: "Could not confirm"
        end
        format.json { render json: {success: false} }
      end
    end
  end


  def new
    @order = @listing.orders.build(user: current_user)
    authorize @order
  end

  def update
    @order = Order.find(params[:id])
    authorize @order
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to [@listing, @order] }
        format.json { render 'show' }
      else
        format.html { render 'edit' }
        format.json { render json: @order.errors, status: 401 }
      end
    end
  end

  def confirm
    @order = Order.find(params[:id])
    authorize @order
    result = @order.confirm
    respond_to do |format|
      if result
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
    @order = @listing.orders.build(order_params)
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

  def reject
    @order = @listing.orders.find(params[:id])
    authorize @order
    respond_to do |format|
      if @order.reject
        format.html do 
          redirect_to [@listing, @order],
            notice: "Order rejected"
        end
        format.json { render 'show' }
      else
        format.html do 
          redirect_to [@listing, @order], 
            warning: "rejection failed"
        end
        format.json { render json: @order.errors, status: 401 }
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
              :name,
              groups_attributes: [group_params])
      .merge(user: current_user)
  end

  def group_params
    [:description,
     :id,
      :_destroy,
      tag_ids: [],
      images_attributes: [image_params]]
  end

  def image_params
    [:description,
      :name,
      :img,
      :id,
      :_destroy]
  end
end
