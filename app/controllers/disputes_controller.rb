# frozen_string_literal: true
class DisputesController < ApplicationController
  include Pundit
  before_action :ensure_user

  def index
    @disputes = policy_scope(Dispute.unresolved)
  end

  def show
    @dispute = Dispute.find(params[:id])
    authorize @dispute
  end

  def new
    @dispute = Dispute.new(attrs)
    authorize @dispute
  end

  def create
    @dispute = Dispute.new(dispute_params)
    authorize @dispute
    respond_to do |format|
      if @dispute.save
        format.html { redirect_to @dispute }
        format.json { render 'show' }
      else
        format.html { render 'edit' }
        format.json do
          render json: @dispute.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  protected

  def dispute_params
    params.require(:dispute)
      .permit(:description,
              :commission_offer_id)
  end
end
