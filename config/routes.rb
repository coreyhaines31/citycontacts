Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  root 'pages#home'

  devise_for :users, 
    path: '', 
    path_names: { sign_in: 'login', sign_up: 'signup' }, 
    controllers: { 
      registrations: 'registrations' 
    }
  
  get 'logout', to: 'pages#logout', as: 'logout'

  resources :subscribe, only: [:index]
  resources :dashboard, only: [:index]
  resources :account, only: %i[index update] do
    get :stop_impersonating, on: :collection
  end
  resources :billing_portal, only: [:new, :create]
  resources :blog_posts, controller: :blog_posts, path: "blog", param: :slug
  resources :social_connections, only: [] do
    delete 'disconnect/:provider', to: 'social_connections#disconnect', as: :disconnect, on: :collection
    post :refresh_locations, on: :collection
    post :create_city_connections, on: :collection
  end

  # Twitter OAuth
  get '/auth/twitter', to: 'twitter_auth#request_authorization', as: 'twitter_login'
  get '/auth/twitter/callback', to: 'twitter_auth#callback', as: 'twitter_callback'

  # static pages
  pages = %w[
    privacy terms
  ]

  pages.each do |page|
    get "/#{page}", to: "pages##{page}", as: page.gsub('-', '_').to_s
  end

  # admin panels
  authenticated :user, lambda(&:admin?) do
    # insert sidekiq etc
    mount Split::Dashboard, at: 'admin/split'
  end
end
