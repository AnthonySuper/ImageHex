## 
# A Favorite is a type of collection that holds a users favorite images.
class Favorite < Collection
  before_validation :fill_name

  ##
  # since this will only ever have 1 curator, we make a helpful
  # alias method
  def curator
    curators.first
  end
  protected
  def fill_name
    self.name = "#{self.curator.name.possessive} Favorites"
  end
end
