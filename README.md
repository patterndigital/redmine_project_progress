# Redmine Project Progress Plugin

This plugin adds project progress tracking functionality to Redmine, allowing users to view progress information for projects in various formats.

## Features

- **Project Progress Calculation**: Multiple calculation methods including status-based, weighted by story points, and arithmetic average
- **Sidebar Integration**: Shows progress in project sidebar
- **List View Enhancement**: Adds progress column to project lists
- **API Support**: RESTful API for programmatic access to progress data
- **Configurable Settings**: Extensive configuration options for calculation methods and display preferences
- **Multi-language Support**: English and Russian translations included

## Installation

1. Copy the plugin files to your Redmine plugins directory:
   ```
   cp -r redmine_project_progress /path/to/redmine/plugins/
   ```

2. Restart your Redmine server

3. Go to Administration > Plugins and configure the plugin settings

## Configuration

The plugin provides several configuration options:

### Calculation Settings
- **Default Calculation Method**: Choose between status-based, weighted, or average progress calculation
- **Priority Weights**: Configure weights for different issue priorities
- **Story Points Patterns**: Define patterns to identify story points in custom fields

### Basic Settings
- **Include Subtasks**: Whether to include subtasks in progress calculation
- **Include Closed Issues**: Whether to include closed issues in progress calculation
- **Minimum Issues Count**: Minimum number of issues required to show progress
- **Exclude Trackers/Priorities**: Filter out specific trackers or priorities

### Performance Settings
- **JavaScript Settings**: Configure initialization delays and retry intervals
- **Animation Duration**: Control progress bar animation speed

### Debug Settings
- **Debug Logging**: Enable detailed logging for troubleshooting
- **Calculation Details**: Log detailed calculation information

## Usage

### Viewing Progress

1. **Project Sidebar**: Progress is automatically displayed in the project sidebar (if enabled)
2. **Project Menu**: Click "Project Progress" in the project menu for detailed view
3. **Project Lists**: Progress bars are automatically added to project list views

### API Access

The plugin provides a RESTful API endpoint for accessing progress data:

```
GET /projects/{project_id}/project_progress
```

Returns JSON data with progress information:
```json
{
  "total_issues": 10,
  "closed_issues": 7,
  "progress_percentage": 70.0,
  "by_tracker": {...},
  "by_version": {...},
  "by_status": {...}
}
```

## File Structure

```
redmine_project_progress/
├── app/
│   ├── controllers/
│   │   └── project_progress_controller.rb
│   ├── models/
│   │   └── project_progress_calculator.rb
│   └── views/
│       ├── project_progress/
│       │   ├── index.html.erb
│       │   └── _sidebar.html.erb
│       ├── projects/
│       │   └── _project_progress_extras.html.erb
│       └── settings/
│           └── redmine_project_progress_settings.html.erb
├── assets/
│   ├── javascripts/
│   │   └── project_progress.js
│   └── stylesheets/
│       └── project_progress.css
├── config/
│   ├── locales/
│   │   ├── en.yml
│   │   └── ru.yml
│   └── routes.rb
├── lib/
│   └── redmine_project_progress_hooks.rb
├── init.rb
└── README.md
```

## Requirements

- Redmine 4.0+
- Ruby 2.5+
- Rails 5.2+

## License

This plugin is released under the MIT License.

## Support

For issues and feature requests, please create an issue in the project repository.
