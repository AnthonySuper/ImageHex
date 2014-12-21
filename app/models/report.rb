class Report < ActiveRecord::Base
  #############
  # RELATIONS #
  #############
  belongs_to :reportable, polymorphic: true
  belongs_to :user


  #########
  # ENUMS #
  #########
  enum severity: [:illegal, :offensive, :spam]


  ###############
  # VALIDATIONS #
  ###############
  validates :severity, presence: true

end
