// Project Progress Plugin - Main functionality

// Глобальные настройки (будут загружены с сервера)
window.projectProgressSettings = {
    js_init_delay: 1000,
    js_retry_interval: 500,
    js_max_retry_time: 10000,
    js_animation_duration: 300
};

function initializeProjectProgress() {
    // Добавляем переключатель прогресса
    addProgressToggle();
    
    // Добавляем кнопку экспорта
    addExportButton();
    
    // Проверяем все возможные представления проектов
    const success = 
        initializeTableView() || 
        initializePanelView() || 
        initializeCardView() ||
        initializeAlternativeSearch();
    
    return success;
}

// Добавление кнопки экспорта
function addExportButton() {
    // Проверяем, не добавлена ли уже кнопка
    if (document.querySelector('.project-progress-export-button')) {
        return;
    }
    
    // Создаем кнопку экспорта
    const exportButton = document.createElement('div');
    exportButton.className = 'project-progress-export-button';
    exportButton.style.cssText = 'margin: 20px 0; padding: 15px; background: #f9f9f9; border: 1px solid #ddd; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);';
    
    exportButton.innerHTML = `
        <h3 style="margin: 0 0 10px 0; color: #333; font-size: 16px;">📊 Экспорт проектов с прогрессом</h3>
        <p style="margin: 0 0 15px 0; color: #666; font-size: 14px;">
          Экспортируйте все проекты в CSV файл с информацией о прогрессе выполнения.
        </p>
        <a href="/project_progress_export.csv" class="icon icon-download" 
           style="display: inline-block; padding: 10px 20px; background: #4CAF50; color: white; text-decoration: none; border-radius: 4px; font-weight: bold; font-size: 14px; transition: background-color 0.3s ease;"
           onmouseover="this.style.backgroundColor='#45a049'" 
           onmouseout="this.style.backgroundColor='#4CAF50'">
          📥 Скачать CSV с прогрессом
        </a>
    `;
    
    // Ищем место для вставки кнопки - в конец страницы после списка проектов
    const content = document.querySelector('#content, .main, .content, main');
    if (content) {
        // Ищем таблицу проектов или панель проектов
        const projectsTable = content.querySelector('table.list.projects');
        const projectsPanel = content.querySelector('.projects');
        
        if (projectsTable) {
            // Если есть таблица проектов, вставляем после неё
            projectsTable.parentNode.insertBefore(exportButton, projectsTable.nextSibling);
            console.log('Project Progress: Export button added after projects table');
        } else if (projectsPanel) {
            // Если есть панель проектов, вставляем после неё
            projectsPanel.parentNode.insertBefore(exportButton, projectsPanel.nextSibling);
            console.log('Project Progress: Export button added after projects panel');
        } else {
            // Если ничего не найдено, вставляем в конец контента
            content.appendChild(exportButton);
            console.log('Project Progress: Export button added to end of content');
        }
    } else {
        console.log('Project Progress: No suitable container found for export button');
    }
}

// Добавление переключателя прогресса
function addProgressToggle() {
    // Проверяем, не добавлен ли уже переключатель
    if (document.querySelector('.project-progress-toggle')) {
        return;
    }
    
    // Создаем переключатель
    const toggleContainer = document.createElement('div');
    toggleContainer.className = 'project-progress-toggle';
    toggleContainer.style.cssText = 'margin: 10px 0; padding: 15px; background: #e8f4fd; border: 1px solid #b3d9ff; border-radius: 6px; display: flex; align-items: center; gap: 15px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);';
    
    toggleContainer.innerHTML = `
        <div style="display: flex; align-items: center; gap: 10px;">
            <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; font-weight: bold; color: #333; font-size: 14px;">
                <input type="checkbox" id="progressToggle" checked style="transform: scale(1.3); cursor: pointer;">
                <span>📊 Показывать прогресс проектов</span>
            </label>
        </div>
        <div style="font-size: 13px; color: #666; flex: 1;">
            Включите/выключите отображение прогресса выполнения для всех проектов на странице
        </div>
    `;
    
    // Ищем место для вставки переключателя - в верхней части страницы
    const content = document.querySelector('#content, .main, .content, main');
    if (content) {
        // Ищем заголовок страницы или первый элемент
        const pageTitle = content.querySelector('h2, .page-title, .main-title, h1');
        if (pageTitle) {
            pageTitle.parentNode.insertBefore(toggleContainer, pageTitle.nextSibling);
            console.log('Project Progress: Toggle added after page title');
        } else {
            content.insertBefore(toggleContainer, content.firstChild);
            console.log('Project Progress: Toggle added to page top');
        }
    } else {
        console.log('Project Progress: No suitable container found for toggle');
    }
    
    // Добавляем обработчик события
    const toggle = document.getElementById('progressToggle');
    if (toggle) {
        toggle.addEventListener('change', function() {
            toggleProgressDisplay(this.checked);
        });
        
        // Восстанавливаем состояние из localStorage
        restoreProgressToggleState();
    }
}

