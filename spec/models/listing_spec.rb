require 'rails_helper'

RSpec.describe Listing, type: :model do
  describe "validation" do
    it "requires at least one category" do
      e = FactoryGirl.build(:listing,
                            categories: [],
                            categories_count: 0)
      expect(e).to_not be_valid
    end
  end
end
