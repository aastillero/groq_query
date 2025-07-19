# AI Task Creation Process

**Instructions:** To document a new task, follow this process. This ensures that all work is tracked in a consistent and organized manner.

1.  **Create the `ai_docs` Directory:** If it doesn't already exist, create a directory named `ai_docs` in the project root. This folder will store all task-related markdown files.
    ```bash
    mkdir -p ai_docs
    ```

2.  **Determine the Next Task Number:** Check the existing files in the `ai_docs` directory to find the highest current number (e.g., if `003-some-feature.md` is the last one, the next number is `004`).

3.  **Create the New Task File:**
    *   Copy the entire content of this template (`task_template.md`).
    *   Create a new file in the `ai_docs` directory with the name `NNN-brief-task-name.md`, where `NNN` is the next number (e.g., `004`) and `brief-task-name` is a short, descriptive name for the task (e.g., `add-user-profile-page`).
    *   Paste the copied template content into the new file.

4.  **Fill Out the Template:** Complete all the sections in the new task file to provide a comprehensive overview of the task for the AI agent.

5.  **Confirm with the User:** Present the completed task document to the user and ask for explicit approval before beginning the implementation.

---

# AI Task Template

**Instructions:** This template helps you create comprehensive task documents for AI-driven development. Fill out each section thoroughly to ensure the AI agent has all necessary context and can execute the task systematically.

---

## 1. Task Overview

### Task Title
<!-- Provide a clear, specific title for this task -->
**Title:** [Brief, descriptive title of what you are building/fixing]

### Goal Statement
<!-- One paragraph describing the high-level objective  -->
**Goal:** [Clear statement of what you want to achieve and why it matters]

---

## 2. Project analysis and Current State

### Technology and Architecture
<!-- 
AI Agent: Analyze the project to fill this out.
- Check `pubspec.yaml` for Flutter/Dart dependencies and versions.
- Check `/lib/main.dart` for app structure and routing.
- Check `/lib/services/` for service layer pattern implementation.
- Check `/lib/widgets/` and `/lib/screens/` for UI patterns.
- Check platform-specific directories: `ios/`, `android/`, `macos/`, `web/` for native configurations.
-->
- **Framework & Versions:** [Flutter 3.16.0, Dart 3.2.0]
- **Language:** [Dart 3.2.0 with null safety]
- **State Management:** [Provider pattern]
- **UI Framework:** [Material Design 3]
- **API Communication:** [HTTP package]
- **Native Integrations:** [SharedPreferences, Path Provider, Provider]
- **Key Architectural Patterns:** [Provider state management, Repository pattern]
- **Relevant Existing Components:** [Check `lib/main.dart:35`, `lib/services/chat_service.dart`, `lib/widget/home_page.dart`]

### Current State
<!-- Describe what exists today based on acutual analysis -->
[Describe the current situation, existing code, and what's working/not working based on actual analysis, not assumptions]

---

## 3. Context and Problem Definition

### Problem Statement
<!-- A detailed description of the problem. What is the user/business need? What is the pain point being solved? -->
**Problem:** [Describe the issue in detail]

### Success Criteria
<!-- What are the specific, measurable outcomes that will indicate the task is complete and successful? -->
**Success looks like:** 
- [Criterion 1]
- [Criterion 2]

---

## 4. Technical Requirements

### Functional Requirements
<!-- List the specific user-facing features or capabilities that must be implemented. -->
**Must-haves:**
- [Requirement 1]
- [Requirement 2]

### Non-Functional Requirements
<!-- List technical constraints or quality attributes (e.g., performance, security, accessibility, logging). -->
**Quality attributes:**
- [Requirement 1]
- [Requirement 2]

---

## 5. State Management and Data Handling

### Local Storage
<!-- Describe any SharedPreferences or local data storage needs. -->
**Data storage:** [Describe local data requirements, or "None" if not applicable]

### API Integration
<!-- Detail any new API endpoints or service methods in service classes. -->
**Service endpoints:**
- `[Method] API endpoint`: [Description]

---

## 6. Flutter UI Implementation

### New Widgets
<!-- List any new Flutter widgets to be created. Describe their properties and state. -->
**New UI components:**
- `[Widget Name]`: [Description - e.g. Stateful widget for conversation list]

### Screen Updates
<!-- Describe changes to existing screens or navigation. -->
**Screen modifications:**
- `[Screen Name]`: [Description of changes to layout, animations, or navigation]

## 7. Implementation Plan

### Phase 1: Core Setup
**Steps:**
1. Update pubspec.yaml with new dependencies
2. Create service classes in lib/services/
3. Define data models in lib/models/

### Phase 2: UI Widgets
**Steps:**
1. Create new stateless/stateful widgets
2. Implement responsive layouts
3. Add Material Design styling

### Phase 3: Testing
**Steps:**
1. Write widget tests using flutter_test
2. Write unit tests for service classes
3. Run integration tests