// Переключение отображения прогресса
function toggleProgressDisplay(show) {
    const progressElements = document.querySelectorAll('.project-progress-bar, .project-progress-text, .project-progress-container, .project-progress-panel, .project-progress-card, .progress-cell');
    
    progressElements.forEach(element => {
        if (show) {
            element.style.display = '';
            element.style.visibility = 'visible';
            element.style.opacity = '1';
            
            // Если элемент в состоянии "Загрузка прогресса", запускаем загрузку
            if (element.innerHTML.includes('Загрузка прогресса') || element.innerHTML.includes('загрузка...') || element.innerHTML.includes('Загрузка...')) {
                const projectId = extractProjectIdFromElement(element);
                if (projectId) {
                    loadProjectProgress(projectId, element, getViewTypeFromElement(element));
                }
            }
        } else {
            element.style.display = 'none';
            element.style.visibility = 'hidden';
            element.style.opacity = '0';
        }
    });
    
    // Сохраняем состояние в localStorage
    localStorage.setItem('projectProgressVisible', show);
    
    console.log(`Project Progress: Display ${show ? 'enabled' : 'disabled'}`);
}

// Восстановление состояния переключателя
function restoreProgressToggleState() {
    const savedState = localStorage.getItem('projectProgressVisible');
    const toggle = document.getElementById('progressToggle');
    
    if (toggle) {
        if (savedState !== null) {
            toggle.checked = savedState === 'true';
        } else {
            // По умолчанию включен
            toggle.checked = true;
        }
        
        // Применяем состояние сразу
        toggleProgressDisplay(toggle.checked);
        
        // Также применяем к уже существующим элементам
        const existingElements = document.querySelectorAll('.project-progress-bar, .project-progress-text, .project-progress-container, .project-progress-panel, .project-progress-card, .progress-cell');
        existingElements.forEach(element => {
            if (!toggle.checked) {
                element.style.display = 'none';
            }
        });
    }
}

// Инициализация для табличного представления
function initializeTableView() {
    const table = document.querySelector('table.list.projects');
    if (!table) {
        return false;
    }
    
    addProgressColumnToTable(table);
    return true;
}

// Инициализация для панельного представления (ul/li)
function initializePanelView() {
    // Ищем списки проектов в панельном представлении
    const projectLists = document.querySelectorAll('ul.projects.root');    
    let foundProjects = false;
    
    projectLists.forEach(list => {
        const projectItems = list.querySelectorAll('li');
        if (projectItems.length > 0) {
            addProgressToPanelView(list, projectItems);
            foundProjects = true;
        }
    });
    
    return foundProjects;
}

// Инициализация для плиточного представления
function initializeCardView() {
    const projectGrid = document.querySelector('div.projects.grid, .grid.projects, .project-cards');
    if (!projectGrid) {
        return false;
    }
    
    addProgressToCardView(projectGrid);
    return true;
}

// Альтернативный поиск проектов
function initializeAlternativeSearch() {
    // Ищем все ссылки на проекты, но только в подходящих контейнерах
    const projectLinks = document.querySelectorAll('a[href*="/projects/"]');
    const processedProjects = new Set();
    
    let foundCount = 0;
    
    projectLinks.forEach(link => {
        // Пропускаем ссылки на создание проектов и служебные страницы
        if (link.href.includes('/projects/new') || 
            link.href.includes('/projects/create') ||
            link.href.includes('/projects/edit') ||
            link.href.includes('/projects/settings')) {
            return;
        }
        
        // Пропускаем ссылки в навигации, заголовках и других служебных местах
        if (isInNavigationOrHeader(link)) {
            return;
        }
        
        const projectId = extractProjectId(link.href);
        if (!projectId || processedProjects.has(projectId)) {
            return;
        }
        
        processedProjects.add(projectId);
        
        // Находим родительский контейнер проекта
        const container = findProjectContainer(link);
        if (!container || container.querySelector('.project-progress-container')) {
            return;
        }
        
        // Проверяем, что контейнер подходит для отображения прогресса
        if (!isSuitableContainerForProgress(container)) {
            return;
        }
        
        addProgressToContainer(container, projectId);
        foundCount++;
    });
    
    return foundCount > 0;
}

