class CommissionOfferPolicy < ApplicationPolicy
  def initialize(user, offer)
    @user = user
    @offer = offer
  end

  def new?
    not_offering_self?
  end

  def create?
    not_offering_self?
  end

  def show?
    if @offer.finalized?
      owner? || offeree?
    else
      owner?
    end
  end

  protected
  def owner?
    @offer.user == @user
  end

  def offeree? 
    @offer.commission_product.user == @user
  end

  def not_offering_self?
    @offer.commission_product.user != @user
  end
end