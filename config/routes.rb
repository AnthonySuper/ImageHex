Rails.application.routes.draw do

  ############
  # CONCERNS #
  ############

  concern :reportable do
    post "report", on: :member
  end

  ##################
  # RESTFUL ROUTES #
  ##################

  resources :images do
    member do
      post "favorite"
      post "created"
      post "add"
    end
    resources :tag_groups
    concerns :reportable
  end
  devise_for :users, path: "accounts"

  resources :users do
    ##
    # This is done so it's easier to see a users collections.
    # Meanwhile, creation and modification of collections is its own thing.
    resources :collections, only: [:index]
  end
  resources :collections, except: [:index] do
    post "subscribe", on: :member
  end
  ################
  # ADMIN ROUTES #
  ################

  namespace :admin do
    resources :images, only: [:index, :destroy] do
      post "absolve", on: :member
    end
  end
  #################
  # STATIC ROUTES #
  #################

  root to: "frontpage#index"


  get '/about', to: "static_stuff#about"

  get '/people', to: "static_stuff#people"

  get '/contact', to: "static_stuff#contact"

  get '/settings', to: 'users#edit'

  post '/settings', to: 'users#update'
  get '/search', to: "images#search"
end
