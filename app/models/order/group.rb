class Order::Group < ActiveRecord::Base

  belongs_to :order,
    inverse_of: :groups,
    required: true

  has_many :images,
    class_name: "Order::Group::Image",
    foreign_key: :order_group_id,
    dependent: :destroy

  has_many :group_tags,
    class_name: "Order::Group::Tag",
    foreign_key: :order_group_id,
    dependent: :destroy

  has_many :tags,
    class_name: "::Tag",
    through: :group_tags

  validates :order,
    presence: true

  validates :description,
    presence: true

  accepts_nested_attributes_for :images,
    allow_destroy: true

end

require_dependency("order/group/image.rb")
require_dependency("order/group/tag.rb")