// Добавление колонки в табличное представление
function addProgressColumnToTable(table) {
    // Добавляем заголовок
    if (!addProgressHeaderToTable(table)) {
        return;
    }
    
    // Добавляем ячейки для каждой строки
    addProgressCellsToTable(table);
}

function addProgressHeaderToTable(table) {
    const headerRow = table.querySelector('thead tr');
    if (!headerRow) {
        return false;
    }
    
    if (headerRow.querySelector('.progress-column-header')) {
        return false;
    }
    
    const header = document.createElement('th');
    header.className = 'progress-column-header';
    header.textContent = 'Прогресс';
    header.style.cssText = 'width: 180px; text-align: center; vertical-align: middle; font-weight: bold; background: #f8f8f8; padding: 8px;';
    
    headerRow.appendChild(header);
    return true;
}

function addProgressCellsToTable(table) {
    const rows = table.querySelectorAll('tbody tr');
    
    rows.forEach((row, index) => {
        setTimeout(() => {
            addProgressCellToTableRow(row);
        }, index * (window.projectProgressSettings.js_animation_duration || 100));
    });
}

function addProgressCellToTableRow(row) {
    if (row.querySelector('.progress-cell')) {
        return;
    }
    
    const projectLink = row.querySelector('td.name a, a[href*="/projects/"]');
    if (!projectLink) return;
    
    const projectId = extractProjectId(projectLink.href);
    if (!projectId) return;
    
    const cell = document.createElement('td');
    cell.className = 'progress-cell';
    cell.style.cssText = 'text-align: center; vertical-align: middle; padding: 8px;';
    cell.innerHTML = '<div style="color: #999; font-style: italic; font-size: 12px;">загрузка...</div>';
    
    row.appendChild(cell);
    
    // Проверяем состояние переключателя перед загрузкой
    const toggle = document.getElementById('progressToggle');
    if (toggle && !toggle.checked) {
        cell.style.display = 'none';
        return;
    }
    
    loadProjectProgress(projectId, cell, 'table');
}

// Добавление прогресса в панельное представление (ul/li)
function addProgressToPanelView(list, projectItems) {
    
    projectItems.forEach((projectItem, index) => {
        // Пропускаем элементы, которые не являются проектами
        if (!isProjectListItem(projectItem)) {
            return;
        }
        
        setTimeout(() => {
            addProgressToPanelProject(projectItem);
        }, index * (window.projectProgressSettings.js_animation_duration || 100));
    });
}

// Проверка, является ли элемент li проектом
function isProjectListItem(listItem) {
    // Проверяем по классам
    const className = listItem.className || '';
    if (className.includes('project') || className.includes('issue') || className.includes('entity')) {
        return true;
    }
    
    // Проверяем по наличию ссылки на проект
    const projectLink = listItem.querySelector('a[href*="/projects/"]');
    if (projectLink && !projectLink.href.includes('/projects/new')) {
        return true;
    }
    
    return false;
}

function addProgressToPanelProject(projectItem) {
    if (projectItem.querySelector('.project-progress-container')) {
        return;
    }
    
    const projectLink = projectItem.querySelector('a[href*="/projects/"]');
    if (!projectLink) {
        return;
    }
    
    const projectId = extractProjectId(projectLink.href);
    if (!projectId) {
        return;
    }
    
    // Создаем контейнер для прогресса
    const progressContainer = document.createElement('div');
    progressContainer.className = 'project-progress-panel';
    progressContainer.style.cssText = 'margin: 8px 0; padding: 10px; background: #f9f9f9; border-radius: 4px; border: 1px solid #eee;';
    progressContainer.innerHTML = '<div style="color: #999; font-style: italic; font-size: 12px;">Загрузка прогресса...</div>';
    
    // Вставляем после ссылки на проект или в конец элемента
    projectItem.appendChild(progressContainer);
    
    // Проверяем состояние переключателя перед загрузкой
    const toggle = document.getElementById('progressToggle');
    if (toggle && !toggle.checked) {
        progressContainer.style.display = 'none';
        return;
    }
    
    loadProjectProgress(projectId, progressContainer, 'panel');
}

