class ProjectProgressController < ApplicationController
  unloadable
  
  before_action :find_project, :only => [:index, :show]
  before_action :authorize, :only => [:index]
  
  # API метод с базовой авторизацией
  skip_before_action :check_if_login_required, :only => [:show]
  before_action :api_authorize, :only => [:show]
  
  def index
    begin
      @progress = ProjectProgressCalculator.calculate(@project)
      
      respond_to do |format|
        format.html
        format.json { render :json => @progress }
      end
    rescue => e
      Rails.logger.error "Project Progress Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      @progress = ProjectProgressCalculator.empty_progress
      @error = "Ошибка расчета прогресса: #{e.message}"
      
      respond_to do |format|
        format.html { render :index }
        format.json { render :json => { error: @error }, :status => 500 }
      end
    end
  end
  
  # API метод для получения прогресса проекта
  def show
    begin
      progress = ProjectProgressCalculator.calculate(@project)
      
      respond_to do |format|
        format.json { render :json => progress }
      end
    rescue => e
      Rails.logger.error "Project Progress API Error: #{e.message}"
      
      respond_to do |format|
        format.json { render :json => { error: "Ошибка расчета прогресса" }, :status => 500 }
      end
    end
  end
  
  private
  
  def find_project
    if params[:project_id]
      @project = Project.find(params[:project_id])
    elsif params[:id]
      @project = Project.find(params[:id])
    else
      render_404
    end
  rescue ActiveRecord::RecordNotFound
    render :json => { error: 'Project not found' }, :status => 404
  end
  
  def authorize
    # Проверяем, что пользователь авторизован и проект видим
    unless User.current.logged? && @project.visible?
      deny_access
    end
  end
  
  def api_authorize
    # Базовая проверка - пользователь должен быть авторизован
    unless User.current.logged? && @project.visible?
      render :json => { error: 'Unauthorized' }, :status => 401
      return
    end
  end
end