RedmineApp::Application.routes.draw do
  resources :projects do
    resources :project_progress, :only => [:index]
    
    # Маршрут для API прогресса
    member do
      get 'project_progress', to: 'project_progress#show', as: 'api_project_progress'
    end
  end
  
  # Маршрут для экспорта проектов с прогрессом
  get 'project_progress_export', to: 'project_progress_export#index', as: 'project_progress_export'
  
  # Маршрут для настроек плагина
  get 'settings/plugin/:id', to: 'settings#plugin', as: 'redmine_project_progress_plugin_settings'
  post 'settings/plugin/:id', to: 'settings#plugin'
end