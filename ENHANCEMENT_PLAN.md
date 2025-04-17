# Global Enhancement Plan for SnapGrid

## 1. Project Structure Improvements

### 1.1 Reorganize Code Structure
- Create a more modular folder structure
- Separate UI widgets from business logic
- Implement feature-based organization

### 1.2 Implement Clean Architecture
- Add domain layer for business logic
- Create repository pattern for data access
- Separate UI, business logic, and data layers

## 2. Feature Enhancements

### 2.1 Improved Screenshot Management
- Add batch import functionality
- Implement screenshot categorization/tagging
- Add favorites system
- Implement sorting options (date, name, type)

### 2.2 Enhanced AI Analysis
- Add option for different AI models (OpenAI, DeepSeek, Gemini(choose models), Local providers like Ollama, or OpenAI compatible providers like OpenRouter via custom API URL)
- Implement batch analysis of multiple screenshots
- Add detailed component detection with bounding boxes
- Create comparison view for multiple screenshots

### 2.3 User Experience Improvements
- Enhance drag-and-drop functionality
- Add keyboard shortcuts
- Implement multi-selection for screenshots
- Add export functionality for analysis results

### 2.4 TODO: Direct Category Assignment on Import
- When importing screenshots (via menu, button, or drag-and-drop) while a category is selected, automatically assign the selected category to the new screenshots.
- Complete the AI suggestion assignment flow so that confirmed screenshots are assigned to the chosen category.

## 3. Technical Improvements

### 3.1 Testing
- Add comprehensive unit tests
- Implement widget tests for UI components
- Add integration tests for key workflows

### 3.2 Error Handling
- Implement global error handling
- Add better error reporting and recovery
- Create user-friendly error messages

### 3.3 Performance Optimization
- Implement image caching
- Optimize loading of large screenshot collections
- Add pagination for large datasets

### 3.4 Cross-Platform Support
- Enhance Windows/Linux support
- Ensure consistent UI across platforms
- Fix platform-specific issues