// Добавление прогресса в плиточное представление
function addProgressToCardView(projectGrid) {
    const projectCards = projectGrid.querySelectorAll('div.project-card, article.project, .project, div[class*="card"]');
    if (projectCards.length === 0) {
        return;
    }
    
    
    projectCards.forEach((projectCard, index) => {
        setTimeout(() => {
            addProgressToCardProject(projectCard);
        }, index * (window.projectProgressSettings.js_animation_duration || 100));
    });
}

function addProgressToCardProject(projectCard) {
    if (projectCard.querySelector('.project-progress-container')) {
        return;
    }
    
    const projectLink = projectCard.querySelector('h3 a, h2 a, .name a, a[href*="/projects/"]');
    if (!projectLink) return;
    
    const projectId = extractProjectId(projectLink.href);
    if (!projectId) return;
    
    // Создаем контейнер для прогресса
    const progressContainer = document.createElement('div');
    progressContainer.className = 'project-progress-card';
    progressContainer.style.cssText = 'margin: 10px 0; padding: 8px; background: rgba(0,0,0,0.03); border-radius: 3px; text-align: center;';
    progressContainer.innerHTML = '<div style="color: #999; font-size: 12px;">Загрузка...</div>';
    
    // Вставляем в карточку
    projectCard.appendChild(progressContainer);
    
    // Проверяем состояние переключателя перед загрузкой
    const toggle = document.getElementById('progressToggle');
    if (toggle && !toggle.checked) {
        progressContainer.style.display = 'none';
        return;
    }
    
    loadProjectProgress(projectId, progressContainer, 'card');
}

// Вспомогательные функции для альтернативного поиска
function isInNavigationOrHeader(link) {
    // Проверяем, находится ли ссылка в навигации, заголовке или других служебных местах
    const navigationSelectors = [
        'nav', 'header', '.header', '.navigation', '.nav',
        '.breadcrumb', '.breadcrumbs', '.menu', '.sidebar',
        '.top-menu', '.main-menu', '.user-menu',
        '.contextual', '.context-menu'
    ];
    
    for (const selector of navigationSelectors) {
        if (link.closest(selector)) {
            return true;
        }
    }
    
    // Проверяем, находится ли ссылка в заголовке страницы
    const pageHeader = link.closest('h1, h2, h3, h4, h5, h6');
    if (pageHeader) {
        return true;
    }
    
    // Проверяем, находится ли ссылка в области поиска
    const searchArea = link.closest('.search, .search-box, .search-form, .search-container');
    if (searchArea) {
        return true;
    }
    
    // Проверяем, находится ли ссылка в верхней части страницы (выше основного контента)
    const mainContent = document.querySelector('#content, .main, .content, main');
    if (mainContent && link.getBoundingClientRect().top < mainContent.getBoundingClientRect().top) {
        return true;
    }
    
    return false;
}

function isSuitableContainerForProgress(container) {
    // Проверяем, подходит ли контейнер для отображения прогресса
    const unsuitableSelectors = [
        'nav', 'header', '.header', '.navigation', '.nav',
        '.breadcrumb', '.breadcrumbs', '.menu', '.sidebar',
        '.top-menu', '.main-menu', '.user-menu',
        '.contextual', '.context-menu', '.search'
    ];
    
    for (const selector of unsuitableSelectors) {
        if (container.closest(selector)) {
            return false;
        }
    }
    
    // Проверяем, что контейнер не слишком маленький
    const rect = container.getBoundingClientRect();
    if (rect.width < 200 || rect.height < 50) {
        return false;
    }
    
    return true;
}

function findProjectContainer(link) {
    // Поднимаемся вверх по DOM чтобы найти контейнер проекта
    let container = link.closest('li, div.project, tr, article, .entity, .item');
    
    if (!container) {
        // Если не нашли стандартный контейнер, используем родительский элемент
        container = link.parentElement;
    }
    
    return container;
}

