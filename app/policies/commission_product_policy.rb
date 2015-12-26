class CommissionProductPolicy < ApplicationPolicy
  def initialize(user, product)
    @user = user
    @product = product
  end

  def create?
    verified_user_info?
  end

  protected
  def verified_user_info?
    @user.stripe_user_id && @user.stripe_publishable_key
  end

end
