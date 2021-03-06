# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do


  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "rails/letter_opener"
  end

  mount Apipony::Engine => '/api/documentation'

  mount ActionCable.server => '/cable'

  get "/@:id" => 'users#show'
  patch "/@:id" => "users#update"
  delete "/@:id" => "users#destroy"
  post "/@:id/subscribe" => "users#subscribe"
  delete "/@:id/unsubscribe" => "users#unsubscribe"

  ############
  # CONCERNS #
  ############

  concern :reportable do
    post "report", on: :member
  end

  concern :commentable do
    post :comment, on: :member
    get :comments, on: :member
  end

  concern :replyable do
    resources :replies
  end

  concern :forumable do
    resources :topics do
      concerns :replyable
    end
  end

  ##################
  # RESTFUL ROUTES #
  ##################
  
  resources :favorites, only: [:create, :destroy] do
    get 'includes_image', on: :member
  end

  resources :conversations do
    resources :messages, only: [:index, :new, :create] do
      get 'by_time', on: :collection
    end
    post :read, on: :member
  end

  resources :tags do
    collection do
      get "suggest"
    end
    concerns :forumable
  end

  resources :commissions_dashboard, only: :index
  ##
  # Not really resourceful at all but whatever yolo
  resources :stripe, only: [] do
    collection do
      get :authorize
      get :callback
    end
  end
  
  resources :listings do
    get 'search', on: :collection
    get 'mine', on: :collection
    post 'confirm', on: :member
    post 'open', on: :member
    post 'close', on: :member

    resources :orders do
      post 'confirm', on: :member
      post 'accept', on: :member
      post 'purchase', on: :member
      post 'fill', on: :member
      post 'reject', on: :member
    end
  end

  get "/my_orders", to: "orders#mine"

  resources :tag_group_changes, only: [:show] do
  end

  resources :images do
    member do
      post "created"
    end

    collection do
      get "feed"
    end

    resources :tag_groups do
      resources :changes, only: [:index], controller: :tag_group_changes
    end

    concerns :reportable, :commentable
  end

  devise_for :users,
             path: "accounts",
             controllers: {
               sessions: "users/sessions"
             }

  resources :users, only: [:show, :edit, :update, :index] do
    get 'search', on: :collection
    ##
    # This is done so it's easier to see a users collections.
    # Meanwhile, creation and modification of collections is its own thing.
    member do
      put 'enable_twofactor'
      get 'verify_twofactor'
      get 'backup_twofactor'
      put 'confirm_twofactor'
      put 'disable_twofactor'
      get 'favorites'
      get 'creations'
      post 'subscribe'
      delete 'unsubscribe'
    end
  end

  resources :collections do
    get :mine, on: :collection
    ##
    # OK we get non-REST here
    resources :images, only: [:create, :destroy], controller: :collection_images do
      ##
      # An action which sees if an image already exists in the collection
      get "exists", on: :collection
    end

    resources :curatorships, except: [:index, :show]
    member do
      post "subscribe"
      delete "unsubscribe"
      ##
      # Refactor these out eventually
      post "add"
      delete "remove"
    end
  end

  resources :notifications, only: [:index] do
    collection do
      get 'unread'
      post 'mark_all_read'
    end

    member do
      post 'read'
    end
  end

  resources :notes do
    collection do
      get 'feed'
    end
    concerns :replyable
  end

  ################
  # ADMIN ROUTES #
  ################

  namespace :admin do
    resources :images, only: [:index, :destroy] do
      post "absolve", on: :member
      collection do
        get 'live'
      end
    end
  end

  #################
  # BROWSE ROUTES #
  #################

  ########################
  # SINGLE ACTION ROUTES #
  ########################
  get 'settings', to: 'users#edit'
  post 'settings', to: 'users#update'

  #################
  # STATIC ROUTES #
  #################
  root to: "frontpage#index"
  get 'about', to: "static_stuff#about"
  get 'people', to: "static_stuff#people"
  get 'guidelines', to: "static_stuff#guidelines"
  get 'contact', to: "static_stuff#contact"
  get 'rules', to: "static_stuff#rules"
  get 'faq', to: "static_stuff#faq"
  get 'help', to: "static_stuff#help"
  get 'press', to: "static_stuff#press"
  get "terms_of_service", to: "static_stuff#terms_of_service"

  get 'search', to: "images#search"
end
