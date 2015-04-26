require 'rails_helper'

RSpec.describe CollectionImagesController, type: :controller do
  include Devise::TestHelpers

  let(:image){FactoryGirl.create(:image)}
  let(:collection){FactoryGirl.create(:collection)}
  context "when logged in as a collection admin" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @user.confirm!
      sign_in @user
    end
    let(:curatorship){FactoryGirl.create(:curatorship,
                                         user: @user,
                                         collection: :collection,
                                         level: :admin)}
    describe "post #create" do
      it "adds the image to a collection" do
        post(:create, 
             collection_id: collection,
             collection_image: FactoryGirl.attributes_for(:collection_image,
                                                          image_id: image.id))
        expect(collection.images).to include(image)
      end
    end
    describe "delete #destroy" do
      it "works" do
        FactoryGirl.create(:collection_image,
                           image_id: image.id,
                           collection_id: :collection)
        expect(collection.images).to include(image)
        delete(:destroy,
               collection_id: collection,
               id: image)
        expect(collection.images).to_not include(image)
      end
    end


  end
end
