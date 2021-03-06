# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CollectionsController, type: :controller do
  include Devise::Test::ControllerHelpers
  describe "get #index" do
    it "renders the index page" do
      user = FactoryGirl.create(:user)
      user.collections << [FactoryGirl.create(:collection)]
      get :index, params: { user_id: user }
      expect(response).to render_template("index")
    end
  end
  describe "get #show" do
    let(:c) { FactoryGirl.create(:collection) }
    it "is success" do
      get :show, params: { id: c.id }
      expect(response).to be_success
    end
    it "sets the images variable" do
      get :show, params: { id: c.id }
      expect(assigns(:images)).to eq(c.images)
    end
    it "sets the collection variable" do
      get :show, params: { id: c.id }
      expect(assigns(:collection)).to eq(c)
    end
    it "sets the curators variable" do
      get :show, params: { id: c.id }
      expect(assigns(:curators)).to eq(c.curators)
    end
  end
  context "when logged in" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @user.confirm
      sign_in @user
    end
    describe "PUT #update" do
      let(:c) { FactoryGirl.create(:collection) }
      before :each do
        Curatorship.create(collection: c,
                           user: @user,
                           level: :admin)
      end

      it "works" do
        put :edit,
          params: {
            id: c,
            collection: FactoryGirl.attributes_for(:collection)
          }
        expect(response).to be_success
      end
    end

    describe "DELETE #destroy" do
      let(:c) { FactoryGirl.create(:collection) }
      before :each do
        Curatorship.create(collection: c,
                           user: @user,
                           level: :admin)
      end
      it "allows deletion" do
        expect do
          delete :destroy, params: { id: c.id }
        end.to change { Collection.count }.by(-1)
      end
    end

    describe "DELETE #unsubscribe" do
      it "unsubscribes" do
        c = FactoryGirl.create(:collection)
        @user.subscribed_collections << c
        expect(@user.subscribed_collections).to include(c)
        expect do
          delete :unsubscribe, params: { id: c }
        end.to change { @user.subscribed_collections.count }.by(-1)
        expect(@user.subscribed_collections.reload).to_not include(c)
      end
    end

    describe "post #subscribe" do
      let(:c) { FactoryGirl.create(:collection) }
      it "adds the collection to a users subscribed collections" do
        expect do
          post "subscribe", params: { id: c }
        end.to change { @user.subscribed_collections.count }.by(1)
      end
    end
    describe "get #new" do
      it "sets a @collection variable"
      it "renders a new collection form"
    end
    describe "post #create" do
      context "with valid attributes" do
        let(:subjective_atrs){ {name: "My Kawaii Images"} }
      
        it "makes a new collection of the proper type with an admin user" do
          expect do
            post :create, params: { collection: subjective_atrs }
          end.to change { Collection.count }.by(1)
          expect(Curatorship.last.level).to eq("admin")
        end
        it "redirects to the collection" do
          post :create, params: { collection: subjective_atrs }
          expect(response).to redirect_to(collection_path(Collection.last))
        end
      end
      context "with invalid attributes" do
        it "doesn't make a new collection"
        it "renders the #new page with errors set"
      end
    end
  end
end
