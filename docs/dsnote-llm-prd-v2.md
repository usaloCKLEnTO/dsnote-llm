# dsnote-llm PRD v2 - Speech-to-Text Post-Processing Tool

## Overview

`dsnote-llm` is a fork of the dsnote application (https://github.com/mkiol/dsnote) that adds LLM-powered post-processing capabilities directly into the speech-to-text workflow. The tool addresses limitations in current speech-to-text solutions by cleaning up transcriptions, removing filler words, fixing duplications, and correcting common speech recognition errors.

## Background & Context

The user currently uses Aqua Voice on macOS, which provides excellent post-processing capabilities but lacks a Linux equivalent. On their immutable Fedora Silverblue-based system (Bluefin OS), they use:
- **Current setup**: dsnote (https://github.com/mkiol/dsnote) with WhisperCpp Distil Large-v3 /en model
- **Desktop environment**: Gnome on Wayland
- **System type**: Immutable Linux (Bluefin OS) requiring special build considerations
- **Current limitation**: 
  - No post-processing of transcribed text, resulting in filler words, duplications, and speech recognition errors
  - Clipboard functionality doesn't work reliably on Wayland with immutable Linux system
  - Need to integrate LLM processing directly into dsnote rather than as separate tool

## Technical Challenge

Initial plan was to create a separate tool, but clipboard functionality doesn't work reliably on Wayland with immutable Linux systems.

**Solution**: Fork dsnote locally and extend its existing functionality by:
1. Adding a new "Transformation" tab to the settings window
2. Integrating LLM post-processing after dsnote's existing dictionary processing
3. Leveraging dsnote's current text processing pipeline

## Goals

### Primary Goals
1. Fork dsnote locally and add LLM post-processing capability
2. Integrate seamlessly with dsnote's existing UI by adding a "Transformation" tab
3. Remove filler words, duplicate words, and fix grammar in transcribed text
4. Leverage dsnote's existing dictionary processing for word corrections
5. Maintain existing dsnote functionality while adding optional LLM enhancement
6. Use Simon Willison's LLM tool for flexible model support

### Future Goals
- Context-aware processing modes (formal writing, code comments, casual notes)
- Performance optimization based on usage metrics
- Upstream contribution to dsnote project
- Support for multiple LLM backends

## Technical Requirements

### System Environment
- **OS**: Immutable Fedora Silverblue-based (Bluefin OS)
- **Desktop**: Gnome on Wayland
- **Base application**: dsnote (https://github.com/mkiol/dsnote)
- **LLM tool**: Simon Willison's LLM (https://github.com/simonw/llm)
- **Dependencies**: 
  - `ydotool` daemon - for active window text insertion (already used by dsnote)
  - Simon's LLM tool - installed via `brew install llm` or `pipx install llm`
  - All existing dsnote dependencies

### Immutable Linux Build Requirements
```bash
# Required Homebrew installations for building C++/Qt applications
brew install gcc cmake qt@6 portaudio

# Environment variables needed for compilation
export CC=gcc-15
export CXX=g++-15
export LD_LIBRARY_PATH=/home/linuxbrew/.linuxbrew/lib:$LD_LIBRARY_PATH
```

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
3. **Dictionary Processing**: dsnote applies its existing dictionary corrections
4. **LLM Processing**: If enabled, send text to LLM tool for additional cleanup (~500ms)
5. **Output**: Insert processed text into active window using existing dsnote ydotool integration

### LLM Integration Requirements
- **Tool**: Simon Willison's LLM (`llm -m MODEL_NAME`)
- **Default Model**: `groq-llama3-70b` (fastest, ~489ms latency)
- **Process Integration**: Call LLM tool as subprocess after transcription completes
- **Error Handling**: Graceful fallback to dictionary-corrected transcription if LLM processing fails
- **Performance**: Target ~500ms processing time with recommended models
- **Configuration**: Optional feature that can be enabled/disabled in dsnote settings

### Model Selection (Based on Testing)
```yaml
# Recommended models based on extensive testing
models:
  fastest: "groq-llama3-70b"              # 489ms - Best overall choice
  fast_alternative: "groq-kimi-k2"        # 569ms - Excellent backup
  lightweight: "gemini-2.5-flash-lite-preview-06-17"  # Sub-second
  quality_focused: "gpt-4o"               # ~1s - When quality matters most
  
# Models to avoid for real-time use
avoid:
  - "gemini-2.5-pro"      # ~8.8s latency
  - "claude-3.5-haiku"    # Long latency, verbose
  - "gemini-2.5-flash"    # Inconsistent cleanup
```

### Processing Features
- **Filler word removal**: Remove "um", "uh", and similar speech artifacts
- **Deduplication**: Remove duplicate words and repeated phrases
- **Grammar correction**: Fix basic grammatical issues
- **Flexible model selection**: Easy switching between models via configuration
- **Leverages existing dictionary**: dsnote's built-in dictionary processing handles word replacements

### Configuration Integration
Extend dsnote's existing configuration system by adding a new "Transformation" tab to the settings window:

#### UI Integration - New Transformation Tab
The dsnote settings window should include a new "Transformation" tab with:
- **Enable LLM Processing** checkbox
- **Model Selection** dropdown with presets:
  - Fastest (groq-llama3-70b) - Default
  - Fast Alternative (groq-kimi-k2)
  - Lightweight (gemini-2.5-flash-lite-preview-06-17)
  - Quality Focus (gpt-4o)
  - Custom...
- **Custom Model** text field (enabled when "Custom..." selected)
- **LLM Tool Path** text field with browse button
- **Processing Timeout** slider (500ms - 3000ms, default 1500ms)
- **Test Processing** button to verify setup
- **Performance Logging** checkbox

#### Internal Configuration Structure
```cpp
// Extension to existing dsnote configuration
struct TransformationConfig {
    bool llmEnabled = false;
    QString llmTool = "llm";  // Command or full path
    QString llmModel = "groq-llama3-70b";
    QString llmPrompt = "Clean up this transcribed speech. Remove filler words like 'um', 'uh', fix grammar, remove duplicate words, and make it clear and concise. Only return the cleaned text, no explanations.";
    int timeoutMs = 1500;
    bool fallbackOnError = true;
    bool logPerformance = false;
};

// Add to existing dsnote settings class
class DsnoteSettings {
    // ... existing settings ...
    TransformationConfig transformation;
};

### Error Handling & Fallback Strategy
```cpp
QString processTranscription(const QString& rawTranscription) {
    // 1. dsnote's existing dictionary processing already applied
    // 2. If LLM enabled, attempt additional processing
    if (settings.transformation.llmEnabled) {
        QString llmProcessed = processWithLLM(rawTranscription);
        if (!llmProcessed.isEmpty() && llmProcessed != rawTranscription) {
            return llmProcessed;  // Success
        }
    }
    
    // 3. Fallback: return dsnote's already-processed text
    return rawTranscription;
}
```

### Performance Specifications
- **LLM processing target**: ~500ms with recommended models
- **Total additional latency**: <600ms typical, 1500ms maximum
- **Timeout behavior**: Fallback to dsnote's processed text
- **User experience**: Transparent operation, no error dialogs

## Integration Requirements

### dsnote Source Code Modification
- **Fork location**: https://github.com/usaloCKLEnTO/dsnote-llm
- **Integration point**: Add LLM processing step after transcription completion, before text output
- **UI integration**: Add LLM settings to existing dsnote preferences/settings dialog
- **Minimal disruption**: Maintain all existing dsnote functionality
- **Optional feature**: LLM processing should be completely optional and configurable

### Simon's LLM Tool Integration
- **Installation**: `brew install llm` or `pipx install llm`
- **API key setup**: `llm keys set anthropic` (for Claude models if needed)
- **Model verification**: `llm models list` to check available models
- **Command format**: `echo "text" | llm -m MODEL --no-stream "prompt"`
- **Path consideration**: May need full path `/home/linuxbrew/.linuxbrew/bin/llm`

### Build Instructions for Immutable Linux
```bash
# Clone YOUR fork
git clone https://github.com/usaloCKLEnTO/dsnote-llm.git
cd dsnote-llm
git checkout -b llm-integration

# Set up build environment
export CC=gcc-15
export CXX=g++-15
export CMAKE_PREFIX_PATH=/home/linuxbrew/.linuxbrew/opt/qt@6
export LD_LIBRARY_PATH=/home/linuxbrew/.linuxbrew/lib:$LD_LIBRARY_PATH

# Build (will need to modify source for different app name)
mkdir build && cd build
cmake ..
make -j$(nproc)

# Install to local directory (not system)
make DESTDIR=$HOME/.local/dsnote-llm install
```

### Parallel Development Strategy

Since you're actively using the existing dsnote installation, the development approach must support running both versions simultaneously:

1. **Different Binary Name**: Modify CMakeLists.txt to output `dsnote-llm` binary
2. **Different Config Directory**: Modify source to use `~/.config/dsnote-llm/`
3. **Different Desktop Entry**: Create distinct launcher for testing version
4. **Import Existing Config**: Provide option to copy settings from production dsnote

#### Required Source Modifications
```cpp
// In main.cpp or equivalent, change application identity
app.setApplicationName("dsnote-llm");
app.setOrganizationName("usaloCKLEnTO");

// Change config directory
QString getConfigDir() {
    return QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) 
           + "/dsnote-llm/";
}
```

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
3. **Phase 3**: Implement subprocess execution for LLM processing
4. **Phase 4**: Add dictionary-based word replacement
5. **Phase 5**: Integrate with existing text output mechanisms
6. **Phase 6**: Testing and performance optimization

### Key Source Files to Examine
- Settings/preferences dialog implementation (for adding Transformation tab)
- Text processing pipeline (post-dictionary processing hook)
- Configuration storage and retrieval
- UI/preferences dialogs structure
- Build configuration files (CMakeLists.txt, etc.)
- Action handling for different dsnote modes

## Success Criteria
1. **Functionality**: Successfully processes transcribed text with LLM before output
2. **Speed**: LLM processing completes within ~500ms typical, 1500ms maximum
3. **Accuracy**: Significant improvement in text quality compared to raw transcription
4. **Reliability**: Handles LLM processing errors gracefully without breaking functionality
5. **Usability**: Existing dsnote workflow remains unchanged, LLM processing is transparent
6. **Configurability**: All LLM features can be easily enabled/disabled and customized
7. **Maintainability**: Changes are well-documented and minimal to ease future updates

## Implementation Phases

### Phase 1 (Code Analysis) - 1-2 days
- Fork dsnote repository to separate directory
- Set up parallel development environment
- Analyze source code structure and build system
- Identify how to change application ID and config paths
- Document text processing pipeline integration points
- Create build scripts for parallel installation

### Phase 2 (Basic Integration) - 2-3 days
- Add "Transformation" tab to dsnote settings window
- Implement LLM configuration options in new tab
- Create subprocess execution for `llm` command
- Hook into post-dictionary processing pipeline
- Add basic error handling and fallback mechanisms
- Test with simple transcription examples

### Phase 3 (Enhancement) - 2-3 days
- Add model preset management
- Implement performance monitoring and logging
- Integrate with existing dsnote logging system
- Add "Test Processing" functionality in settings
- Optimize processing pipeline for speed

### Phase 4 (Polish) - 1-2 days
- User interface improvements for LLM settings
- Comprehensive error handling and user feedback
- Documentation and configuration examples
- Performance testing with various models

## Technical Notes
- **Immutable OS consideration**: Build modified dsnote locally in user space
- **Wayland compatibility**: Leverage dsnote's existing Wayland/ydotool integration
- **Dependency management**: Use Homebrew for build dependencies on immutable system
- **Model flexibility**: Support for multiple LLM providers through Simon's tool
- **Performance priority**: Default to fastest models, allow quality/speed tradeoffs
- **Future extensibility**: Structure code to support additional LLM backends

## Testing Strategy
1. **Unit tests**: Dictionary replacement functionality
2. **Integration tests**: LLM subprocess communication
3. **Performance tests**: Measure latency with different models
4. **Fallback tests**: Verify graceful degradation
5. **User acceptance**: Real-world dictation scenarios

## Deployment Options
1. **Parallel Local Build**: Run as `dsnote-llm` alongside production `dsnote`
2. **Gradual Migration**: Test thoroughly before replacing production version
3. **AppImage**: Package both versions separately for easy switching
4. **Upstream PR**: Eventually contribute back to dsnote project

### Migration Path
1. **Development Phase**: Run `dsnote-llm` with different shortcuts
2. **Testing Phase**: Use both versions in parallel, compare results
3. **Transition Phase**: Gradually move workflows to LLM version
4. **Production Phase**: Replace original only after full validation
5. **Contribution Phase**: Submit improvements upstream

## Risk Mitigation
- **Production Disruption**: Parallel installation prevents any impact on current workflow
- **Configuration Conflicts**: Separate config directories ensure isolation
- **Keyboard Shortcut Conflicts**: Use different shortcuts during development
- **LLM API changes**: Abstract LLM interface for easy updates
- **Model availability**: Support multiple fallback models
- **Performance variability**: Configurable timeouts and fallbacks
- **Build complexity**: Document all steps thoroughly

This PRD represents a practical approach to enhancing dsnote with LLM capabilities while respecting the constraints of an immutable Linux system and prioritizing user experience through fast, reliable text processing.