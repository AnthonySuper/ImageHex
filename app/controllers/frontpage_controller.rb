# frozen_string_literal: true
##
# We put the frontpage in a seperate controller, since it isn't
# static and also isn't RESTful.
#
# Users can see all the images in their feed here.
class FrontpageController < ApplicationController
  ##
  # Root of our site.
  def index
    if current_user
      after = if params[:fetch_after]
                Time.at(params[:fetch_after].to_f)
              else
                Time.zone.now
              end
      @images = current_user.image_feed
        .includes(:creators)
        .where("sort_created_at < ?", after)
        .limit(5)
      render "index_with_user"
    else
      @images = Image.all
        .paginate(page: page, per_page: per_page)
        .order('created_at DESC')
        .for_content(content_pref)
      render "index"
    end
  end
end
