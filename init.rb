require 'redmine'

Redmine::Plugin.register :redmine_project_progress do
  name 'Project Progress Plugin'
  author 'Your Name'
  description 'Плагин для отображения общего прогресса по проекту'
  version '1.0.0'
  url 'http://example.com/plugins/redmine_project_progress'
  author_url 'http://example.com'
  
  permission :view_project_progress, { :project_progress => [:index, :show] }, :require => :loggedin
  
  menu :project_menu, :project_progress, { :controller => 'project_progress', :action => 'index' }, 
       :caption => :label_project_progress, :after => :activity, :param => :project_id
  
  settings :default => {
    # Настройки расчета прогресса
    'default_calculation_method' => 'progress_by_status',
    'priority_weights_high' => 3.0,
    'priority_weights_normal' => 2.0,
    'priority_weights_low' => 1.0,
    'story_points_patterns' => 'story point,complexity,size,estimate',
    
    # Настройки для разных типов проектов
    'parent_project_include_own_issues' => true,
    'parent_project_weight_children' => true,
    'parent_project_calculation_method' => 'weighted_average',
    'include_subtasks' => false,
    'include_closed_issues' => true,
    'minimum_issues_count' => 1,
    'exclude_trackers' => '',
    'exclude_priorities' => '',
    
    # Настройки отладки
    'enable_debug_logging' => false,
    'log_calculation_details' => false,
    
    # Настройки производительности
    'cache_calculation' => false,
    'cache_duration' => 600,
    
    # Базовые настройки
    'show_in_sidebar' => false,
    'count_100_percent_as_closed' => true
  }, :partial => 'settings/redmine_project_progress_settings'
end

# Загрузка хука
require_relative 'lib/redmine_project_progress_hooks'