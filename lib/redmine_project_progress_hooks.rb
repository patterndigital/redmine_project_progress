class RedmineProjectProgressHooks < Redmine::Hook::ViewListener
  # Хук для сайдбара проекта
  render_on :view_projects_show_sidebar_bottom, 
            :partial => 'project_progress/sidebar'
  
  # Инициализация патча для CSV экспорта
  def self.included(base)
    # Применяем патч к ProjectsController для CSV экспорта
    if defined?(ProjectsController)
      ProjectsController.class_eval do
        alias_method :index_without_progress_csv, :index unless method_defined?(:index_without_progress_csv)
        
        def index
          if request.format.csv? && params[:include_progress] == 'true'
            # Добавляем столбец прогресса в CSV экспорт
            add_progress_to_csv_export
          else
            index_without_progress_csv
          end
        end
        
        private
        
        def add_progress_to_csv_export
          # Получаем все проекты
          @projects = Project.visible.sorted
          
          # Добавляем прогресс для каждого проекта
          @projects.each do |project|
            begin
              progress = ProjectProgressCalculator.calculate(project)
              project.instance_variable_set(:@progress_percentage, progress[:progress_percentage])
              project.instance_variable_set(:@progress_closed_issues, progress[:closed_issues])
              project.instance_variable_set(:@progress_total_issues, progress[:total_issues])
            rescue => e
              Rails.logger.error "Project Progress CSV: Error calculating progress for project #{project.id}: #{e.message}"
              project.instance_variable_set(:@progress_percentage, 0)
              project.instance_variable_set(:@progress_closed_issues, 0)
              project.instance_variable_set(:@progress_total_issues, 0)
            end
          end
          
          # Вызываем оригинальный метод
          index_without_progress_csv
        end
      end
    end
  end
  
  # Хук для добавления кнопки экспорта проектов с прогрессом
  def view_projects_index_bottom(context = {})
    # Отладочная информация
    Rails.logger.info "Project Progress: view_projects_index_bottom hook called"
    
    # Добавляем кнопку экспорта с прогрессом
    begin
      export_url = Rails.application.routes.url_helpers.project_progress_export_path(format: 'csv')
      Rails.logger.info "Project Progress: Export URL generated: #{export_url}"
    rescue => e
      Rails.logger.error "Project Progress: Error generating export URL: #{e.message}"
      export_url = "/project_progress_export.csv"
    end
    
    <<~HTML
      <div style="margin: 20px 0; padding: 15px; background: #f9f9f9; border: 1px solid #ddd; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        <h3 style="margin: 0 0 10px 0; color: #333; font-size: 16px;">📊 Экспорт проектов с прогрессом</h3>
        <p style="margin: 0 0 15px 0; color: #666; font-size: 14px;">
          Экспортируйте все проекты в CSV файл с информацией о прогрессе выполнения.
        </p>
        <a href="#{export_url}" class="icon icon-download" 
           style="display: inline-block; padding: 10px 20px; background: #4CAF50; color: white; text-decoration: none; border-radius: 4px; font-weight: bold; font-size: 14px; transition: background-color 0.3s ease;"
           onmouseover="this.style.backgroundColor='#45a049'" 
           onmouseout="this.style.backgroundColor='#4CAF50'">
          📥 Скачать CSV с прогрессом
        </a>
      </div>
    HTML
  end
  
  # Хук для модификации CSV экспорта проектов
  def view_projects_index_csv(context = {})
    # Добавляем JavaScript для модификации CSV данных
    if context[:request] && context[:request].format.csv?
      <<~HTML
        <script>
          // Перехватываем CSV экспорт и добавляем столбец прогресса
          document.addEventListener('DOMContentLoaded', function() {
            if (window.location.search.includes('format=csv') && window.location.search.includes('include_progress=true')) {
              modifyCSVExport();
            }
          });
          
          function modifyCSVExport() {
            // Получаем все проекты на странице
            const projectLinks = document.querySelectorAll('table.list.projects tbody tr td.name a');
            const projectIds = Array.from(projectLinks).map(link => {
              const match = link.href.match(/\/projects\/([^\/]+)/);
              return match ? match[1] : null;
            }).filter(id => id);
            
            // Загружаем прогресс для всех проектов
            loadProgressForCSV(projectIds);
          }
          
          function loadProgressForCSV(projectIds) {
            const progressData = {};
            let loadedCount = 0;
            
            projectIds.forEach(projectId => {
              fetch(`/projects/${projectId}/project_progress`, {
                headers: {
                  'Accept': 'application/json',
                  'X-Requested-With': 'XMLHttpRequest'
                }
              })
              .then(response => response.json())
              .then(data => {
                progressData[projectId] = data.progress_percentage || 0;
                loadedCount++;
                
                if (loadedCount === projectIds.length) {
                  // Все данные загружены, модифицируем CSV
                  modifyCSVWithProgress(progressData);
                }
              })
              .catch(error => {
                console.error('Error loading progress for project', projectId, error);
                progressData[projectId] = 0;
                loadedCount++;
                
                if (loadedCount === projectIds.length) {
                  modifyCSVWithProgress(progressData);
                }
              });
            });
          }
          
          function modifyCSVWithProgress(progressData) {
            // Находим ссылку на CSV экспорт
            const csvLink = document.querySelector('a[href*="format=csv"]');
            if (!csvLink) return;
            
            // Сохраняем оригинальную ссылку
            const originalHref = csvLink.href;
            
            // Модифицируем ссылку для добавления данных прогресса
            const url = new URL(originalHref);
            url.searchParams.set('progress_data', JSON.stringify(progressData));
            
            csvLink.href = url.toString();
          }
        </script>
      HTML
    end
  end
  
  # Основной хук для подключения JS и CSS
  def view_layouts_base_html_head(context = {})
    tags = []
    
    # Подключаем CSS
    tags << stylesheet_link_tag('project_progress', :plugin => 'redmine_project_progress')
    
    # Подключаем JavaScript только на странице проектов
    if projects_page?(context)
      tags << javascript_include_tag('project_progress', :plugin => 'redmine_project_progress')
      
      # Добавляем script для инициализации с настройками по умолчанию
      tags << <<~HTML
        <script>
          // Передаем настройки в JavaScript (значения по умолчанию)
          window.projectProgressSettings = {
            js_init_delay: 1000,
            js_retry_interval: 500,
            js_max_retry_time: 10000,
            js_animation_duration: 300
          };
          
          document.addEventListener('DOMContentLoaded', function() {
            // Ждем появления проектов в любом представлении
            const checkProjects = setInterval(function() {
              const hasProjects = 
                document.querySelector('table.list.projects') ||
                document.querySelector('div.projects.list') ||
                document.querySelector('div.projects.grid');
              
              if (hasProjects && typeof initializeProjectProgress === 'function') {
                clearInterval(checkProjects);
                initializeProjectProgress();
              }
            }, window.projectProgressSettings.js_retry_interval);
            
            // Таймаут на случай если проекты никогда не появятся
            setTimeout(function() {
              clearInterval(checkProjects);
            }, window.projectProgressSettings.js_max_retry_time);
          });
        </script>
      HTML
    end
    
    tags.join("\n")
  end
  
  private
  
  def projects_page?(context)
    # Проверяем, что это контроллер проектов
    controller = context[:controller]
    return false unless controller.is_a?(ProjectsController)
    
    # Исключаем страницы создания/редактирования проектов
    request = context[:request]
    !request.path.include?('/projects/new') &&
    !request.path.include?('/projects/create') &&
    !request.path.include?('/projects/edit')
  end
  
end

# Инициализируем патч для CSV экспорта
RedmineProjectProgressHooks.included(RedmineProjectProgressHooks)

# Отладочная информация
Rails.logger.info "Project Progress: Hooks loaded successfully"