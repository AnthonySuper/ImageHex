json.extract! product, 
  :id,
  :name,
  :description,
  :created_at,
  :updated_at,
  :base_price,
  :included_subjects,
  :subject_price,
  :background_price,
  :offer_background,
  :offer_subjects,
  :maximum_subjects,
  :include_background

json.user product.user, partial: "users/stub", as: :user
