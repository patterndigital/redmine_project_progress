# Project Progress Plugin for Redmine

## Description
The Project Progress Plugin provides the ability to display overall project completion progress in Redmine. The plugin supports various progress calculation methods, flexible task filtering settings, and Redmine interface integration.

## Installation
1. Copy the plugin folder to your Redmine `plugins/` directory
2. Restart Redmine
3. Go to "Administration" → "Plugins" → "Project Progress Plugin" → "Settings"

## Plugin Settings

### 1. Progress Calculation Methods

#### **Default Calculation Method** (`default_calculation_method`)
Choose the main method for calculating project progress:

- **`progress_by_status`** - Calculation by task statuses (default)
- **`weighted_progress`** - Weighted calculation by priorities
- **`average_progress`** - Average progress by completion
- **`parent_project_aggregation`** - Child projects aggregation

#### **Weighted Calculation by Priorities** (`weighted_progress`)
Weight settings for different priorities:
- **High Priority** (`priority_weights_high`) - default 3.0
- **Normal Priority** (`priority_weights_normal`) - default 2.0
- **Low Priority** (`priority_weights_low`) - default 1.0

#### **Story Points Patterns** (`story_points_patterns`)
List of field names for Story Points search (comma-separated):
- Default: `story point,complexity,size,estimate`

### 2. Task Filtering Settings

#### **Include Subtasks** (`include_subtasks`)
- **Enabled** - include subtasks in progress calculation
- **Disabled** - include only main tasks (default)

#### **Include Closed Issues** (`include_closed_issues`)
- **Enabled** - include closed issues in total count (default)
- **Disabled** - exclude closed issues

#### **Count 100% as Closed** (`count_100_percent_as_closed`)
- **Enabled** - tasks with 100% completion are considered closed (default)
- **Disabled** - only tasks with "Closed" status are considered closed

#### **Minimum Issues Count** (`minimum_issues_count`)
Minimum number of issues to display progress:
- Default: 1
- If fewer issues than specified, progress is not displayed

#### **Exclude Trackers** (`exclude_trackers`)
List of trackers to exclude from calculation (comma-separated):
- Example: `Bug,Support`
- Empty field - include all trackers

#### **Exclude Priorities** (`exclude_priorities`)
List of priorities to exclude from calculation (comma-separated):
- Example: `Low,Trivial`
- Empty field - include all priorities

### 3. Parent Project Settings

#### **Include Own Issues** (`parent_project_include_own_issues`)
- **Enabled** - include parent project's own issues (default)
- **Disabled** - include only child project issues

#### **Weight Child Projects** (`parent_project_weight_children`)
- **Enabled** - apply weights to child projects (default)
- **Disabled** - equal weight distribution

#### **Progress Calculation Method** (`parent_project_calculation_method`)
Choose the progress calculation method for parent projects:

- **`weighted_average`** - By task count (weighted average) (default)
  - Projects with more tasks have greater weight
  - Example: if project A has 10 tasks (50% progress) and project B has 2 tasks (100% progress), then total progress = (50×10 + 100×2) / 12 = 58.3%

- **`simple_average`** - Simple average
  - All projects have equal weight regardless of task count
  - Example: if project A has 10 tasks (50% progress) and project B has 2 tasks (100% progress), then total progress = (50 + 100) / 2 = 75%

### 4. Display Settings

#### **Show in Project Sidebar** (`show_in_sidebar`)
- **Enabled** - display progress in project sidebar
- **Disabled** - don't display in sidebar (default)

#### **Progress Toggle on Projects Page**
A toggle for showing/hiding progress is automatically added to the projects page:
- **Enabled by default** - progress is shown for all projects
- **State is saved** in user's browser
- **Works for all views** - table, panel, cards

#### **Export Projects with Progress**
Added ability to export all projects to CSV file with progress information:
- **Export button** - at the end of projects page
- **Additional columns** - Progress (%), Closed Issues, Total Issues
- **Automatic file naming** with date
- **Access rights** - authenticated users only

### 5. Performance Settings

#### **Cache Calculations** (`cache_calculation`)
- **Enabled** - cache calculation results for better performance
- **Disabled** - always calculate fresh (default)

#### **Cache Duration** (`cache_duration`)
Cache storage time in seconds:
- Default: 600 seconds (10 minutes)
- Minimum: 60 seconds
- Maximum: 3600 seconds (1 hour)

### 6. Debug Settings

#### **Enable Debug Logging** (`enable_debug_logging`)
- **Enabled** - write detailed information to log
- **Disabled** - minimal logging (default)

#### **Log Calculation Details** (`log_calculation_details`)
- **Enabled** - log details of each calculation step
- **Disabled** - only basic information (default)

## Usage

### Sidebar Display
If "Show in Project Sidebar" is enabled, progress will be automatically displayed in each project's sidebar.

### Progress Page
Go to Project Menu → "Project Progress" to view detailed progress information.

### Progress Toggle on Projects Page
On the projects page (`/projects`) automatically added:
- **Toggle** at the top of the page for showing/hiding progress
- **Export button** at the end of the page for downloading CSV file with progress
- **Support for all views** - table, panel, cards

### Export Projects with Progress
1. Go to the projects page (`/projects`)
2. Find the "Export Projects with Progress" block at the end of the page
3. Click the "Download CSV with Progress" button
4. Get the `projects_with_progress_YYYYMMDD.csv` file with additional columns:
   - **Progress (%)** - completion percentage
   - **Closed Issues** - number of closed issues
   - **Total Issues** - total number of issues

### API Access
The plugin provides API for getting progress data:
```
GET /projects/:project_id/project_progress.json
```

## Permissions
- **View Progress** - available to all authenticated users
- **Plugin Settings** - administrators only

## Support
If you encounter issues, check:
1. Plugin settings in "Administration" section
2. Redmine logs for debug information
3. User permissions to projects

## Version
Current version: 1.0.0
