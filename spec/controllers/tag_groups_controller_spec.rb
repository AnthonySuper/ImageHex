# frozen_string_literal: true
require 'spec_helper'

describe TagGroupsController do
  include Devise::Test::ControllerHelpers
  context "when logged in" do
    let(:image) { FactoryGirl.create(:image) }
    before(:each) do
      @user = FactoryGirl.create(:user)
      @user.confirm
      sign_in @user
    end
    describe "put #update" do
      let(:group) { FactoryGirl.create(:tag_group, image: image) }
      let(:tag1) { FactoryGirl.create(:tag) }
      let(:tag2) { FactoryGirl.create(:tag) }
      it "properly updates" do
        put :update,
          params: {
            image_id: image,
            id: group,
            tag_group: { tag_ids: [tag1.id, tag2.id] }
          }
        expect(group.tags.reload).to contain_exactly(tag1, tag2)
      end
      it "creates a new tag group change" do
        old_tags = group.tags.pluck(:id)
        expect do
          put :update,
            params: {
              image_id: image,
              id: group,
              tag_group: { tag_ids: [tag1.id, tag2.id] }
            }
        end.to change { TagGroupChange.count }.by(1)
        expect(TagGroupChange.last.tag_group).to eq(group)
        expect(TagGroupChange.last.before).to match_array(old_tags)
      end
    end
    describe "post #create" do
      let(:tag1) { FactoryGirl.create(:tag) }
      let(:tag2) { FactoryGirl.create(:tag) }
      it "makes a new tag group" do
        expect do
          post :create,
            params: {
              image_id: image,
              tag_group: { tag_ids: [tag1.id, tag2.id] }
            }
        end.to change { TagGroup.count }.by(1)
      end
      it "makes a new tag group change" do
        expect do
          post :create,
            params: {
              image_id: image,
              tag_group: { tag_ids: [tag1.id, tag2.id] }
            }
        end.to change { TagGroupChange.count }.by(1)
        expect(TagGroupChange.last.kind).to eq("created")
        expect(TagGroupChange.last.user).to eq(@user)
      end
    end
    describe 'get #new' do
      it "responds successfully" do
        get :new, params: { image_id: image }
        expect(response).to be_success
      end
    end
    describe "get #edit" do
      let(:group) { FactoryGirl.create(:tag_group) }
      it "responds successfully" do
        get :edit, params: { image_id: group.image, id: group.id }
        expect(response).to be_success
      end
      it "sets the variables correctly" do
        get :edit, params: { image_id: group.image, id: group.id }
        expect(assigns(:tag_group)).to eq(group)
      end
    end
  end
  context "when not logged in" do
    let(:image) { FactoryGirl.create(:image) }
    describe "get #new" do
      it "redirects to the login page" do
        get :new, params: { image_id: image }
        expect(response).to redirect_to("/accounts/sign_in")
      end
    end
    describe "get #edit" do
      it "redirects to the login page" do
        get :new, params: { image_id: image }
        expect(response).to redirect_to("/accounts/sign_in")
      end
    end
  end
end
