Mashoutable::Application.routes.draw do
  # 3rd party authentication providers (twitter, facebook, etc...)
  match '/auth/:provider/callback'  => 'authorization#create'
  match '/auth/failure'             => 'authorization#failure'

  # social network
  match 'network'             => 'dashboard#remove_networks', :via => :delete,  :as => :remove_networks

  # mashouts
  match 'mashouts/create'     => 'dashboard#create_mashout',  :via => :post,    :as => :mashout_create

  # shoutouts
  match 'shoutouts/create'    => 'dashboard#create_shoutout', :via => :post,    :as => :shoutout_create

  # blastouts
  match 'blastouts/create'    => 'dashboard#create_blastout', :via => :post,    :as => :blastout_create

  # besties
  match 'besties/delete'      => 'dashboard#delete_bestie',   :via => :delete,  :as => :delete_bestie
  match 'besties/new'         => 'dashboard#create_bestie',   :via => :post,    :as => :create_bestie

  # videos
  match 'videos/new'          => 'dashboard#create_video',    :via => :post,    :as => :create_video
  match 'videos/:guid'        => 'dashboard#delete_video',    :via => :delete,  :as => :delete_video
  match 'videos/(:guid)'      => 'dashboard#video_playback',  :via => :get,     :as => :video_playback
  match 'videos/:guid'        => 'dashboard#update_video',    :via => :post,    :as => :update_video

  # contact us & misc
  match 'contact-us/message'  => 'content#message',     :via => :post, :as => :contact_us_message
  match 'contact-us'          => 'content#contact_us',  :as => :contact_us
  match 'about-us'            => 'content#about_us',    :as => :about_us
  match 'blog'                => 'content#blog'
  match 'privacy'             => 'content#privacy_policy',    :as => :privacy_policy
  match 'terms'               => 'content#terms_and_conditions',    :as => :terms_and_conditions
  match 'mashout'             => 'content#mashout',     :as => :mashout
  match 'blastout'            => 'content#blastout',    :as => :blastout
  match 'shoutout'            => 'content#shoutout',    :as => :shoutout
  match 'pickout'             => 'content#pickout',     :as => :pickout
  match 'signup_iframe'       => 'content#signup_iframe', :as => :signup_iframe

  # dashboard
  match 'dashboard'                    => 'dashboard#index'
  match 'dashboard/tool'               => 'dashboard#tool'
  match 'dashboard/besties'            => 'dashboard#besties'
  match 'dashboard/videos'             => 'dashboard#videos'
  match 'dashboard/mashout'            => 'dashboard#mashout',  :as => :dashboard_mashout
  match 'dashboard/blastout'           => 'dashboard#blastout', :as => :dashboard_blastout
  match 'dashboard/shoutout'           => 'dashboard#shoutout', :as => :dashboard_shoutout
  # TODO: the following tool is temporarily unavailable
  # match 'dashboard/pickout'            => 'dashboard#pickout'
  match 'dashboard/interactions'       => 'dashboard#interactions'
  match 'dashboard/signout'            => 'dashboard#signout'
  match 'dashboard/trends'             => 'dashboard#trends',    :via => :get, :as => :trend_source
  match 'dashboard/targets'            => 'dashboard#targets',   :via => :get, :as => :target_source
  match 'dashboard/trendspottr_search' => 'dashboard#trendspottr_search', :via => :get, :as => :trendspottr_search

  # Friends of current_user
  scope "user", :as => "user" do
    resources :friends, :only => [:create, :destroy]
    resources :user_hashtags, :path => '/hashtags', :as => 'hashtags', :only => [:new, :create, :update, :destroy]
  end

  resources :advertisements, :only => [:show]
  resources :advertisement_emails, :only => [:create]

  # default
  match '/' => 'content#home', :as => :home

  # root
  root :to  => 'content#home'
end

