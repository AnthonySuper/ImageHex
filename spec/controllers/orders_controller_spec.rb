require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  include Devise::TestHelpers
  let(:listing) { create(:open_listing) }
  context "when logged in" do
    before(:each) do
      @user = create(:user)
      @user.confirm
      sign_in @user
    end

    describe "POST #accept" do 
      context "with priced listings" do
        let(:listing) { create(:listing, user: @user) }
        let(:order) do
          create(:order,
                 listing: listing,
                 confirmed: true)
        end

        it "allows the user to accept the order" do
          expect do
            post :accept,
              params: {
              listing_id: listing.id,
              id: order.id
            }
          end.to change{order.reload.accepted}.from(false).to(true)
        end

        it "changes the accepted_at time" do
          expect do
            post :accept,
              params: {
              listing_id: listing.id,
              id: order.id
            }
          end.to change{order.reload.accepted_at}
        end

        it "creates a conversation" do
          expect do
            post :accept,
              params: {
              listing_id: listing.id,
              id: order.id
            }
          end.to change{Conversation.count}.by(1)
          expect(Conversation.last.user_ids).to contain_exactly(@user.id,
                                                                order.user.id)
        end
      end

      context "with quote listings" do
        let(:listing) { create(:quote_listing, user: @user) }
        let(:order) do
          create(:order,
                 listing: listing,
                 confirmed: true)
              
        end

        it "allows the user to give a price" do
          expect do
            post :accept,
              params: {
              listing_id: listing.id,
              id: order.id,
              quote_price: 500
            }
          end.to change{order.reload.final_price}.to(500)
        end

        it "gives the user a notification" do 
          expect do
            post :accept,
              params: {
              listing_id: listing.id,
              id: order.id,
              quote_price: 500
            }
          end.to change{Notification.count}.by(1)
        end

        it "updates #accepted_at" do
          expect do
            post :accept,
              params: {
              listing_id: listing.id,
              id: order.id,
              quote_price: 500
            }
          end.to change{order.reload.accepted_at}
        end
      end
    end

    describe "POST #confirm" do
      let(:order) { create(:order,
                           listing: listing,
                           user: @user) }
      it "confirms the order" do
        expect do
          post :confirm,
            params: {
            listing_id: listing.id,
            id: order.id
          }
        end.to change{order.reload.confirmed}.from(false).to(true)
      end
      
      it "gives the artist a notification" do
        expect do
          post :confirm,
            params: {
              listing_id: listing.id,
              id: order.id
            }
        end.to change{Notification.count}.by(1)
      end

      it "changes confirmed_at" do
        expect do
          post :confirm,
            params: {
            listing_id: listing.id,
            id: order.id
          }
        end.to change{order.reload.confirmed_at}
      end
    end

    describe "GET new" do
      it "returns success" do
        get :new, params: {listing_id: listing.id}
        expect(response).to be_success
      end
    end

    describe "POST create" do
      context "with valid attributes" do

        let(:images_attributes) do
          attributes_for(:order_reference_image).select do |a|
            [:description, :img].include? a
          end
        end

        let(:references_attributes) do
          {listing_category_id: listing.category_ids.sample,
            description: "This is a test"}
            .merge(images_attributes: {1 => images_attributes})
        end

        let(:order_option_ids) do
          # obtain a randomly sized sample
          listing.options.sample(1 + rand(listing.options.count)).map(&:id)
        end

        let(:order_params) do
          attributes_for(:order)
            .merge(option_ids: order_option_ids)
            .merge(references_attributes: {1 => references_attributes})
        end

        it "creates a new order" do
          p = order_params
          expect do
            post(:create,
              params: {
                listing_id: listing.id,
                order: p
              })
          end.to change{Order.count}.by(1)
          expect(Order.last.options.pluck(:id)).to match_array(order_option_ids)
        end
        it "creates a new order on the listing" do
          p = order_params
          expect do
            post(:create,
                 params: {
                  listing_id: listing.id,
                  order: p
                })
          end.to change{listing.orders.count}.by(1)
        end
      end
    end
  end
end
