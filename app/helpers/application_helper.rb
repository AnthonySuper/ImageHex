##
# Helpers used universally throughout ImageHex
module ApplicationHelper
  ##
  # This allows us to get a "link" to a comment, which is really just a link
  # to the thing being commented on with the id of the comment appended to the
  # URL as an anchor link.
  def comment_path(comment)
    polymorphic_path(comment.commentable) + "##{comment.id}" if comment.commentable
  end

  ##
  # Used on the About, People, and Contact pages to add a "current"
  # class to the tab link if the page linked is the current page.
  def current(path)
    "current" if current_page?(path)
  end

  ##
  # Used for page's HTML titles.
  # http://stackoverflow.com/a/3841549
  def title(page_title)
    content_for(:title) { page_title }
  end
end
