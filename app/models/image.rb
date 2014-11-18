class Image < ActiveRecord::Base
  belongs_to :user
  ##
  # The actual image file is referenced with f
  has_attached_file :f, styles: { medium: "300x300>", thumb: "100x100>" }
  validates_attachment_content_type :f, content_type: /\Aimage\/.*\Z/
  validates_attachment_presence :f
  validates :user, presence: :true
  enum license: [:public_domain, :all_rights_reserved, :cc_by, :cc_by_sa, :cc_by_nd, :cc_by_nc, :cc_by_nc_sa, :cc_by_nc_nd]
  enum medium: [:photograph, :pencil, :paint, :digital_paint, :mixed_media, :three_dimensional_render]
  validates :license, presence: true
  validates :medium, presence: true
end
