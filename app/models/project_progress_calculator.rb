class ProjectProgressCalculator
  def self.calculate(project)
    return empty_progress if project.nil?

    # Получаем настройки плагина
    settings = get_plugin_settings
    
    # Проверяем кэш если включен
    if settings['cache_calculation'] == '1' || settings['cache_calculation'] == true
      cached_result = get_cached_progress(project, settings)
      return cached_result if cached_result
    end


    # Применяем фильтры к задачам
    issues = get_filtered_issues(project, settings)
    
        # Отладочная информация
        if settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true
          Rails.logger.info "Project Progress Debug for #{project.name}:"
          Rails.logger.info "  Total visible issues: #{project.issues.visible.count}"
          Rails.logger.info "  Filtered issues: #{issues.count}"
          Rails.logger.info "  Settings: include_closed_issues=#{settings['include_closed_issues']}, include_subtasks=#{settings['include_subtasks']}"
          Rails.logger.info "  Minimum issues count: #{settings['minimum_issues_count']}"
          Rails.logger.info "  Exclude trackers: #{settings['exclude_trackers']}"
          Rails.logger.info "  Exclude priorities: #{settings['exclude_priorities']}"
        end
    
    return empty_progress if issues.empty?
    
    # Проверяем минимальное количество задач
    if settings['minimum_issues_count'].to_i > 0 && issues.count < settings['minimum_issues_count'].to_i
      Rails.logger.info "Project Progress: Not enough issues (#{issues.count} < #{settings['minimum_issues_count']})" if settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true
      return empty_progress
    end
    
    if project.children.any?
      {
        :total_issues => total_issues_count(project),
        :closed_issues => closed_issues_count(project),
        :progress_percentage => calculate_parent_project_progress(project),
        :by_tracker => progress_by_tracker(project),
        :by_version => progress_by_version(project),
        :by_status => progress_by_status(project),
        :calculation_method => settings['default_calculation_method'],
        :is_parent_project => true
      }
    else
      # Используем настройки для выбора метода расчета
      calculation_method = settings['default_calculation_method']
      Rails.logger.info "Project Progress: Selected calculation method: #{calculation_method}" if settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true
      
      
      # Рассчитываем прогресс по отфильтрованным задачам
      progress_percentage = calculate_progress_by_method(issues, calculation_method, project, settings)
      total_issues_count = issues.count
      closed_issues_count = count_closed_issues(issues, settings)
      
      
      # АЛГОРИТМ 2: Fallback (независимо от подзадач)
      # Fallback срабатывает только если прогресс по статусам = 0, но есть задачи в проекте
      status_progress = calculate_progress_by_status(issues, settings)
      
      if status_progress == 0 && total_issues_count > 0
        # Проверяем, есть ли задачи с done_ratio > 0 в проекте
        all_project_issues = project.issues.visible
        all_with_progress_count = all_project_issues.where('done_ratio > 0').count
        
        if all_with_progress_count > 0
          # Используем fallback - рассчитываем прогресс по всем задачам
          all_issues = get_all_issues_for_fallback(project, settings)
          fallback_progress = calculate_average_progress(all_issues, settings)
          
          # Используем fallback только если он дает более разумный результат
          if fallback_progress > 0
            progress_percentage = fallback_progress
            # Обновляем счетчики для отражения реального состояния
            total_issues_count = all_issues.count
            closed_issues_count = count_closed_issues(all_issues, settings)
          else
          end
        else
        end
      else
      end
      
      
      result = {
       :total_issues => total_issues_count,
       :closed_issues => closed_issues_count,
       :total_story_points => total_story_points(issues),
       :weighted_progress => calculate_weighted_progress(issues, project, settings),
       :average_progress => calculate_average_progress(issues, settings),
       :progress_percentage => progress_percentage,
       :by_tracker => progress_by_tracker(project),
       :by_version => progress_by_version(project),
       :by_status => progress_by_status(project),
       :by_priority => progress_by_priority(project),
       :calculation_method => settings['default_calculation_method'],
       :is_parent_project => false
      }
      
      # Сохраняем в кэш если включен
      if settings['cache_calculation'] == '1' || settings['cache_calculation'] == true
        cache_progress(project, result, settings)
      end
      
      result
    end
  end

  private
  
  # Фильтрация задач согласно настройкам
  def self.get_filtered_issues(project, settings)
    # Получаем задачи из самого проекта и всех дочерних проектов
    all_project_ids = [project.id] + project.children.pluck(:id)
    issues = Issue.where(:project_id => all_project_ids).visible
    
    # Применяем фильтры последовательно
    issues = apply_subtask_filter(issues, settings)
    issues = apply_closed_issues_filter(issues, settings)
    issues = apply_tracker_filter(issues, settings)
    issues = apply_priority_filter(issues, settings)
    
    # Логирование только при включенной отладке
    if settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true
      Rails.logger.info "Project Progress: Filtered issues for #{project.name}: #{issues.count}"
    end
    
    issues
  end
  
  private
  
  def self.apply_subtask_filter(issues, settings)
    if settings['include_subtasks'] != true && settings['include_subtasks'] != '1'
      issues = issues.where(:parent_id => nil)
    end
    issues
  end
  
  def self.apply_closed_issues_filter(issues, settings)
    unless settings['include_closed_issues'] == true || settings['include_closed_issues'] == '1'
      issues = issues.where.not(:status_id => closed_status_ids)
    end
    issues
  end
  
  def self.apply_tracker_filter(issues, settings)
    if settings['exclude_trackers'].present?
      exclude_tracker_names = settings['exclude_trackers'].split(',').map(&:strip)
      exclude_tracker_ids = Tracker.where(:name => exclude_tracker_names).pluck(:id)
      if exclude_tracker_ids.any?
        issues = issues.where.not(:tracker_id => exclude_tracker_ids)
      end
    end
    issues
  end
  
  def self.apply_priority_filter(issues, settings)
    if settings['exclude_priorities'].present?
      exclude_priority_names = settings['exclude_priorities'].split(',').map(&:strip)
      exclude_priority_ids = IssuePriority.where(:name => exclude_priority_names).pluck(:id)
      if exclude_priority_ids.any?
        issues = issues.where.not(:priority_id => exclude_priority_ids)
      end
    end
    issues
  end

  # Получение настроек плагина
  def self.get_plugin_settings
    # Не кэшируем настройки, чтобы изменения применялись сразу
    begin
      plugin = Redmine::Plugin.find(:redmine_project_progress)
      settings = plugin.settings
      
      # Читаем настройки из Setting.plugin_redmine_project_progress
      begin
        saved_settings = Setting.plugin_redmine_project_progress
        if saved_settings.present?
          result = saved_settings
        else
          # Если сохраненных настроек нет, используем настройки по умолчанию из плагина
          result = settings[:default] || settings
        end
      rescue => e
        Rails.logger.error "Project Progress: Error reading settings from Setting: #{e.message}"
        # В случае ошибки используем настройки по умолчанию
        result = settings[:default] || settings
      end
      
      # Убеждаемся, что все настройки имеют значения по умолчанию
      default_settings = {
        'default_calculation_method' => 'progress_by_status',
        'priority_weights_high' => 3.0,
        'priority_weights_normal' => 2.0,
        'priority_weights_low' => 1.0,
        'story_points_patterns' => 'story point,complexity,size,estimate',
        'parent_project_include_own_issues' => true,
        'parent_project_weight_children' => true,
        'parent_project_calculation_method' => 'weighted_average',
        'include_subtasks' => false,
        'include_closed_issues' => true,
        'minimum_issues_count' => 1,
        'exclude_trackers' => '',
        'exclude_priorities' => '',
        'enable_debug_logging' => false,
        'log_calculation_details' => false,
        'show_in_sidebar' => false,
        'cache_calculation' => false,
        'cache_duration' => 600,
        'count_100_percent_as_closed' => true
      }

      default_settings.merge(result)
    rescue => e
      Rails.logger.error "Project Progress: Error loading settings: #{e.message}"
      # Возвращаем настройки по умолчанию если плагин не найден
      {
        'default_calculation_method' => 'progress_by_status',
        'priority_weights_high' => 3.0,
        'priority_weights_normal' => 2.0,
        'priority_weights_low' => 1.0,
        'story_points_patterns' => 'story point,complexity,size,estimate',
        'parent_project_include_own_issues' => true,
        'parent_project_weight_children' => true,
        'parent_project_calculation_method' => 'weighted_average',
        'include_subtasks' => false,
        'include_closed_issues' => true,
        'minimum_issues_count' => 1,
        'exclude_trackers' => '',
        'exclude_priorities' => '',
        'enable_debug_logging' => false,
        'log_calculation_details' => false,
        'show_in_sidebar' => false,
        'cache_calculation' => false,
        'cache_duration' => 600,
        'count_100_percent_as_closed' => true
      }
    end
  end
  
  # Расчет прогресса по выбранному методу
  def self.calculate_progress_by_method(issues, method, project = nil, settings = nil)
    # Отладочная информация
    if method && (method != 'progress_by_status')
      Rails.logger.info "Project Progress: Using calculation method: #{method}"
    end
    
    case method
    when 'weighted_progress'
      result = calculate_weighted_progress(issues, project, settings)
      if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
        Rails.logger.info "Project Progress: Weighted progress result: #{result}" if method == 'weighted_progress'
      end
      result
    when 'average_progress'
      # При использовании среднего прогресса также включаем все задачи
      if project && settings
        all_issues = get_all_issues_for_fallback(project, settings)
        result = calculate_average_progress(all_issues, settings)
      else
        result = calculate_average_progress(issues, settings)
      end
      if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
        Rails.logger.info "Project Progress: Average progress result: #{result}" if method == 'average_progress'
      end
      result
    else # 'progress_by_status' или неизвестный метод
      result = calculate_progress_by_status(issues, settings)
      if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
        Rails.logger.info "Project Progress: Status progress result: #{result}" if method == 'progress_by_status'
      end
      result
    end
  end
  
  # Расчет прогресса по статусам (основной метод)
  def self.calculate_progress_by_status(issues, settings = nil)
    total = issues.count
    return 0 if total == 0
    
    # Используем done_ratio вместо статусов для более точного расчета
    total_done_ratio = issues.sum(:done_ratio) || 0
    result = (total_done_ratio / total).round(1)
    
    # Логирование только при включенной отладке
    if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
      Rails.logger.info "Project Progress: Done ratio progress calculated: #{result}% (total done_ratio: #{total_done_ratio}, issues: #{total})"
      Rails.logger.info "Project Progress: Issues done_ratios: #{issues.pluck(:done_ratio).compact}"
    end
    
    result
  end

  def self.total_issues_count(project)
    settings = get_plugin_settings
    issues = get_filtered_issues(project, settings)
    issues.count
  end
  
  def self.closed_issues_count(project)
    settings = get_plugin_settings
    issues = get_filtered_issues(project, settings)
    count_closed_issues(issues, settings)
  end
  
  # Вспомогательный метод для подсчета закрытых задач с учетом настройки
  def self.count_closed_issues(issues, settings)
    # Считаем задачи с done_ratio >= 100 как закрытые, если включена настройка
    if settings['count_100_percent_as_closed'] == true || settings['count_100_percent_as_closed'] == '1'
      # Считаем задачи с done_ratio >= 100 как закрытые
      issues.where('done_ratio >= ?', 100).count
    else
      # Считаем только задачи со статусом "закрыт"
      issues.where(:status_id => closed_status_ids).count
    end
  end

  def self.progress_percentage(project)
    total = total_issues_count(project)
    return 0 if total == 0
    
    (closed_issues_count(project).to_f / total * 100).round(1)
  end

  def self.progress_by_tracker(project)
    result = {}
    trackers = Tracker.all
    
    trackers.each do |tracker|
      tracker_issues = project.issues.visible.where(:tracker_id => tracker.id)
      total = tracker_issues.count
      closed = count_closed_issues(tracker_issues, get_plugin_settings)
      percentage = total > 0 ? (closed.to_f / total * 100).round(1) : 0
      
      result[tracker.name] = {
        :total => total,
        :closed => closed,
        :percentage => percentage
      }
    end
    result
  end

  def self.progress_by_version(project)
    result = {}
    project.versions.each do |version|
      version_issues = version.fixed_issues.visible
      total = version_issues.count
      closed = count_closed_issues(version_issues, get_plugin_settings)
      percentage = total > 0 ? (closed.to_f / total * 100).round(1) : 0
      
      result[version.name] = {
        :total => total,
        :closed => closed,
        :percentage => percentage
      }
    end
    result
  end

  def self.progress_by_status(project)
    result = {}
    IssueStatus.all.each do |status|
      count = project.issues.visible.where(:status_id => status.id).count
      result[status.name] = count if count > 0
    end
    result
  end

  def self.closed_status_ids
    # Сбрасываем кэш при каждом вызове, чтобы учитывать изменения настроек
    @closed_status_ids = nil
    @closed_status_ids ||= begin
      settings = get_plugin_settings
      
      # Если заданы названия статусов в настройках, используем их
      if settings['closed_status_names'].present?
        status_names = settings['closed_status_names'].split(',').map(&:strip)
        ids = IssueStatus.where(:name => status_names).pluck(:id)
        # Логирование только для отладки
        Rails.logger.info "Project Progress: Using custom closed status names: #{status_names} -> IDs: #{ids}"
      else
        # Иначе используем стандартную логику Redmine
        ids = IssueStatus.where(:is_closed => true).pluck(:id)
        # Логирование только для отладки
        Rails.logger.info "Project Progress: Using Redmine closed status IDs: #{ids}"
      end
      
      # Дополнительная диагностика статусов (только для отладки)
      # all_statuses = IssueStatus.all.map { |s| "#{s.id}:#{s.name}:#{s.is_closed}" }
      # Rails.logger.info "Project Progress: All statuses: #{all_statuses}"
      
      ids
    end
  end
  # Метод для расчета прогресса родительского проекта
  def self.calculate_parent_project_progress(project)
    settings = get_plugin_settings
    
    # Получаем все дочерние проекты
    child_projects = project.children.visible
    
    # Получаем задачи родительского проекта с учетом настроек
    direct_issues = if settings['parent_project_include_own_issues'] == true || settings['parent_project_include_own_issues'] == '1'
      get_filtered_issues(project, settings)
    else
      []
    end
    
    # Определяем метод расчета
    calculation_method = settings['parent_project_calculation_method'] || 'weighted_average'
    
    if calculation_method == 'simple_average'
      # Простое среднее - все проекты имеют равный вес
      calculate_simple_average_progress(child_projects, direct_issues)
    else
      # Взвешенное среднее по количеству задач (по умолчанию)
      calculate_weighted_average_progress(child_projects, direct_issues)
    end
  end
  
  # Простое среднее - все проекты имеют равный вес
  def self.calculate_simple_average_progress(child_projects, direct_issues)
    total_progress = 0.0
    project_count = 0
    
    # Учитываем прогресс по дочерним проектам
    child_projects.each do |child_project|
      child_progress = calculate(child_project) # Рекурсивный вызов
      if child_progress[:total_issues] > 0
        total_progress += child_progress[:progress_percentage]
        project_count += 1
      end
    end
    
    # Учитываем задачи непосредственно в родительском проекте
    if direct_issues.any?
      project_issues_progress = direct_issues.average(:done_ratio) || 0
      total_progress += project_issues_progress
      project_count += 1
    end
    
    return 0 if project_count == 0
    
    (total_progress / project_count).round(1)
  end
  
  # Взвешенное среднее по количеству задач
  def self.calculate_weighted_average_progress(child_projects, direct_issues)
    total_issues = 0
    total_progress = 0.0
    
    # Учитываем прогресс по дочерним проектам
    child_projects.each do |child_project|
      child_progress = calculate(child_project) # Рекурсивный вызов
      total_issues += child_progress[:total_issues]
      
      if child_progress[:total_issues] > 0
        total_progress += child_progress[:progress_percentage] * child_progress[:total_issues]
      end
    end
    
    # Учитываем задачи непосредственно в родительском проекте
    if direct_issues.any?
      project_issues_progress = direct_issues.average(:done_ratio) || 0
      total_progress += project_issues_progress * direct_issues.count
      total_issues += direct_issues.count
    end
    
    return 0 if total_issues == 0
    
    (total_progress / total_issues).round(1)
  end



  def self.empty_progress
    {
      :total_issues => 0,
      :total_story_points => 0,
      :weighted_progress => 0,
      :average_progress => 0,
      :progress_percentage => 0,
      :by_tracker => {},
      :by_version => {},
      :by_status => {},
      :by_priority => {},
      :calculation_method => 'no_issues'
    }
  end

  # Основной расчет взвешенного прогресса по стори поинтам
  def self.calculate_weighted_progress(issues, project = nil, settings = nil)
    total_points = total_story_points(issues)
    if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
      Rails.logger.info "Project Progress: Total story points: #{total_points}" if total_points > 0
    end
    
    if total_points == 0
      if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
      Rails.logger.info "Project Progress: No story points found, falling back to average progress"
    end
      # При fallback используем все задачи (включая закрытые)
      if project && settings
        all_issues = get_all_issues_for_fallback(project, settings)
        return calculate_average_progress(all_issues, settings)
      else
        return calculate_average_progress(issues, settings)
      end
    end

    weighted_sum = 0.0
    issues.each do |issue|
      issue_points = story_points(issue) || 0
      issue_done_ratio = issue.done_ratio || 0
      weight = total_points > 0 ? issue_points / total_points : 1.0 / issues.count
      weighted_sum += issue_done_ratio * weight
    end

    result = weighted_sum.round(1)
    if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
      Rails.logger.info "Project Progress: Weighted progress calculated: #{result}"
    end
    result
  end

  # Получение всех задач для fallback расчета (включая закрытые)
  def self.get_all_issues_for_fallback(project, settings)
    # Получаем задачи из самого проекта и всех дочерних проектов
    all_project_ids = [project.id] + project.children.pluck(:id)
    all_issues = Issue.where(:project_id => all_project_ids)
    
    if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
      Rails.logger.info "Project Progress: Fallback - getting all issues for #{project.name}:"
      Rails.logger.info "  All issues count: #{all_issues.count}"
    end
    
    # Применяем visible scope для корректного расчета
    issues = all_issues.visible
    if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
      Rails.logger.info "Project Progress: Fallback - visible issues count: #{issues.count}"
      Rails.logger.info "Project Progress: Fallback - including all visible issues (open, closed, and subtasks)"
    end
    
    # Применяем те же фильтры, что и в основном методе, но включаем подзадачи и закрытые задачи
    if settings['include_subtasks'] == true || settings['include_subtasks'] == '1'
      if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
        Rails.logger.info "Project Progress: Fallback - including subtasks: #{issues.count} issues"
      end
    else
      # Исключаем подзадачи только если явно настроено
      issues = issues.where(:parent_id => nil)
      if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
        Rails.logger.info "Project Progress: Fallback - excluding subtasks: #{issues.count} issues"
      end
    end
    
    # Всегда включаем закрытые задачи для fallback
    if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
      Rails.logger.info "Project Progress: Fallback - including all issues (open and closed): #{issues.count}"
    end
    
    issues
  end

  # Расчет среднего арифметического прогресса
  def self.calculate_average_progress(issues, settings = nil)
    # Отладочная информация о done_ratio
    done_ratios = issues.pluck(:done_ratio).compact
    if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
      Rails.logger.info "Project Progress: Done ratios found: #{done_ratios.inspect}"
      Rails.logger.info "Project Progress: Issues with done_ratio > 0: #{issues.where('done_ratio > 0').count}"
    end
    
    average = issues.average(:done_ratio)
    result = average ? average.round(1) : 0
    if settings && (settings['enable_debug_logging'] == '1' || settings['enable_debug_logging'] == true)
      Rails.logger.info "Project Progress: Average progress calculated: #{result} (from #{issues.count} issues, average: #{average})"
    end
    result
  end

  # Сумма стори поинтов всех задач
  def self.total_story_points(issues)
    issues.sum { |issue| story_points(issue) || 0 }.to_f
  end

  # Получение стори поинтов задачи из пользовательского поля
  def self.story_points(issue)
    settings = get_plugin_settings
    patterns = settings['story_points_patterns'].split(',').map(&:strip)
    
    # Поиск пользовательского поля с стори поинтами
    story_points_field = issue.custom_field_values.find do |field|
      patterns.any? { |pattern| field.custom_field.name =~ /#{pattern}/i }
    end

    if story_points_field && story_points_field.value.present?
      story_points_field.value.to_f
    else
      # Если нет стори поинтов, используем вес приоритета
      priority_weight(issue.priority)
    end
  end

  # Вес приоритета для задач без стори поинтов
  def self.priority_weight(priority)
    return 1.0 if priority.nil?

    settings = get_plugin_settings
    
    case priority.name.downcase
    when /high|urgent|critical/ then settings['priority_weights_high'].to_f
    when /normal|medium/ then settings['priority_weights_normal'].to_f
    when /low|minor/ then settings['priority_weights_low'].to_f
    else 1.0
    end
  end

  # Прогресс по типам задач
  def self.progress_by_tracker(project)
    result = {}
    trackers = Tracker.all

    trackers.each do |tracker|
      tracker_issues = project.issues.visible.where(:tracker_id => tracker.id)
      total = tracker_issues.count
      next if total == 0

      total_points = total_story_points(tracker_issues)
      weighted_progress = calculate_weighted_progress(tracker_issues)
      average_progress = calculate_average_progress(tracker_issues, get_plugin_settings)

      result[tracker.name] = {
        :total => total,
        :total_story_points => total_points.round(1),
        :weighted_progress => weighted_progress,
        :average_progress => average_progress
      }
    end

    result.delete_if { |k, v| v[:total] == 0 }
  end

  # Прогресс по версиям
  def self.progress_by_version(project)
    result = {}
    project.versions.each do |version|
      version_issues = version.fixed_issues.visible
      total = version_issues.count
      next if total == 0

      total_points = total_story_points(version_issues)
      weighted_progress = calculate_weighted_progress(version_issues)
      average_progress = calculate_average_progress(version_issues, get_plugin_settings)

      result[version.name] = {
        :total => total,
        :total_story_points => total_points.round(1),
        :weighted_progress => weighted_progress,
        :average_progress => average_progress
      }
    end

    result.delete_if { |k, v| v[:total] == 0 }
  end

  # Распределение по статусам
  def self.progress_by_status(project)
    result = {}
    IssueStatus.all.each do |status|
      status_issues = project.issues.visible.where(:status_id => status.id)
      count = status_issues.count
      next if count == 0

      total_points = total_story_points(status_issues)
      average_progress = calculate_average_progress(status_issues, get_plugin_settings)

      result[status.name] = {
        :count => count,
        :total_story_points => total_points.round(1),
        :average_progress => average_progress
      }
    end

    result
  end

  # Прогресс по приоритетам
  def self.progress_by_priority(project)
    result = {}
    IssuePriority.all.each do |priority|
      priority_issues = project.issues.visible.where(:priority_id => priority.id)
      count = priority_issues.count
      next if count == 0

      total_points = total_story_points(priority_issues)
      weighted_progress = calculate_weighted_progress(priority_issues)
      average_progress = calculate_average_progress(priority_issues, get_plugin_settings)

      result[priority.name] = {
        :count => count,
        :total_story_points => total_points.round(1),
        :weighted_progress => weighted_progress,
        :average_progress => average_progress
      }
    end

    result.delete_if { |k, v| v[:count] == 0 }
  end
  
  # Кэширование прогресса
  def self.get_cached_progress(project, settings)
    cache_key = "project_progress_#{project.id}_#{project.updated_at.to_i}"
    cache_duration = (settings['cache_duration'] || 600).to_i.seconds
    
    Rails.cache.read(cache_key)
  end
  
  def self.cache_progress(project, result, settings)
    cache_key = "project_progress_#{project.id}_#{project.updated_at.to_i}"
    cache_duration = (settings['cache_duration'] || 600).to_i.seconds
    
    Rails.cache.write(cache_key, result, expires_in: cache_duration)
  end
  
  def self.clear_cache(project = nil)
    if project
      # Очищаем кэш для конкретного проекта
      cache_key_pattern = "project_progress_#{project.id}_*"
      Rails.cache.delete_matched(cache_key_pattern)
    else
      # Очищаем весь кэш прогресса
      Rails.cache.delete_matched("project_progress_*")
    end
  end
end
