# Отладка кнопки экспорта проектов с прогрессом

## 🔧 **Что сделано:**

### **1. Исправлен хук `view_projects_index_bottom`:**
- ✅ **Убран ERB код** - заменен на обычный HTML
- ✅ **Добавлена отладка** - логирование работы хука
- ✅ **Обработка ошибок** - fallback URL при ошибке генерации маршрута

### **2. Добавлена JavaScript кнопка:**
- ✅ **Функция `addExportButton()`** - создает кнопку через JavaScript
- ✅ **Проверка дублирования** - не добавляет кнопку дважды
- ✅ **Поиск контейнера** - ищет подходящее место для вставки
- ✅ **Стилизация** - красивая кнопка с описанием

### **3. Двойная защита:**
- ✅ **Хук** - работает на серверной стороне
- ✅ **JavaScript** - работает на клиентской стороне
- ✅ **Отладка** - логирование в консоль и Rails лог

## 🚀 **Как проверить:**

### **1. Проверьте логи:**
```bash
docker-compose logs -f redmine
```
Ищите сообщения:
- `Project Progress: Hooks loaded successfully`
- `Project Progress: view_projects_index_bottom hook called`
- `Project Progress: Export URL generated: ...`

### **2. Проверьте консоль браузера:**
Откройте Developer Tools (F12) и ищите:
- `Project Progress: Export button added`
- `Project Progress: No suitable container found for export button`

### **3. Проверьте страницу проектов:**
- Перейдите на `/projects`
- Ищите блок "Экспорт проектов с прогрессом"
- Должна быть зеленая кнопка "Скачать CSV с прогрессом"

## 🔍 **Возможные проблемы:**

### **1. Хук не срабатывает:**
- Проверьте, что плагин загружен
- Проверьте логи на ошибки
- Убедитесь, что вы на странице проектов

### **2. JavaScript не работает:**
- Проверьте консоль браузера на ошибки
- Убедитесь, что JavaScript файл загружается
- Проверьте, что есть элемент `#content`

### **3. Кнопка не видна:**
- Проверьте CSS стили
- Убедитесь, что кнопка не скрыта
- Проверьте, что контейнер найден

## 📝 **Технические детали:**

### **Хук:**
```ruby
def view_projects_index_bottom(context = {})
  # Отладочная информация
  Rails.logger.info "Project Progress: view_projects_index_bottom hook called"
  
  # Генерация URL
  export_url = Rails.application.routes.url_helpers.project_progress_export_path(format: 'csv')
  
  # Возврат HTML
  <<~HTML
    <div>...</div>
  HTML
end
```

### **JavaScript:**
```javascript
function addExportButton() {
  // Проверка дублирования
  if (document.querySelector('.project-progress-export-button')) {
    return;
  }
  
  // Создание кнопки
  const exportButton = document.createElement('div');
  // ... стилизация и содержимое
  
  // Вставка в DOM
  const content = document.querySelector('#content, .main, .content, main');
  if (content) {
    content.insertBefore(exportButton, content.firstChild);
  }
}
```

## ✅ **Ожидаемый результат:**

После перезагрузки страницы проектов вы должны увидеть:

1. **Блок с заголовком** "Экспорт проектов с прогрессом"
2. **Описание** функциональности
3. **Зеленую кнопку** "Скачать CSV с прогрессом"
4. **В логах** сообщения об успешной инициализации

Если что-то не работает, проверьте логи и консоль браузера для диагностики!
