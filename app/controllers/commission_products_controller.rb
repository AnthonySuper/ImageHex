class CommissionProductsController < ApplicationController
  include Pundit
  after_action :verify_authorized, except: [:index, :show]
  before_action :ensure_user, except: [:index, :show]

  def new
    @product = CommissionProduct.new
    authorize(@product)
  end

  def show
    @product = CommissionProduct.find(params[:id])
  end

  def create
    @product = CommissionProduct.new(commission_product_params)
    authorize @product
    respond_to do |format|
      if @product.save
        format.html {redirect_to @product}
        format.json {render action: 'show'}
      else
        format.html {render 'new'}
        format.json {render json: @product.errors, status: 422}
      end
    end
  end

  protected

  def commission_product_params
    params.require(:commission_product)
      .permit(:name,
              :description,
              :base_price,
              :included_subjects,
              :subject_price,
              :include_background,
              :background_price,
              :offer_background,
              :offer_subjects,
              :maximum_subjects,
              :weeks_to_completion)
      .merge(user_id: current_user.id)
  end
end