function addProgressToContainer(container, projectId) {
    const progressContainer = document.createElement('div');
    progressContainer.className = 'project-progress-container';
    progressContainer.style.cssText = 'margin: 8px 0; padding: 10px; background: #f9f9f9; border-radius: 4px; border: 1px solid #eee;';
    progressContainer.innerHTML = '<div style="color: #999; font-style: italic; font-size: 12px;">Загрузка прогресса...</div>';
    
    container.appendChild(progressContainer);
    
    // Проверяем состояние переключателя перед загрузкой
    const toggle = document.getElementById('progressToggle');
    if (toggle && !toggle.checked) {
        progressContainer.style.display = 'none';
        return;
    }
    
    loadProjectProgress(projectId, progressContainer, 'auto');
}

// Загрузка данных прогресса
function loadProjectProgress(projectId, container, viewType) {
    
    fetch(`/projects/${projectId}/project_progress`, {
        headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
        }
    })
    .then(response => {
        if (!response.ok) throw new Error(`HTTP error: ${response.status}`);
        return response.json();
    })
    .then(data => {
        // Отладочная информация
        console.log('Project Progress: API Response for project', projectId, ':', data);
        updateProgressDisplay(container, data, viewType);
    })
    .catch(error => {
        console.error('Project Progress: Error loading progress:', error);
        showProgressError(container, viewType);
    });
}

// Обновление отображения прогресса в зависимости от типа представления
function updateProgressDisplay(container, data, viewType) {
    console.log('Project Progress: updateProgressDisplay called with:', { data, viewType });
    
    if (!data || typeof data.progress_percentage === 'undefined') {
        console.log('Project Progress: Invalid data or missing progress_percentage:', data);
        showProgressError(container, viewType);
        return;
    }
    
    const percent = data.progress_percentage;
    const closed = data.closed_issues || 0;
    const total = data.total_issues || 0;
    const color = getProgressColor(percent);
    
    console.log('Project Progress: Display values:', { percent, closed, total, color });
    
    switch (viewType) {
        case 'table':
            updateTableView(container, percent, closed, total, color);
            break;
        case 'panel':
            updatePanelView(container, percent, closed, total, color);
            break;
        case 'card':
            updateCardView(container, percent, closed, total, color);
            break;
        default:
            updateAutoView(container, percent, closed, total, color);
    }
    
    // Проверяем состояние переключателя после обновления
    const toggle = document.getElementById('progressToggle');
    if (toggle && !toggle.checked) {
        toggleProgressDisplay(false);
    }
}

function updateTableView(container, percent, closed, total, color) {
    // Проверяем, находимся ли мы в списке проектов (table.list.projects)
    const isProjectList = container.closest('table.list.projects');
    
    if (isProjectList) {
        // Для списка проектов показываем только цифры
        updateProjectListNumbers(container, percent, closed, total, color);
    } else {
        // Для других таблиц показываем полный прогресс-бар
        container.innerHTML = `
            <div title="${percent}% завершено (${closed}/${total} задач)" style="display: inline-block; text-align: center;">
                <div style="width: 100px; height: 12px; background: #f0f0f0; border: 1px solid #ddd; border-radius: 6px; margin: 0 auto; overflow: hidden;">
                    <div style="width: ${percent}%; height: 100%; background: ${color}; transition: width 0.3s ease;"></div>
                </div>
                <div style="margin-top: 5px; font-size: 11px; line-height: 1.3;">
                    <div style="font-weight: bold; color: #333;">${percent}%</div>
                    <div style="color: #666;">${closed}/${total}</div>
                </div>
            </div>
        `;
    }
}

// Обновление отображения только цифрами для списка проектов
function updateProjectListNumbers(container, percent, closed, total, color) {
    container.innerHTML = `
        <div title="${percent}% завершено (${closed}/${total} задач)" style="text-align: center; padding: 5px;">
            <div style="font-size: 14px; font-weight: bold; color: ${color};">
                ${percent}%
            </div>
        </div>
    `;
}

function updatePanelView(container, percent, closed, total, color) {
    container.innerHTML = `
        <div class="project-progress-panel-content" style="display: flex; align-items: center; gap: 12px;">
            <div style="flex: 1;">
                <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 5px;">
                    <div style="width: 100px; height: 12px; background: #f0f0f0; border-radius: 6px; overflow: hidden;">
                        <div style="width: ${percent}%; height: 100%; background: ${color};"></div>
                    </div>
                    <span style="font-weight: bold; color: #333; font-size: 13px;">${percent}%</span>
                </div>
                <div style="color: #666; font-size: 12px;">
                    ${closed} из ${total} задач завершено
                </div>
            </div>
        </div>
    `;
}

