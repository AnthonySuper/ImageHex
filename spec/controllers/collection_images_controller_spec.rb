# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CollectionImagesController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:image) { FactoryGirl.create(:image) }
  let(:collection) { FactoryGirl.create(:collection) }
  context "when logged in as a collection admin" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @user.confirm
      sign_in @user
    end
    let(:curatorship) do
      FactoryGirl.create(:curatorship,
                         user: @user,
                         collection: collection,
                         level: :admin)
    end
    describe "post #create" do
      it "adds the image to a collection" do
        curatorship
        post :create,
          params: {
            collection_id: collection,
            collection_image: FactoryGirl.attributes_for(:collection_image,
                                                        image_id: image.id)
          }
        expect(collection.images).to include(image)
      end
    end
    describe "delete #destroy" do
      it "works" do
        curatorship
        collection.images << image
        expect(collection.images).to include(image)
        delete :destroy,
          params: {
            collection_id: collection,
            id: image
          }
        expect(collection.reload.images).to_not include(image)
      end
    end
  end
end
