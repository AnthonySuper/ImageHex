##
# Represents a tag in the ImageHex database.
# Tags must have a unique name, and are not case sensative.
#
# Tags are formatted before saving to remove excess spaces ("do  thing" becomes
# "do thing"), trailing and leading whitespace " do thing " becomes "do thing"),
# and capital letters in the normal name. The display_name, which
# is what should always be shown to the user, retains capital letters.
class Tag < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  ##
  # CALLBACKS:
  before_save :fix_name
  ##
  # SCOPES
  scope :by_importance, ->{ order(:importance) }
  ##
  # ASSOCIATIONS:
  has_many :tag_group_members
  has_many :tag_groups, through: :tag_group_members
  has_many :images, through: :tag_groups
  validates :name, uniqueness: {case_sensative: false}
  validates :importance, inclusion: {in: (0..1)}
  validate :name_and_display_name_equality
  ##
  # Suggest tags beginning with a string.
  # Tags are returned alphabetically.
  # Returns 10 tags at a time.
  # Usage:
  #   Tag.suggest("ha") => ["hack", "halloween"]
  def self.suggest(n)
    query = %q{
    SELECT tags.* FROM tags
    WHERE tags.name LIKE ?
    ORDER BY importance ASC
    LIMIT 10
    }
    finder = "#{n.gsub("%","").downcase.strip.squish}%"
    find_by_sql([query, finder])
  end
  

  private

  def name_and_display_name_equality
    self.display_name ||= self.name.downcase 
    if self.display_name.downcase != self.name.downcase then
      errors.add(:display_name, "must_change_case_only")
    end
  end
  ##
  # Callback which formats the name.
  def fix_name
    self.display_name ||= self.name.strip.squish
    self.name = self.name.strip.squish.downcase
  end
end