function updateCardView(container, percent, closed, total, color) {
    container.innerHTML = `
        <div class="project-progress-card-content" style="text-align: center;">
            <div style="font-size: 11px; color: #666; margin-bottom: 4px;">Прогресс</div>
            <div style="width: 80px; height: 10px; background: #f0f0f0; border-radius: 5px; margin: 0 auto; overflow: hidden;">
                <div style="width: ${percent}%; height: 100%; background: ${color};"></div>
            </div>
            <div style="margin-top: 4px; font-size: 11px;">
                <span style="font-weight: bold; color: #333;">${percent}%</span>
                <span style="color: #666;"> (${closed}/${total})</span>
            </div>
        </div>
    `;
}

function updateAutoView(container, percent, closed, total, color) {
    container.innerHTML = `
        <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
            <div style="flex: 1;">
                <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
                    <div style="width: 80px; height: 10px; background: #f0f0f0; border-radius: 5px; overflow: hidden;">
                        <div style="width: ${percent}%; height: 100%; background: ${color};"></div>
                    </div>
                    <span style="font-weight: bold; color: #333; font-size: 12px;">${percent}%</span>
                </div>
                <div style="color: #666; font-size: 11px;">
                    ${closed}/${total} задач
                </div>
            </div>
        </div>
    `;
}

function showProgressError(container, viewType) {
    const message = viewType === 'table' ? 
        '<div style="color: #999; font-style: italic; font-size: 12px;">ошибка</div>' :
        '<div style="color: #999; font-style: italic; font-size: 12px; text-align: center;">Ошибка загрузки</div>';
    
    container.innerHTML = message;
}

// Вспомогательные функции
function extractProjectId(url) {
    try {
        const match = url.match(/projects\/([^\/\?]+)/);
        return match ? match[1] : null;
    } catch (error) {
        return null;
    }
}

// Извлечение projectId из элемента прогресса
function extractProjectIdFromElement(element) {
    // Ищем ссылку на проект в родительских элементах
    const projectLink = element.closest('tr, li, div.project, article, .entity, .item')?.querySelector('a[href*="/projects/"]');
    if (projectLink) {
        return extractProjectId(projectLink.href);
    }
    
    // Ищем в самом элементе
    const linkInElement = element.querySelector('a[href*="/projects/"]');
    if (linkInElement) {
        return extractProjectId(linkInElement.href);
    }
    
    return null;
}

// Определение типа представления по элементу
function getViewTypeFromElement(element) {
    if (element.classList.contains('progress-cell')) {
        return 'table';
    } else if (element.classList.contains('project-progress-panel')) {
        return 'panel';
    } else if (element.classList.contains('project-progress-card')) {
        return 'card';
    } else if (element.classList.contains('project-progress-container')) {
        return 'auto';
    }
    
    // Определяем по контексту
    if (element.closest('table.list.projects')) {
        return 'table';
    } else if (element.closest('ul.projects')) {
        return 'panel';
    } else if (element.closest('.grid, .project-cards')) {
        return 'card';
    }
    
    return 'auto';
}

function getProgressColor(percent) {
    if (percent === 0) return '#f0f0f0';
    if (percent <= 20) return '#ff6b6b';
    if (percent <= 40) return '#ff9b6b';
    if (percent <= 60) return '#ffd46b';
    if (percent <= 80) return '#b8e05e';
    return '#8ec165';
}

// Инициализация при загрузке документа
document.addEventListener('DOMContentLoaded', function() {
    // Пытаемся инициализировать с настройками
    setTimeout(function() {
        const success = initializeProjectProgress();
        if (!success) {
            // Периодическая проверка с настройками
            const retryInterval = setInterval(function() {
                if (initializeProjectProgress()) {
                    clearInterval(retryInterval);
                }
            }, window.projectProgressSettings.js_retry_interval || 500);
            
            setTimeout(() => clearInterval(retryInterval), window.projectProgressSettings.js_max_retry_time || 10000);
        }
    }, window.projectProgressSettings.js_init_delay || 1000);
});

// Глобальные функции для отладки
window.initializeProjectProgress = initializeProjectProgress;
window.projectProgress = {
    init: initializeProjectProgress,
    reload: function() {
        initializeProjectProgress();
    },
    debug: function() {
    }
};
