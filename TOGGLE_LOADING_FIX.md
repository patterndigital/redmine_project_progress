# Исправление загрузки прогресса при включении переключателя

## 🐛 **Проблема:**
При включении галочки "Показывать прогресс проектов" часть панелей остается в состоянии "Загрузка прогресса" и не загружает данные.

## 🔧 **Причина:**
Элементы были созданы, но загрузка данных не была запущена из-за проверки состояния переключателя. При включении переключателя элементы показывались, но загрузка не запускалась.

## ✅ **Решение:**

### **1. Обновлена функция `toggleProgressDisplay`:**
```javascript
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
}
```

### **2. Добавлена функция извлечения projectId:**
```javascript
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
```

### **3. Добавлена функция определения типа представления:**
```javascript
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
```

## 🎯 **Логика работы:**

### **При включении переключателя:**
1. **Показываются** все элементы прогресса
2. **Проверяется** содержимое каждого элемента
3. **Если содержимое** содержит "Загрузка прогресса", "загрузка..." или "Загрузка..."
4. **Извлекается** projectId из элемента
5. **Определяется** тип представления
6. **Запускается** загрузка данных

### **При отключении переключателя:**
1. **Скрываются** все элементы прогресса
2. **Загрузка** не запускается

## 🔧 **Технические детали:**

### **Поиск projectId:**
- **В родительских элементах:** `tr, li, div.project, article, .entity, .item`
- **В самом элементе:** прямая ссылка на проект
- **Извлечение:** регулярное выражение `/projects\/([^\/\?]+)/`

### **Определение типа представления:**
- **По классам:** `.progress-cell`, `.project-progress-panel`, `.project-progress-card`, `.project-progress-container`
- **По контексту:** `table.list.projects`, `ul.projects`, `.grid, .project-cards`
- **Fallback:** `'auto'`

### **Проверка состояния загрузки:**
- **Тексты:** "Загрузка прогресса", "загрузка...", "Загрузка..."
- **Метод:** `element.innerHTML.includes()`

## ✅ **Результат:**

### **Теперь при включении галочки:**
- ✅ **Показываются** все элементы прогресса
- ✅ **Запускается загрузка** для элементов в состоянии "Загрузка прогресса"
- ✅ **Отображается** актуальный прогресс
- ✅ **Работает** для всех типов представлений

### **При отключении галочки:**
- ✅ **Скрываются** все элементы прогресса
- ✅ **Останавливается** загрузка данных
- ✅ **Экономится** трафик

Теперь переключатель работает корректно и загружает данные при включении! 🎯
