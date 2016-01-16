class CommissionOffersController < ApplicationController
  include Pundit
  after_action :verify_authorized
  before_action :ensure_user
  def index
  end

  def fullfill
    @offer = CommissionOffer.find(params[:id])
    authorize @offer
  end

  def fill
    @offer = CommissionOffer.find(params[:id])
    authorize @offer
    @image = Image.find(params[:image_id])
    fail Pundit::NotAuthorizedError.new unless @image.created_by? current_user
    respond_to do |format|
      if @offer.fill!(@image)
        format.html { redirect_to @offer, notice: "Created successfully" }
        format.json { render json: true }
      else
        format.html { render 'fullfill', notice: "Something broke ;-;" }
        format.json { render json: false, status: :unprocessible_entity }
      end
    end
  end

  def pay
    @offer = CommissionOffer.find(params[:id])
    authorize @offer
  end

  def charge
    @offer = CommissionOffer.find(params[:id])
    authorize @offer
    begin
      token = params[:stripeToken]
      fee = @offer.calculate_fee
      logger.info("Created a charge of #{@offer.total_price} with fee #{fee}")
      charge = Stripe::Charge.create(amount: @offer.total_price,
                                     currency: "usd",
                                     source: token,
                                     description: "Commission Payment",
                                     application_fee: fee,
                                     destination: @offer.offeree.stripe_user_id)
      @offer.charge!(charge.id)
      redirect_to @offer, notice: "Charge created!"
    rescue Stripe::CardError => e
      @error = e
      render
    end
  end

  def confirm
    @offer = CommissionOffer.find(params[:id])
    authorize @offer
    respond_to do |format|
      if @offer.confirm!
        format.html { redirect_to @offer, notice: "confirmed!" }
        format.json { render json: true }
      else
        format.html { redirect_to @offer, notice: "Something went wrong" }
        format.json { render json: false }
      end
    end
  end

  def accept
    @offer = CommissionOffer.find(params[:id])
    authorize @offer
    respond_to do |format|
      if @offer.accept!
        format.html { redirect_to @offer, notice: "Accepted!" }
        format.json { render json: true }
      else
        format.html { redirect_to @offer, notice: "Something went wrong" }
        format.json { render json: false }
      end
    end
  end

  def show
    @offer = CommissionOffer.find(params[:id])
    authorize @offer
  end

  def new
    @offer = if id = params["commission_product_id"]
               CommissionOffer.new(commission_product_id: id)
             else
               CommissionOffer.new
    end
    authorize @offer
  end

  def create
    @offer = CommissionOffer.new(commission_offer_params)
    authorize @offer
    respond_to do |format|
      if @offer.save
        format.html { redirect_to @offer }
        format.json { render 'show' }
      else
        format.html { render 'new' }
        format.json { render json: @offer.errors, status: :unprocessible_entity }
      end
    end
  end

  def edit
    @offer = CommissionOffer.find(params[:id])
    authorize @offer
  end

  def update
    @offer = CommissionOffer.find(params[:id])
    authorize @offer
    respond_to do |format|
      if @offer.update(commission_offer_params)
        format.html { redirect_to @offer }
        format.json { render 'show' }
      else
        format.html { render 'edit' }
        format.json { render @offer.errors, status: :unproccessible_entity }
      end
    end
  end

  protected

  def commission_offer_params
    params.require(:commission_offer)
      .permit(:description,
        :commission_product_id,
        subjects_attributes: [:description,
                              :id,
                              :_destroy,
                              { tag_ids: [] },
                              { references_attributes: [:file, :id, :_destroy] }],
        background_attributes: [:description,
                                :id,
                                :_destroy,
                                { references_attributes: [:file, :id, :_destroy] }])
      .merge(user_id: current_user.id)
  end
end
