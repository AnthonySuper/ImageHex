##
# We put the frontpage in a seperate controller, since it isn't
# static and also isn't RESTful.
#
# Users can see all the images in their feed here.
class FrontpageController < ApplicationController
  ##
  # "/" of our site.
  def index
    if current_user
      @images = current_user.image_feed.paginate(page: page, per_page: per_page)
      render "index_with_user"
    else
      render "index"
    end
  end
end
