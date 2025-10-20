class SettingsController < ApplicationController
  unloadable

  def plugin
    @plugin = Redmine::Plugin.find(params[:id])
    @partial = @plugin.settings[:partial]
    
    # Читаем настройки из правильного места
    begin
      saved_settings = Setting.plugin_redmine_project_progress
      if saved_settings.present?
        @settings = saved_settings
      else
        # Если сохраненных настроек нет, используем настройки по умолчанию из плагина
        default_settings = @plugin.settings
        @settings = default_settings[:default] || default_settings
      end
      
      # Убеждаемся, что все настройки имеют значения по умолчанию
      default_settings = @plugin.settings[:default] || {}
      @settings = default_settings.merge(@settings)
    rescue => e
      Rails.logger.error "Project Progress: Error reading settings for display: #{e.message}"
      # В случае ошибки используем настройки по умолчанию
      default_settings = @plugin.settings
      @settings = default_settings[:default] || default_settings
    end
    
    if request.post?
      # Используем стандартный способ сохранения настроек Redmine
      begin
        # Обрабатываем чекбоксы - если их нет в параметрах, значит они не отмечены
        settings_to_save = params[:settings].permit!.to_h
        
        # Обрабатываем чекбоксы
        checkbox_settings = ['show_in_sidebar', 'include_subtasks', 'include_closed_issues', 'cache_calculation', 'enable_debug_logging', 'log_calculation_details', 'count_100_percent_as_closed', 'parent_project_include_own_issues']
        checkbox_settings.each do |setting|
          if !settings_to_save.key?(setting)
            settings_to_save[setting] = '0'  # Не отмечен
          end
        end
        
        # Сохраняем настройки через стандартный механизм Redmine
        Setting.plugin_redmine_project_progress = settings_to_save
        
        flash[:notice] = l(:notice_successful_update)
      rescue => e
        Rails.logger.error "Project Progress: Error saving settings: #{e.message}"
        flash[:error] = "Ошибка сохранения настроек: #{e.message}"
      end
      
      redirect_to plugin_settings_path(@plugin)
    end
  end
end
