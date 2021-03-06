RSpec.feature "User page visit", type: :feature do
  let(:user){ create(:user) }
  include_context "when signed in" do
    scenario "they follow the user" do
      visit user_path(user)

      expect do
        click_button("Follow")
      end.to change{user.subscribers.reload.count}.by(1)
    end
  end

  scenario "display the user name" do
    visit user_path(user)

    expect(page).to have_title(user.name)
  end

  scenario "displays creations" do
    user.creations << create(:image)
    visit user_path(user)

    expect(page).to have_css(".image-gallery-item")
  end
end
