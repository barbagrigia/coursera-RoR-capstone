Rails.application.routes.draw do

  get 'authn/whoami', defaults: {format: :json}
  get 'authn/checkme'

  mount_devise_token_auth_for 'User', at: 'auth'

  scope :api, defaults: {format: :json}  do
    resources :foos, except: [:new, :edit]
    resources :bars, except: [:new, :edit]
    resources :images, except: [:new, :edit] do
      post "thing_images",  controller: :thing_images, action: :create
      get "thing_images",  controller: :thing_images, action: :image_things
      get "linkable_things",  controller: :thing_images, action: :linkable_things
    end
    resources :tags, except: [:new, :edit] do
      post "associated_things",  controller: :thing_tags, action: :create
      get "associated_things", controller: :thing_tags, action: :associated_things
      get "linkable_things",  controller: :thing_tags, action: :linkable_things
    end
    resources :things, except: [:new, :edit] do
      resources :thing_images, only: [:index, :create, :update, :destroy]
      resources :thing_tags, only: [:index, :create, :update, :destroy]
    end

    get "images/:id/content", as: :image_content, controller: :images, action: :content, defaults:{format: :jpg}
    get 'geocoder/addresses' => "geocoder#addresses"
    get 'geocoder/positions' => "geocoder#positions"
    get 'subjects' => "thing_images#subjects"
  end

  get "/client-assets/:name.:format", :to => redirect("/client/client-assets/%{name}.%{format}")
#  get "/", :to => redirect("/client/index.html")

  get '/ui'  => 'ui#index'
  get '/ui#' => 'ui#index'
  root "ui#index"
end
