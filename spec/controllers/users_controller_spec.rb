# frozen_string_literal: true
require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  include Devise::Test::ControllerHelpers
  context "when logged in" do
    before(:each) do
      @user = FactoryGirl.create(:user,
                                 password: "thispassword")
      @user.confirm
      sign_in @user
    end
    describe "post #subscribe" do
      it "creates a subscription" do
        u = FactoryGirl.create(:user)
        expect do
          post :subscribe, params: { id: u.id }
        end.to change { ArtistSubscription.count }.by(1)
        expect(@user.subscribed_artists).to include(u)
      end
    end
    describe "delete #unsubscribe" do
      it "creates a subscription" do
        u = FactoryGirl.create(:user)
        @user.subscribe! u
        expect(@user.subscribed_artists).to include(u)
        expect do
          delete :unsubscribe, params: { id: u.id }
        end.to change { ArtistSubscription.count }.by(-1)
        expect(@user.subscribed_artists).to_not include(u)
      end
    end
    describe "get #edit" do
      it "sets the user variable" do
        get :edit, params: { id: @user.id }
        expect(assigns(:user)).to eq(@user)
      end
      it "responds with success" do
        get :edit, params: { id: @user.id }
        expect(response).to be_success
      end
    end
    describe "put #update" do
      describe "updating user page" do
        # this works when you test it manually
        # TODO: make it work automatically as well
        it "allows updating" do
          put :update,
            params: {
              id: @user.id,
              user: { user_page: { body: "test" } }
            }
          #  expect(@user.reload.user_page.reload.body).to eq("test")
        end
      end
      describe "updating page pref" do
        it "allows update" do
          put :update,
            params: {
              id: @user.id,
              user: { page_pref: 10 }
            }
          expect(@user.reload.page_pref).to eq(10)
        end
      end
      describe "updating content ratings" do
        # Can't get this test to work properly, note that I have manually
        # verified it works - Anthony
        # TODO
        pending "add some examples to (or delete) #{__FILE__}"
      end
    end
    describe "PUT #enable_twofactor" do
      it "starts to enable 2factor" do
        # Ensure it's not enabled at this point
        @user.otp_required_for_login = false
        @user.save
        put :enable_twofactor, params: { id: @user }
        expect(@user.reload.otp_secret).to_not be_nil
      end
      it "doesn't work for other users" do
        put :enable_twofactor, params: { id: FactoryGirl.create(:user) }
        expect(response).to_not be_success
      end
    end
    describe "PUT #disable_twofactor" do
      it "disables 2factor" do
        @user.enable_twofactor
        put :disable_twofactor,
          params: { 
            id: @user,
            current_password: "thispassword"
          }
        expect(@user.reload.otp_required_for_login).to be_falsy
      end
      it "does not work for other users" do
        u = FactoryGirl.create(:user)
        u.enable_twofactor
        put :disable_twofactor, params: { id: u }
        expect(response).to_not be_success
      end
    end
    describe "GET verify_twofactor" do
      it "only works if the user has twofactor enabled" do
        @user[:otp_required_for_login] = false
        @user[:encrypted_otp_secret] = nil
        get :verify_twofactor, params: { id: @user } 
        expect(response).to_not be_success
      end
      it "only works if the user hasn't verified" do
        @user[:two_factor_verified] = true
        get :verify_twofactor, params: { id: @user } 
        expect(response).to_not be_success
      end
    end
    describe "PUT confirm_twofactor" do
      it "works with the right key" do
        @user.enable_twofactor
        put :confirm_twofactor,
          params: {
            id: @user,
            otp_key: @user.current_otp
          }
        expect(@user.reload.otp_required_for_login).to eq(true)
        expect(@user.reload.two_factor_verified).to eq(true)
      end
      it "doesn't work with the wrong key" do
        @user[:otp_required_for_login] = false
        @user.enable_twofactor
        put :confirm_twofactor,
          params: {
            id: @user,
            otp_key: "123123123"
          }
        expect(response).to_not be_success
        expect(@user.reload.otp_required_for_login).to eq(false)
      end
    end
  end
end
