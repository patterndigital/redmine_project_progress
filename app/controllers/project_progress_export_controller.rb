class ProjectProgressExportController < ApplicationController
  unloadable
  
  before_action :authorize_global
  
  def index
    # Получаем все видимые проекты
    @projects = Project.visible.sorted
    
    # Вычисляем прогресс для каждого проекта
    @projects.each do |project|
      begin
        progress = ProjectProgressCalculator.calculate(project)
        project.instance_variable_set(:@progress_percentage, progress[:progress_percentage])
        project.instance_variable_set(:@progress_closed_issues, progress[:closed_issues])
        project.instance_variable_set(:@progress_total_issues, progress[:total_issues])
      rescue => e
        Rails.logger.error "Project Progress Export: Error calculating progress for project #{project.id}: #{e.message}"
        project.instance_variable_set(:@progress_percentage, 0)
        project.instance_variable_set(:@progress_closed_issues, 0)
        project.instance_variable_set(:@progress_total_issues, 0)
      end
    end
    
    respond_to do |format|
      format.csv do
        send_data generate_csv, 
                  :type => 'text/csv; charset=utf-8; header=present',
                  :disposition => "attachment; filename=projects_with_progress_#{Date.current.strftime('%Y%m%d')}.csv"
      end
    end
  end
  
  private
  
  def generate_csv
    require 'csv'
    
    CSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # Заголовки
      csv << [
        l(:field_name),
        l(:field_description),
        l(:field_homepage),
        l(:field_is_public),
        l(:field_created_on),
        l(:field_updated_on),
        'Progress (%)',
        'Closed Issues',
        'Total Issues'
      ]
      
      # Данные проектов
      @projects.each do |project|
        csv << [
          project.name,
          project.description,
          project.homepage,
          project.is_public? ? l(:general_text_Yes) : l(:general_text_No),
          format_date(project.created_on),
          format_date(project.updated_on),
          project.instance_variable_get(:@progress_percentage),
          project.instance_variable_get(:@progress_closed_issues),
          project.instance_variable_get(:@progress_total_issues)
        ]
      end
    end
  end
  
  def authorize_global
    # Проверяем права доступа
    unless User.current.allowed_to?(:view_project_progress, nil, :global => true)
      deny_access
    end
  end
end
