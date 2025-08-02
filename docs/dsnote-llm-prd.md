# rk-voice PRD - Speech-to-Text Post-Processing Tool

## Overview

`rk-voice` is a modification to the dsnote application (https://github.com/mkiol/dsnote) that adds LLM-powered post-processing capabilities directly into the speech-to-text workflow. The tool addresses limitations in current speech-to-text solutions by cleaning up transcriptions, removing filler words, fixing duplications, and correcting common speech recognition errors.

## Background & Context

The user currently uses Aqua Voice on macOS, which provides excellent post-processing capabilities but lacks a Linux equivalent. On their immutable Fedora Silverblue-based system (Bluffin OS), they use:
- **Current setup**: dsnote (https://github.com/mkiol/dsnote) with WhisperCpp Distil Large-v3 /en model
- **Desktop environment**: Gnome on Wayland
- **Current limitation**: 
  - No post-processing of transcribed text, resulting in filler words, duplications, and speech recognition errors
  - Clipboard functionality doesn't work reliably on Wayland with immutable Linux system
  - Need to integrate LLM processing directly into dsnote rather than as separate tool

## Technical Challenge

Initial plan was to create a separate `rk-voice` script that would:
1. Trigger dsnote with `--action start-listening-clipboard`
2. Process clipboard content with LLM after transcription
3. Output processed text to active window

**Problem discovered**: Clipboard functionality (`--action start-listening-clipboard`) does not work reliably on Wayland with immutable Linux systems.

**New approach**: Fork dsnote locally and modify source code to add optional LLM post-processing capability directly within the application.

## Goals

### Primary Goals
1. Fork dsnote locally and add LLM post-processing capability
2. Remove filler words, duplicate words, and fix grammar in transcribed text
3. Correct common speech recognition errors via custom dictionary
4. Integrate processing seamlessly into existing dsnote workflow
5. Maintain existing dsnote functionality while adding optional LLM enhancement
6. Use existing command-line LLM tools (Claude Code CLI) to avoid API configuration

### Future Goals
- Context-aware processing modes (formal writing, code comments, casual notes)
- Direct API integration instead of CLI tools
- Performance optimization
- Upstream contribution to dsnote project

## Technical Requirements

### System Environment
- **OS**: Immutable Fedora Silverblue-based (Bluffin OS)
- **Desktop**: Gnome on Wayland
- **Base application**: dsnote (https://github.com/mkiol/dsnote)
- **Dependencies**: 
  - `ydotool` daemon - for active window text insertion (already used by dsnote)
  - Claude Code CLI tool - for LLM processing (installed via brew)
  - All existing dsnote dependencies

### Architecture
- **Approach**: Fork and modify dsnote source code
- **Language**: C++/Qt (dsnote's existing codebase)
- **Integration point**: Add LLM processing step after transcription, before output
- **Configuration**: Extend dsnote's existing configuration system
- **Trigger**: Existing Gnome global keyboard shortcut (F12/Ctrl-F12 via analog keyboard)

## Functional Specifications

### Modified dsnote Workflow
1. **Input**: User triggers existing dsnote recording (F12 key down → start listening)
2. **Transcription**: dsnote performs speech-to-text using existing WhisperCpp integration
3. **Dictionary Processing**: Apply word replacements from custom dictionary file
4. **LLM Processing**: Optionally send transcribed text to Claude Code CLI for cleanup
5. **Output**: Insert processed text into active window using existing dsnote ydotool integration

### LLM Integration Requirements
- **CLI Tool**: Use `claude -p "prompt_text"` command
- **Process Integration**: Call CLI tool as subprocess after transcription completes
- **Error Handling**: Graceful fallback to raw transcription if LLM processing fails
- **Performance**: LLM processing must complete within 500-600ms
- **Configuration**: Optional feature that can be enabled/disabled in dsnote settings

### Processing Features
- **Filler word removal**: Remove "um", "uh", and similar speech artifacts
- **Deduplication**: Remove duplicate words and repeated phrases
- **Grammar correction**: Fix basic grammatical issues
- **Custom dictionary**: User-defined word replacements (e.g., "nd" → "command")

### Configuration Integration
Extend dsnote's existing configuration system to include:

#### New Configuration Options
- **Enable LLM processing**: Boolean toggle
- **LLM command**: Configurable CLI command (default: `claude -p`)
- **LLM prompt**: Configurable prompt text
- **Dictionary file path**: Path to word replacement dictionary
- **Processing timeout**: Maximum time to wait for LLM processing
- **Fallback behavior**: What to do if LLM processing fails

#### Dictionary File Format
- **Format**: Simple text file with one mapping per line
- **Syntax**: `wrong_word -> correct_word`
- **Example**:
  ```
  nd -> command
  gooble -> Google
  ```
- **Location**: User-configurable path in dsnote settings

### Error Handling & Logging
- **Integration with dsnote logging**: Use existing dsnote logging system
- **LLM failure fallback**: Output raw transcription if LLM processing fails
- **Timeout handling**: Cancel LLM processing if it exceeds configured timeout
- **Dictionary errors**: Log but don't fail if dictionary file is missing/corrupted
- **Performance monitoring**: Log processing times for optimization

### Performance Considerations
- **Speed priority**: Maximum LLM processing latency of 500-600 milliseconds
- **Performance breakdown** (additional processing only):
  - Dictionary processing: ~50ms
  - Claude Code CLI execution: ~400-500ms (largest bottleneck)
  - Process communication overhead: ~50ms
- **Timeout protection**: Cancel LLM processing if it exceeds timeout
- **Async processing**: Don't block dsnote UI during LLM processing
- **Fallback speed**: Immediate fallback to raw transcription if LLM fails

## Integration Requirements

### dsnote Source Code Modification
- **Fork location**: Local fork of https://github.com/mkiol/dsnote
- **Integration point**: Add LLM processing step after transcription completion, before text output
- **UI integration**: Add LLM settings to existing dsnote preferences/settings dialog
- **Minimal disruption**: Maintain all existing dsnote functionality
- **Optional feature**: LLM processing should be completely optional and configurable

### Claude Code CLI Integration
- **Command**: `claude -p "prompt_text"` 
- **Input method**: Pass transcribed text via stdin or command argument
- **Output parsing**: Capture stdout from claude command
- **Error handling**: Detect command failures and timeouts
- **Path configuration**: Allow user to specify claude command path

### Existing dsnote Workflow Preservation
- **No breaking changes**: All existing actions and shortcuts continue working
- **Performance**: LLM processing should not significantly impact base transcription speed
- **User choice**: Users can disable LLM processing and use original dsnote behavior

## Development Approach

### Code Analysis Requirements
1. **Study dsnote architecture**: Understand how transcription results are processed and output
2. **Identify integration points**: Find where to insert LLM processing in the workflow
3. **Configuration system**: Understand dsnote's existing settings/preferences system
4. **Build system**: Learn dsnote's build process and dependencies
5. **Text processing pipeline**: Map the flow from speech recognition to text output

### Implementation Strategy
1. **Phase 1**: Analyze dsnote source code and identify modification points
2. **Phase 2**: Add configuration options for LLM integration
3. **Phase 3**: Implement CLI subprocess execution for LLM processing
4. **Phase 4**: Add dictionary-based word replacement
5. **Phase 5**: Integrate with existing text output mechanisms
6. **Phase 6**: Testing and performance optimization

### Key Source Files to Examine
- Text processing and output modules
- Configuration/settings management
- UI/preferences dialogs
- Build configuration files (CMakeLists.txt, etc.)
- Action handling for different dsnote modes

## Success Criteria
1. **Functionality**: Successfully processes transcribed text with LLM before output to active window
2. **Speed**: LLM processing completes within 500-600 milliseconds or falls back to raw transcription
3. **Accuracy**: Significant improvement in text quality compared to raw transcription
4. **Reliability**: Handles LLM processing errors gracefully without breaking dsnote functionality
5. **Usability**: Existing dsnote workflow remains unchanged, LLM processing is transparent
6. **Configurability**: All LLM features can be easily enabled/disabled and customized
7. **Maintainability**: Changes are well-documented and don't interfere with future dsnote updates

## Implementation Phases

### Phase 1 (Code Analysis)
- Fork dsnote repository locally
- Analyze source code structure and build system
- Identify text processing pipeline and output mechanisms
- Understand configuration system and UI integration points

### Phase 2 (Basic Integration)
- Add LLM configuration options to dsnote settings
- Implement CLI subprocess execution for `claude -p`
- Add basic error handling and fallback mechanisms
- Test with simple transcription examples

### Phase 3 (Enhancement)
- Implement dictionary-based word replacement
- Add performance monitoring and timeout handling
- Integrate with existing dsnote logging system
- Optimize processing pipeline for speed

### Phase 4 (Polish)
- User interface improvements for LLM settings
- Comprehensive error handling and user feedback
- Documentation and configuration examples
- Performance testing and optimization

## Technical Notes
- **Immutable OS consideration**: Build modified dsnote locally, don't require system-level changes
- **Wayland compatibility**: Leverage dsnote's existing Wayland/ydotool integration
- **Dependency management**: Use existing dsnote dependencies, add minimal external requirements
- **Upstream compatibility**: Structure changes to potentially contribute back to dsnote project
- **CLI tool integration**: Use subprocess execution to maintain separation between dsnote and LLM tools
- **Performance monitoring**: Add timing logs to identify bottlenecks in LLM processing pipeline

## Coding Engine Instructions

When analyzing the dsnote source code, focus on:

1. **Text output pipeline**: Find where transcribed text is formatted and sent to active window
2. **Configuration system**: Understand how user preferences are stored and accessed
3. **Action handling**: See how different `--action` commands are processed
4. **Error handling**: Learn existing patterns for handling failures and timeouts
5. **Build system**: Understand compilation and dependency requirements
6. **UI integration**: Find where settings dialogs are defined for adding LLM options

The goal is to add an optional LLM processing step that integrates seamlessly with dsnote's existing workflow while maintaining all current functionality.