module screens.popups.options;

import raylib; // Ensure this is at the top

import std.stdio;
import std.file;
import std.json;
import std.path;
import std.process;
import std.string;
import std.algorithm : min, max;
import std.typecons : Tuple, tuple;
import std.conv; // Added for to!string, to!int, to!float, to!bool

import world.screen_manager;
import world.audio_manager;
import world.audio_manager : AudioType; // Explicitly import AudioType enum
import world.audio_settings; // Added import for audio settings
import world.memory_manager;
import world.screen_states;
import app;
import app : GetMousePositionVirtual, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, fontFamily; // Ensure fontFamily is imported
import data;

struct GameOptions {
    // screen manager
    bool fullscreen;
    string resolution; // Example: "1920x1080"
    bool vsync;
    bool hasPendingResolutionChange; // Flag to track if resolution change is pending

    // display manager (Placeholder - not directly settable in Raylib easily post-init)
    float brightness; // Typically adjusted via shaders or monitor settings
    float contrast;   // Typically adjusted via shaders or monitor settings
    float gamma;      // Typically adjusted via shaders or monitor settings

    // audio manager
    int masterVolume; // Changed to int (0-100)
    int musicVolume;  // Changed to int (0-100)
    int sfxVolume;    // Changed to int (0-100)
    bool mute;        // Added mute

    // gameplay options
    bool autoSave;
    bool randomBackdrops;
    int gemStyle; // 1: Classic, 2: Modern, 3: Retro
    int systemMode; // 1: Original, 2: Arranged
    int musicStyle; // Added: e.g., 1: Original, 2: Remastered

    // player settings
    string playerName; // Added
}

class OptionsScreen { // Renamed from OptionsPopup to OptionsScreen to match usage in app.d
    private MemoryManager memoryManager;
    private AudioManager audioManager;
    private GameOptions currentOptions;
    private string optionsFilePath;

    private bool _isActive = false;

    private Rectangle backButtonRect;
    private string[] optionCategories = ["Video", "Audio", "Gameplay", "Controls"]; // Added Controls
    private int selectedCategoryIndex = 0;

    // UI element rectangles - defined here if they need to be accessed in update() for clicks
    private Rectangle fullscreenToggleRect;
    private Rectangle vsyncToggleRect;
    private Rectangle muteToggleRect;
    private Rectangle autoSaveToggleRect;
    private Rectangle randomBackdropsToggleRect;

    // Rectangles for selector arrows
    private Rectangle resolutionLeftArrowRect;
    private Rectangle resolutionRightArrowRect;
    private Rectangle gemStyleLeftArrowRect;
    private Rectangle gemStyleRightArrowRect;
    private Rectangle musicStyleLeftArrowRect;
    private Rectangle musicStyleRightArrowRect;
    private Rectangle systemModeLeftArrowRect;
    private Rectangle systemModeRightArrowRect;

    // Supported options lists and current indices
    // Filtered for 16:9 aspect ratios
    private string[] supportedResolutions = [
        "1280x720", 
        "1600x900", 
        "1920x1080",
        "2560x1440" // Added 2560x1440
        // Add other 16:9 resolutions if needed, e.g., "3840x2160"
    ];
    private int currentResolutionIndex = 0;
    
    // Slider-related variables
    private Rectangle masterVolumeSliderRect;
    private Rectangle musicVolumeSliderRect;
    private Rectangle sfxVolumeSliderRect;
    private bool isDraggingMasterSlider = false;
    private bool isDraggingMusicSlider = false;
    private bool isDraggingEffectsSlider = false;
    private float sliderWidth = 200.0f;
    private float sliderHeight = 20.0f;

    // Track music style changes
    private int originalMusicStyle = -1; // Store the music style when options menu is opened

    public this() {
        memoryManager = MemoryManager.instance(); // Corrected: use instance()
        audioManager = AudioManager.getInstance();  // Corrected: use getInstance()

        currentOptions = GameOptions.init; // Corrected: struct initialization
        // Explicitly initialize fields that aren't handled by .init
        currentOptions.hasPendingResolutionChange = false;
        // currentOptions.resolution is loaded from file, find its index
        // If not found, default to a common one like 1600x900 or the first in the list
        optionsFilePath = buildPath(getcwd(), "options.ini");

        loadOptionsFromFile(); // Load options first to get current resolution
        initializeResolutionIndex(); // Then initialize index based on loaded/default resolution
        initializeUI();
    }

    void initializeResolutionIndex() {
        currentResolutionIndex = 0; // Default to the first 16:9 resolution in the filtered list
        bool found = false;
        for (int i = 0; i < supportedResolutions.length; i++) {
            if (supportedResolutions[i] == currentOptions.resolution) {
                // Check if the loaded resolution is 16:9
                string[] parts = currentOptions.resolution.split('x');
                if (parts.length == 2) {
                    try {
                        int w = parts[0].to!int;
                        int h = parts[1].to!int;
                        if (w * 9 == h * 16) { // Check for 16:9 aspect ratio
                            currentResolutionIndex = i;
                            found = true;
                            break;
                        }
                    } catch (Exception e) {
                        writeln("Error parsing resolution for aspect ratio check: ", currentOptions.resolution);
                    }
                }
            }
        }

        // If the loaded resolution wasn't found in the 16:9 list or wasn't 16:9,
        // default to the first supported 16:9 resolution.
        if (!found) {
            if (supportedResolutions.length > 0) {
                currentOptions.resolution = supportedResolutions[0]; // Default to the first 16:9 option
                currentResolutionIndex = 0;
                currentOptions.hasPendingResolutionChange = true; // Mark for change if it wasn't 16:9
                writeln("Current resolution is not 16:9 or not supported. Defaulting to ", currentOptions.resolution);
            } else {
                // This case should ideally not happen if supportedResolutions is correctly populated.
                // Fallback to a common 16:9 resolution if the list is somehow empty.
                currentOptions.resolution = "1280x720"; 
                currentResolutionIndex = 0; // Assuming 1280x720 would be in a non-empty list
                currentOptions.hasPendingResolutionChange = true;
                writeln("Supported resolutions list is empty. Defaulting to 1280x720.");
            }
        }
        // Ensure currentOptions.resolution is valid if it wasn't found or was empty
        // This part might be redundant now due to the logic above but kept for safety.
        else if (currentOptions.resolution.empty || (currentResolutionIndex == 0 && supportedResolutions.length > 0 && supportedResolutions[0] != currentOptions.resolution)) {
             if (supportedResolutions.length > 0) {
                currentOptions.resolution = supportedResolutions[currentResolutionIndex]; // Ensure it's set from the list
             } else {
                currentOptions.resolution = "1280x720"; // Fallback if list is empty
             }
        }
    }

    void initializeUI() {
        float buttonWidth = 200;
        float buttonHeight = 50;
        float padding = 10;
        backButtonRect = Rectangle(VIRTUAL_SCREEN_WIDTH - buttonWidth - padding, VIRTUAL_SCREEN_HEIGHT - buttonHeight - padding, buttonWidth, buttonHeight);

        // Only apply audio and gameplay settings during initialization
        // Video settings are skipped to avoid screen flashes
        applyAudioSettings();
        // No video settings application here to prevent flashing
        applyGameplaySettings();

        // Apply texture filtering to fonts for better quality
        foreach (font; app.fontFamily) {
            if (font.texture.id > 0) {
                SetTextureFilter(font.texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
            }
        }

        writeln("Options Screen Initialized with " ~ optionsFilePath);
    }

    public bool isActive() {
        return _isActive;
    }

    public void show() {
        _isActive = true;
        // Store the original music style when opening options
        originalMusicStyle = currentOptions.musicStyle;
        // Don't reload and apply settings when showing to avoid screen flashes
        // loadOptionsFromFile(); // Commented out to prevent reload and potential screen flashing
        writeln("OptionsScreen shown, original music style: ", originalMusicStyle);
    }

    public void hide() {
        _isActive = false;
        saveOptionsToFile();
        // audioManager.playSound("options_close"); // Example sound
        
        // Apply settings when closing, but skip resolution/fullscreen changes
        // to prevent screen flashing
        applySettings(false); 
        
        // Check if music style changed and restart main menu music if it did
        if (originalMusicStyle != -1 && originalMusicStyle != currentOptions.musicStyle) {
            writeln("Music style changed from ", originalMusicStyle, " to ", currentOptions.musicStyle, " - restarting main menu music");
            if (audioManager !is null) {
                // Set the new music style in the audio manager
                audioManager.setMusicStyle(currentOptions.musicStyle);
                // Restart the main menu music with the new style
                audioManager.playMusicWithStyle("Main Theme - Bejeweled 2.ogg", -1.0f, true);
            }
        }
        
        writeln("OptionsScreen hidden");
    }

    // Public getter for current music style
    public int getCurrentMusicStyle() {
        return currentOptions.musicStyle;
    }
    
    // Public method to save options to file (for external calls like name entry confirmation)
    public void saveOptions() {
        saveOptionsToFile();
    }

    // Public method to check for and apply pending resolution changes at game startup
    public bool applyPendingResolutionChanges() {
        try {
            bool changesMade = false;
            
            // Always check and apply fullscreen setting on startup (regardless of pending changes)
            if (currentOptions.fullscreen && !IsWindowState(ConfigFlags.FLAG_WINDOW_UNDECORATED)) {
                writeln("Applying fullscreen setting from options.ini...");
                ToggleBorderlessWindowed();
                changesMade = true;
            } else if (!currentOptions.fullscreen && IsWindowState(ConfigFlags.FLAG_WINDOW_UNDECORATED)) {
                writeln("Applying windowed setting from options.ini...");
                ToggleBorderlessWindowed(); // Call again to toggle off if it was on
                changesMade = true;
            }
            
            // Apply pending resolution changes if any
            if (currentOptions.hasPendingResolutionChange) {
                writeln("Applying pending resolution changes...");
                
                // Apply resolution changes if needed
                string[] resParts = currentOptions.resolution.split('x');
                if (resParts.length == 2) {
                    int width = resParts[0].to!int;
                    int height = resParts[1].to!int;
                    
                    // Only change if different from current
                    if (width != GetScreenWidth() || height != GetScreenHeight()) {
                        writeln("Setting resolution to ", width, "x", height);
                        SetWindowSize(width, height);
                        changesMade = true;
                    }
                }
                
                // Reset the flag
                currentOptions.hasPendingResolutionChange = false;
                saveOptionsToFile();
            }
            
            return changesMade; // Changes were applied
        } catch (Exception e) {
            writeln("Error applying resolution changes: ", e.msg);
            // Ensure the flag is reset to avoid repeated attempts
            currentOptions.hasPendingResolutionChange = false;
            try {
                saveOptionsToFile();
            } catch (Exception saveEx) {
                writeln("Error saving options file: ", saveEx.msg);
            }
        }
        
        return false; // No changes were applied
    }

    void update(float deltaTime) {
        if (!_isActive) return;

        Vector2 mousePos = GetMousePositionVirtual();

        // Handle mouse button release for all sliders
        if (IsMouseButtonReleased(MouseButton.MOUSE_BUTTON_LEFT)) {
            if (isDraggingMasterSlider || isDraggingMusicSlider || isDraggingEffectsSlider) {
                // Play a sound effect when the slider is released
                if (audioManager !is null) {
                    // Play a click sound or similar feedback
                    audioManager.playSound("resources/audio/sfx/gotset2.ogg", AudioType.SFX);
                }
                
                // Apply audio settings when slider is released (final application)
                applyAudioSettings();
                
                // Reset all dragging states
                isDraggingMasterSlider = false;
                isDraggingMusicSlider = false;
                isDraggingEffectsSlider = false;
            }
        }

        // Handle active slider dragging
        if (IsMouseButtonDown(MouseButton.MOUSE_BUTTON_LEFT)) {
            if (isDraggingMasterSlider) {
                updateSliderValue(masterVolumeSliderRect, mousePos.x, currentOptions.masterVolume);
            }
            if (isDraggingMusicSlider) {
                updateSliderValue(musicVolumeSliderRect, mousePos.x, currentOptions.musicVolume);
            }
            if (isDraggingEffectsSlider) {
                updateSliderValue(sfxVolumeSliderRect, mousePos.x, currentOptions.sfxVolume);
            }
        }

        if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
            if (CheckCollisionPointRec(mousePos, backButtonRect)) {
                // Sound for back button is already handled in hide() or when it was added
                hide();
                return; // Exit update after hiding
            }

            // Handle category clicks (visual tabs)
            // The drawing logic for tabs is in the draw() method.
            // We need to replicate the tab rectangle calculation here for click detection.
            float panelX = (VIRTUAL_SCREEN_WIDTH - (VIRTUAL_SCREEN_WIDTH * 0.8f)) / 2;
            float panelWidth = VIRTUAL_SCREEN_WIDTH * 0.8f;
            float actualPanelY = (VIRTUAL_SCREEN_HEIGHT - (VIRTUAL_SCREEN_HEIGHT * 0.8f)) / 2;
            float actualCategoryTabYStart = actualPanelY + 80;

            foreach (i, category; optionCategories) {
                Rectangle tabRect = Rectangle(panelX + 20, actualCategoryTabYStart + (i * 60), panelWidth * 0.2f - 40, 50);
                if (CheckCollisionPointRec(mousePos, tabRect)) {
                    if (selectedCategoryIndex != cast(int)i) {
                        selectedCategoryIndex = cast(int)i;
                        if (audioManager !is null) {
                            audioManager.playSound("resources/audio/sfx/menuclick.ogg", AudioType.SFX); // Corrected sound
                        }
                    }
                    break; 
                }
            }
            
            // Check for slider handle clicks to play sound on drag start
            if (selectedCategoryIndex == 1) { // Audio category
                bool sliderClicked = false;
                if (CheckCollisionPointRec(mousePos, masterVolumeSliderRect)) {
                    isDraggingMasterSlider = true;
                    updateSliderValue(masterVolumeSliderRect, mousePos.x, currentOptions.masterVolume);
                    sliderClicked = true;
                }
                
                if (CheckCollisionPointRec(mousePos, musicVolumeSliderRect)) {
                    isDraggingMusicSlider = true;
                    updateSliderValue(musicVolumeSliderRect, mousePos.x, currentOptions.musicVolume);
                    sliderClicked = true;
                }
                
                if (CheckCollisionPointRec(mousePos, sfxVolumeSliderRect)) {
                    isDraggingEffectsSlider = true;
                    updateSliderValue(sfxVolumeSliderRect, mousePos.x, currentOptions.sfxVolume);
                    sliderClicked = true;
                }

                if (sliderClicked && audioManager !is null) {
                    audioManager.playSound("resources/audio/sfx/menuclick.ogg", AudioType.SFX);
                }
            }
        }

        // Category navigation with keys
        bool categoryChangedByKeyboard = false;
        if (IsKeyPressed(KeyboardKey.KEY_UP)) {
            selectedCategoryIndex = cast(int)((selectedCategoryIndex - 1 + optionCategories.length) % optionCategories.length);
            categoryChangedByKeyboard = true;
        } else if (IsKeyPressed(KeyboardKey.KEY_DOWN)) {
            selectedCategoryIndex = cast(int)((selectedCategoryIndex + 1) % optionCategories.length);
            categoryChangedByKeyboard = true;
        }

        if (categoryChangedByKeyboard && audioManager !is null) {
            audioManager.playSound("resources/audio/sfx/menuclick.ogg", AudioType.SFX);
        }
        
        updateCurrentCategoryOptions(mousePos); // Pass mousePos for click handling
    }

    void updateCurrentCategoryOptions(Vector2 mousePos) {
        if (!IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) return;

        // Define layout variables for interactable elements
        float panelX = VIRTUAL_SCREEN_WIDTH * 0.25f; // This panelX is different from the main panelX in draw()
                                                    // It refers to the options area, not the category tabs area.
                                                    // Let's use the one from drawCurrentCategoryOptionsLayout for consistency
        float mainPanelX = (VIRTUAL_SCREEN_WIDTH - (VIRTUAL_SCREEN_WIDTH * 0.8f)) / 2;
        float optionsContentX = mainPanelX + (VIRTUAL_SCREEN_WIDTH * 0.8f) * 0.2f + 20; // x from drawCurrentCategoryOptionsLayout
        float optionsContentWidth = (VIRTUAL_SCREEN_WIDTH * 0.8f) * 0.8f - 40; // width from drawCurrentCategoryOptionsLayout

        float interactableXPos = optionsContentX + optionsContentWidth / 2; // Centered or specific offset within options area
        float initialYPos = (VIRTUAL_SCREEN_HEIGHT - (VIRTUAL_SCREEN_HEIGHT * 0.8f)) / 2 + 80 + 70; // panelY + header + initial spacing

        float yPos = initialYPos; // Reset yPos for each category's layout logic

        switch (optionCategories[selectedCategoryIndex]) {
            case "Video":
                // Fullscreen Toggle
                // The fullscreenToggleRect is defined in drawCurrentCategoryOptionsLayout and used here.
                // Its yPos is initialYPos.
                if (CheckCollisionPointRec(mousePos, fullscreenToggleRect)) {
                    currentOptions.fullscreen = !currentOptions.fullscreen;
                    currentOptions.hasPendingResolutionChange = true;
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }
                // yPos for vsync is initialYPos + 40
                // The vsyncToggleRect is defined in drawCurrentCategoryOptionsLayout and used here.
                if (CheckCollisionPointRec(mousePos, vsyncToggleRect)) {
                    currentOptions.vsync = !currentOptions.vsync;
                    applyVideoSettings(true); // Apply VSync immediately
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }
                
                // Resolution Arrows
                // The resolutionLeftArrowRect and resolutionRightArrowRect are defined in drawCurrentCategoryOptionsLayout.
                // Their yPos is initialYPos + 40 + 40.
                if (CheckCollisionPointRec(mousePos, resolutionLeftArrowRect)) {
                    currentResolutionIndex = (currentResolutionIndex - 1 + cast(int)supportedResolutions.length) % cast(int)supportedResolutions.length;
                    currentOptions.resolution = supportedResolutions[currentResolutionIndex];
                    currentOptions.hasPendingResolutionChange = true;
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }
                if (CheckCollisionPointRec(mousePos, resolutionRightArrowRect)) {
                    currentResolutionIndex = (currentResolutionIndex + 1) % cast(int)supportedResolutions.length;
                    currentOptions.resolution = supportedResolutions[currentResolutionIndex];
                    currentOptions.hasPendingResolutionChange = true;
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }
                break;
            case "Audio":
                float audioYPos = initialYPos; // Start Y for audio options
                audioYPos += 40; // After Master Volume label + slider
                audioYPos += 40; // After Music Volume label + slider
                audioYPos += 40; // After SFX Volume label + slider
                // Now audioYPos is at the start of the Mute option
                
                muteToggleRect = Rectangle(optionsContentX + optionsContentWidth / 2, audioYPos, 100, 24); // Use same X as other toggles
                if (CheckCollisionPointRec(mousePos, muteToggleRect)) {
                    currentOptions.mute = !currentOptions.mute;
                    applyAudioSettings(); // Apply immediately
                    if (audioManager !is null) {
                        audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX); 
                    }
                }

                // Calculate the Y position for the mute toggle, mirroring drawCurrentCategoryOptionsLayout
                float yPosForMuteClickCheck = initialYPos; 
                yPosForMuteClickCheck += 40; // Master Volume label + slider
                yPosForMuteClickCheck += 40; // Music Volume label + slider
                yPosForMuteClickCheck += 40; // SFX Volume label + slider
                
                // Account for keyboard control hints' vertical space, as in drawCurrentCategoryOptionsLayout
                yPosForMuteClickCheck += 30; // "Press 1-3 to increase, Shift+1-3 to decrease volume"
                yPosForMuteClickCheck += 20; // Spacing before "Keyboard Controls:"
                yPosForMuteClickCheck += 25; // "Keyboard Controls:" line
                yPosForMuteClickCheck += 20; // "Press 1: Adjust Master Volume (+/-)"
                yPosForMuteClickCheck += 20; // "Press 2: Adjust Music Volume (+/-)"
                yPosForMuteClickCheck += 20; // "Press 3: Adjust SFX Volume (+/-)"
                yPosForMuteClickCheck += 40; // "Hold Shift + Number: Decrease Volume" and spacing after
                yPosForMuteClickCheck += 40; // Music Style and spacing after

                // Music Style Arrows - positioned right before the mute toggle
                float musicStyleYPos = yPosForMuteClickCheck - 40; // Music Style is 40 pixels above mute toggle
                if (CheckCollisionPointRec(mousePos, musicStyleLeftArrowRect)) {
                    currentOptions.musicStyle = (currentOptions.musicStyle == 1) ? 2 : 1; // Toggle between 1 (Original) and 2 (Arranged)
                    applyGameplaySettings();
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }
                if (CheckCollisionPointRec(mousePos, musicStyleRightArrowRect)) {
                    currentOptions.musicStyle = (currentOptions.musicStyle == 1) ? 2 : 1; // Toggle between 1 (Original) and 2 (Arranged)
                    applyGameplaySettings();
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }

                // Define the clickable rectangle for the mute toggle using the corrected Y position
                // Note: optionsContentX + optionsContentWidth / 2 should be equivalent to interactableXPos used in draw
                Rectangle actualMuteToggleRect = Rectangle(optionsContentX + optionsContentWidth / 2, yPosForMuteClickCheck, 100, 24);
                
                if (CheckCollisionPointRec(mousePos, actualMuteToggleRect)) {
                    currentOptions.mute = !currentOptions.mute;
                    applyAudioSettings(); // Apply immediately
                    if (audioManager !is null) {
                        audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX); 
                    }
                }
                break;
            case "Gameplay":
                // Auto Save Toggle
                // The autoSaveToggleRect is defined in drawCurrentCategoryOptionsLayout. Its yPos is initialYPos.
                if (CheckCollisionPointRec(mousePos, autoSaveToggleRect)) {
                    currentOptions.autoSave = !currentOptions.autoSave;
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }
                // Random Backdrops Toggle
                // The randomBackdropsToggleRect is defined in drawCurrentCategoryOptionsLayout. Its yPos is initialYPos + 40.
                if (CheckCollisionPointRec(mousePos, randomBackdropsToggleRect)) {
                    currentOptions.randomBackdrops = !currentOptions.randomBackdrops;
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }

                // Gem Style Arrows
                // The gemStyleLeftArrowRect and gemStyleRightArrowRect are defined in drawCurrentCategoryOptionsLayout.
                // Their yPos is initialYPos + 40 + 40.
                if (CheckCollisionPointRec(mousePos, gemStyleLeftArrowRect)) {
                    currentOptions.gemStyle = (currentOptions.gemStyle - 1);
                    if (currentOptions.gemStyle < 1) currentOptions.gemStyle = 3; // Cycle from 1 to 3
                    applyGameplaySettings();
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }
                if (CheckCollisionPointRec(mousePos, gemStyleRightArrowRect)) {
                    currentOptions.gemStyle = (currentOptions.gemStyle + 1);
                    if (currentOptions.gemStyle > 3) currentOptions.gemStyle = 1; // Cycle from 1 to 3
                    applyGameplaySettings();
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }

                // System Mode Arrows
                // The systemModeLeftArrowRect and systemModeRightArrowRect are defined in drawCurrentCategoryOptionsLayout.
                // Their yPos is initialYPos + 40 + 40 + 40.
                if (CheckCollisionPointRec(mousePos, systemModeLeftArrowRect)) {
                    currentOptions.systemMode = (currentOptions.systemMode == 1) ? 2 : 1; // Toggle between 1 and 2
                    applyGameplaySettings();
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }
                if (CheckCollisionPointRec(mousePos, systemModeRightArrowRect)) {
                    currentOptions.systemMode = (currentOptions.systemMode == 1) ? 2 : 1; // Toggle between 1 and 2
                    applyGameplaySettings();
                    if (audioManager !is null) audioManager.playSound("resources/audio/sfx/select.ogg", AudioType.SFX);
                }
                break;
            case "Controls":
                // Placeholder for control settings
                break;
            default:
                break;
        }
    }

    void draw() {
        if (!_isActive) return;

        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, Color(0, 0, 0, 150));

        float panelWidth = VIRTUAL_SCREEN_WIDTH * 0.8f;
        float panelHeight = VIRTUAL_SCREEN_HEIGHT * 0.8f;
        float panelX = (VIRTUAL_SCREEN_WIDTH - panelWidth) / 2;
        float panelY = (VIRTUAL_SCREEN_HEIGHT - panelHeight) / 2;
        DrawRectangleRounded(Rectangle(panelX, panelY, panelWidth, panelHeight), 0.1f, 10, Color(30, 30, 30, 230));
        DrawRectangleRoundedLinesEx(Rectangle(panelX, panelY, panelWidth, panelHeight), 0.1f, 10, 2.0f, Colors.GRAY); // Corrected: Changed to DrawRectangleRoundedLinesEx

        DrawTextEx(app.fontFamily[0], "OPTIONS".toStringz(), Vector2(panelX + 20, panelY + 20), 32, 2, Colors.WHITE);

        // Draw Category Tabs
        float categoryTabX = panelX + (VIRTUAL_SCREEN_WIDTH * 0.2f / 2); // Centered in the left 20% of the panel
        float categoryTabYStart = panelY + 80;
        foreach (i, category; optionCategories) {
            Rectangle tabRect = Rectangle(panelX + 20, categoryTabYStart + (i * 60), panelWidth * 0.2f - 40, 50);
            Color tabColor = (i == selectedCategoryIndex) ? Color(70, 70, 70, 255) : Color(40, 40, 40, 255);
            DrawRectangleRec(tabRect, tabColor);
            DrawRectangleLinesEx(tabRect, 2, (i == selectedCategoryIndex) ? Colors.YELLOW : Colors.DARKGRAY);
            DrawTextEx(app.fontFamily[1], category.toStringz(), Vector2(tabRect.x + 15, tabRect.y + 15), 24, 1, Colors.WHITE);
        }

        // Draw Back Button
        DrawRectangleRec(backButtonRect, Color(100, 0, 0, 255));
        DrawTextEx(app.fontFamily[0], "BACK".toStringz(), Vector2(backButtonRect.x + 60, backButtonRect.y + 15), 24, 1, Colors.WHITE);
        if (CheckCollisionPointRec(GetMousePositionVirtual(), backButtonRect)) {
            DrawRectangleLinesEx(backButtonRect, 2, Colors.YELLOW);
        }


        // Draw options for the selected category
        float optionsPanelX = panelX + panelWidth * 0.2f + 20;
        float optionsPanelY = panelY + 80;
        float optionsPanelWidth = panelWidth * 0.8f - 40;
        float optionsPanelHeight = panelHeight - 100;
        drawCurrentCategoryOptionsLayout(optionsPanelX, optionsPanelY, optionsPanelWidth, optionsPanelHeight);
    }

    void drawCurrentCategoryOptionsLayout(float x, float y, float width, float height) {
        // DrawRectangle(cast(int)x, cast(int)y, cast(int)width, cast(int)height, Color(50,50,50,200)); // Background for options area
        DrawTextEx(app.fontFamily[0], (optionCategories[selectedCategoryIndex] ~ " Settings").toStringz(), Vector2(x + 20, y + 20), 28, 2, Colors.WHITE);

        float yPos = y + 70;
        float labelXPos = x + 30;
        float interactableXPos = x + width / 2; // X position for toggles/sliders
        float valueXPos = x + width - 150; // X for displaying current value text

        // Define arrow button properties
        float arrowButtonWidth = 30;
        float arrowButtonHeight = 24;
        float arrowSpacing = 5;
        // Calculate X positions for arrows around the displayed value text
        // The value text is drawn starting at interactableXPos or a similar centered position.
        // Let's assume the value text itself is about 100-150px wide for centering arrows.
        float valueTextDisplayWidth = 150; // Estimated width for the resolution/style text
        float leftArrowX = interactableXPos - (valueTextDisplayWidth / 2) - arrowButtonWidth - arrowSpacing;
        float rightArrowX = interactableXPos + (valueTextDisplayWidth / 2) + arrowSpacing;
        // A simpler approach for arrows: place them directly to the left/right of the interactableXPos (center of the option value)
        // This might be better if the value text width varies a lot.
        float simplerLeftArrowX = interactableXPos - arrowButtonWidth - arrowSpacing - 50; // Nudge left of center
        float simplerRightArrowX = interactableXPos + arrowSpacing + 50; // Nudge right of center


        switch (optionCategories[selectedCategoryIndex]) {
            case "Video":
                DrawTextEx(app.fontFamily[1], "Fullscreen:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                fullscreenToggleRect = Rectangle(interactableXPos, yPos, 100, 24); // Assign to class member if needed in update
                DrawRectangleRec(fullscreenToggleRect, currentOptions.fullscreen ? Colors.LIME : Colors.MAROON);
                DrawTextEx(app.fontFamily[2], (currentOptions.fullscreen ? "ON" : "OFF").toStringz(), Vector2(interactableXPos + 35, yPos + 2), 20, 1, Colors.BLACK);
                yPos += 40;

                DrawTextEx(app.fontFamily[1], "VSync:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                vsyncToggleRect = Rectangle(interactableXPos, yPos, 100, 24); // Assign to class member
                DrawRectangleRec(vsyncToggleRect, currentOptions.vsync ? Colors.LIME : Colors.MAROON);
                DrawTextEx(app.fontFamily[2], (currentOptions.vsync ? "ON" : "OFF").toStringz(), Vector2(interactableXPos + 35, yPos + 2), 20, 1, Colors.BLACK);
                yPos += 40;
                
                DrawTextEx(app.fontFamily[1], "Resolution:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                // Arrow positions for resolution
                float resValueTextX = interactableXPos - (MeasureTextEx(app.fontFamily[2], supportedResolutions[currentResolutionIndex].toStringz(), 24, 1).x / 2); // Center the text
                resolutionLeftArrowRect = Rectangle(resValueTextX - arrowButtonWidth - arrowSpacing, yPos, arrowButtonWidth, arrowButtonHeight);
                resolutionRightArrowRect = Rectangle(resValueTextX + MeasureTextEx(app.fontFamily[2], supportedResolutions[currentResolutionIndex].toStringz(), 24, 1).x + arrowSpacing, yPos, arrowButtonWidth, arrowButtonHeight);

                DrawRectangleRec(resolutionLeftArrowRect, Colors.DARKGRAY);
                DrawTextEx(app.fontFamily[2], "<".toStringz(), Vector2(resolutionLeftArrowRect.x + 10, resolutionLeftArrowRect.y + 2), 24, 1, Colors.WHITE);
                DrawTextEx(app.fontFamily[2], supportedResolutions[currentResolutionIndex].toStringz(), Vector2(resValueTextX, yPos +2), 24, 1, Colors.YELLOW);
                DrawRectangleRec(resolutionRightArrowRect, Colors.DARKGRAY);
                DrawTextEx(app.fontFamily[2], ">".toStringz(), Vector2(resolutionRightArrowRect.x + 10, resolutionRightArrowRect.y + 2), 24, 1, Colors.WHITE);
                yPos += 40;
                
                if (currentOptions.hasPendingResolutionChange) {
                    DrawTextEx(app.fontFamily[2], "* Display changes will apply on game restart".toStringz(), 
                               Vector2(labelXPos, yPos + 2), 18, 1, Colors.ORANGE);
                    yPos += 30;
                }

                break;
            case "Audio":
                DrawTextEx(app.fontFamily[1], "Master Volume:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                
                // Master volume slider
                masterVolumeSliderRect = Rectangle(interactableXPos, yPos, sliderWidth, sliderHeight);
                DrawRectangleRec(masterVolumeSliderRect, Color(60, 60, 60, 255)); // Slider background
                DrawRectangleLinesEx(masterVolumeSliderRect, 1, Colors.GRAY); // Slider border
                
                // Draw filled portion of the slider
                float masterFillWidth = (currentOptions.masterVolume / 100.0f) * sliderWidth;
                DrawRectangleRec(Rectangle(interactableXPos, yPos, masterFillWidth, sliderHeight), Color(0, 120, 200, 255));
                
                // Draw slider handle
                float masterHandleX = interactableXPos + masterFillWidth - 5;
                DrawRectangleRec(Rectangle(masterHandleX, yPos - 5, 10, sliderHeight + 10), Colors.WHITE);
                
                // Display current value
                DrawTextEx(app.fontFamily[2], currentOptions.masterVolume.to!string.toStringz(), Vector2(valueXPos, yPos + 2), 24, 1, Colors.YELLOW);
                
                // Add key hint (1)
                DrawTextEx(app.fontFamily[2], "[1]".toStringz(), Vector2(labelXPos - 30, yPos + 2), 18, 1, Colors.DARKGRAY);
                yPos += 40;

                DrawTextEx(app.fontFamily[1], "Music Volume:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                
                // Music volume slider
                musicVolumeSliderRect = Rectangle(interactableXPos, yPos, sliderWidth, sliderHeight);
                DrawRectangleRec(musicVolumeSliderRect, Color(60, 60, 60, 255)); // Slider background
                DrawRectangleLinesEx(musicVolumeSliderRect, 1, Colors.GRAY); // Slider border
                
                // Draw filled portion of the slider
                float musicFillWidth = (currentOptions.musicVolume / 100.0f) * sliderWidth;
                DrawRectangleRec(Rectangle(interactableXPos, yPos, musicFillWidth, sliderHeight), Color(0, 120, 200, 255));
                
                // Draw slider handle
                float musicHandleX = interactableXPos + musicFillWidth - 5;
                DrawRectangleRec(Rectangle(musicHandleX, yPos - 5, 10, sliderHeight + 10), Colors.WHITE);
                
                // Display current value
                DrawTextEx(app.fontFamily[2], currentOptions.musicVolume.to!string.toStringz(), Vector2(valueXPos, yPos + 2), 24, 1, Colors.YELLOW);
                
                // Add key hint (2)
                DrawTextEx(app.fontFamily[2], "[2]".toStringz(), Vector2(labelXPos - 30, yPos + 2), 18, 1, Colors.DARKGRAY);
                yPos += 40;

                DrawTextEx(app.fontFamily[1], "SFX Volume:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                
                // SFX volume slider
                sfxVolumeSliderRect = Rectangle(interactableXPos, yPos, sliderWidth, sliderHeight);
                DrawRectangleRec(sfxVolumeSliderRect, Color(60, 60, 60, 255)); // Slider background
                DrawRectangleLinesEx(sfxVolumeSliderRect, 1, Colors.GRAY); // Slider border
                
                // Draw filled portion of the slider
                float sfxFillWidth = (currentOptions.sfxVolume / 100.0f) * sliderWidth;
                DrawRectangleRec(Rectangle(interactableXPos, yPos, sfxFillWidth, sliderHeight), Color(0, 120, 200, 255));
                
                // Draw slider handle
                float sfxHandleX = interactableXPos + sfxFillWidth - 5;
                DrawRectangleRec(Rectangle(sfxHandleX, yPos - 5, 10, sliderHeight + 10), Colors.WHITE);
                
                // Display current value
                DrawTextEx(app.fontFamily[2], currentOptions.sfxVolume.to!string.toStringz(), Vector2(valueXPos, yPos + 2), 24, 1, Colors.YELLOW);
                
                // Add key hint (3)
                DrawTextEx(app.fontFamily[2], "[3]".toStringz(), Vector2(labelXPos - 30, yPos + 2), 18, 1, Colors.DARKGRAY);
                yPos += 40;
                
                // Add keyboard control hint
                DrawTextEx(app.fontFamily[2], "Press 1-3 to increase, Shift+1-3 to decrease volume".toStringz(), 
                           Vector2(labelXPos, yPos + 10), 18, 1, Colors.LIGHTGRAY);
                yPos += 30;
                
                // Add keyboard control hints
                yPos += 20;
                DrawTextEx(app.fontFamily[2], "Keyboard Controls:".toStringz(), Vector2(labelXPos, yPos), 20, 1, Colors.LIGHTGRAY);
                yPos += 25;
                DrawTextEx(app.fontFamily[2], "Press 1: Adjust Master Volume (+/-)".toStringz(), Vector2(labelXPos + 20, yPos), 18, 1, Colors.LIGHTGRAY);
                yPos += 20;
                DrawTextEx(app.fontFamily[2], "Press 2: Adjust Music Volume (+/-)".toStringz(), Vector2(labelXPos + 20, yPos), 18, 1, Colors.LIGHTGRAY);
                yPos += 20;
                DrawTextEx(app.fontFamily[2], "Press 3: Adjust SFX Volume (+/-)".toStringz(), Vector2(labelXPos + 20, yPos), 18, 1, Colors.LIGHTGRAY);
                yPos += 20;
                DrawTextEx(app.fontFamily[2], "Hold Shift + Number: Decrease Volume".toStringz(), Vector2(labelXPos + 20, yPos), 18, 1, Colors.LIGHTGRAY);
                yPos += 40;

                DrawTextEx(app.fontFamily[1], "Music Style:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                string musicStyleStr = (currentOptions.musicStyle == 1) ? "Original" : "Arranged";
                if (currentOptions.musicStyle != 1 && currentOptions.musicStyle != 2) currentOptions.musicStyle = 2; // Default to Arranged if invalid

                float musicStyleTextX = interactableXPos - (MeasureTextEx(app.fontFamily[2], musicStyleStr.toStringz(), 24, 1).x / 2); // Center the text
                musicStyleLeftArrowRect = Rectangle(musicStyleTextX - arrowButtonWidth - arrowSpacing, yPos, arrowButtonWidth, arrowButtonHeight);
                musicStyleRightArrowRect = Rectangle(musicStyleTextX + MeasureTextEx(app.fontFamily[2], musicStyleStr.toStringz(), 24, 1).x + arrowSpacing, yPos, arrowButtonWidth, arrowButtonHeight);

                DrawRectangleRec(musicStyleLeftArrowRect, Colors.DARKGRAY);
                DrawTextEx(app.fontFamily[2], "<".toStringz(), Vector2(musicStyleLeftArrowRect.x + 10, musicStyleLeftArrowRect.y + 2), 24, 1, Colors.WHITE);
                DrawTextEx(app.fontFamily[2], musicStyleStr.toStringz(), Vector2(musicStyleTextX, yPos + 2), 24, 1, Colors.YELLOW);
                DrawRectangleRec(musicStyleRightArrowRect, Colors.DARKGRAY);
                DrawTextEx(app.fontFamily[2], ">".toStringz(), Vector2(musicStyleRightArrowRect.x + 10, musicStyleRightArrowRect.y + 2), 24, 1, Colors.WHITE);
                yPos += 40;

                DrawTextEx(app.fontFamily[1], "Mute All:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                muteToggleRect = Rectangle(interactableXPos, yPos, 100, 24); // Assign to class member
                DrawRectangleRec(muteToggleRect, currentOptions.mute ? Colors.LIME : Colors.MAROON);
                DrawTextEx(app.fontFamily[2], (currentOptions.mute ? "ON" : "OFF").toStringz(), Vector2(interactableXPos + 35, yPos + 2), 20, 1, Colors.BLACK);
                break;
            case "Gameplay":
                DrawTextEx(app.fontFamily[1], "Auto Save:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                autoSaveToggleRect = Rectangle(interactableXPos, yPos, 100, 24); // Assign to class member
                DrawRectangleRec(autoSaveToggleRect, currentOptions.autoSave ? Colors.LIME : Colors.MAROON);
                DrawTextEx(app.fontFamily[2], (currentOptions.autoSave ? "ON" : "OFF").toStringz(), Vector2(interactableXPos + 35, yPos + 2), 20, 1, Colors.BLACK);
                yPos += 40;

                DrawTextEx(app.fontFamily[1], "Random Backdrops:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                randomBackdropsToggleRect = Rectangle(interactableXPos, yPos, 100, 24); // Assign to class member
                DrawRectangleRec(randomBackdropsToggleRect, currentOptions.randomBackdrops ? Colors.LIME : Colors.MAROON);
                DrawTextEx(app.fontFamily[2], (currentOptions.randomBackdrops ? "ON" : "OFF").toStringz(), Vector2(interactableXPos + 35, yPos + 2), 20, 1, Colors.BLACK);
                yPos += 40;

                DrawTextEx(app.fontFamily[1], "Gem Style:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                string gemStyleStr;
                switch(currentOptions.gemStyle) {
                    case 1: gemStyleStr = "Classic"; break;
                    case 2: gemStyleStr = "Modern"; break;
                    case 3: gemStyleStr = "Retro"; break;
                    default: gemStyleStr = "Unknown"; currentOptions.gemStyle = 1; break; // Default to 1 if invalid
                }
                float gemStyleTextX = interactableXPos - (MeasureTextEx(app.fontFamily[2], gemStyleStr.toStringz(), 24, 1).x / 2); // Center the text
                gemStyleLeftArrowRect = Rectangle(gemStyleTextX - arrowButtonWidth - arrowSpacing, yPos, arrowButtonWidth, arrowButtonHeight);
                gemStyleRightArrowRect = Rectangle(gemStyleTextX + MeasureTextEx(app.fontFamily[2], gemStyleStr.toStringz(), 24, 1).x + arrowSpacing, yPos, arrowButtonWidth, arrowButtonHeight);
                
                DrawRectangleRec(gemStyleLeftArrowRect, Colors.DARKGRAY);
                DrawTextEx(app.fontFamily[2], "<".toStringz(), Vector2(gemStyleLeftArrowRect.x + 10, gemStyleLeftArrowRect.y + 2), 24, 1, Colors.WHITE);
                DrawTextEx(app.fontFamily[2], gemStyleStr.toStringz(), Vector2(gemStyleTextX, yPos + 2), 24, 1, Colors.YELLOW);
                DrawRectangleRec(gemStyleRightArrowRect, Colors.DARKGRAY);
                DrawTextEx(app.fontFamily[2], ">".toStringz(), Vector2(gemStyleRightArrowRect.x + 10, gemStyleRightArrowRect.y + 2), 24, 1, Colors.WHITE);
                yPos += 40;

                DrawTextEx(app.fontFamily[1], "System Mode:".toStringz(), Vector2(labelXPos, yPos + 2), 24, 1, Colors.RAYWHITE);
                string systemModeStr = (currentOptions.systemMode == 1) ? "Original" : "Arranged";
                if (currentOptions.systemMode != 1 && currentOptions.systemMode != 2) currentOptions.systemMode = 1; // Default to 1 if invalid

                float systemModeTextX = interactableXPos - (MeasureTextEx(app.fontFamily[2], systemModeStr.toStringz(), 24, 1).x / 2); // Center the text
                systemModeLeftArrowRect = Rectangle(systemModeTextX - arrowButtonWidth - arrowSpacing, yPos, arrowButtonWidth, arrowButtonHeight);
                systemModeRightArrowRect = Rectangle(systemModeTextX + MeasureTextEx(app.fontFamily[2], systemModeStr.toStringz(), 24, 1).x + arrowSpacing, yPos, arrowButtonWidth, arrowButtonHeight);

                DrawRectangleRec(systemModeLeftArrowRect, Colors.DARKGRAY);
                DrawTextEx(app.fontFamily[2], "<".toStringz(), Vector2(systemModeLeftArrowRect.x + 10, systemModeLeftArrowRect.y + 2), 24, 1, Colors.WHITE);
                DrawTextEx(app.fontFamily[2], systemModeStr.toStringz(), Vector2(systemModeTextX, yPos + 2), 24, 1, Colors.YELLOW);
                DrawRectangleRec(systemModeRightArrowRect, Colors.DARKGRAY);
                DrawTextEx(app.fontFamily[2], ">".toStringz(), Vector2(systemModeRightArrowRect.x + 10, systemModeRightArrowRect.y + 2), 24, 1, Colors.WHITE);
                break;
            case "Controls":
                DrawTextEx(app.fontFamily[1], "Controls configuration coming soon...".toStringz(), Vector2(labelXPos, yPos + 2), 22, 1, Colors.LIGHTGRAY);
                break;
            default:
                break;
        }
    }

    // Helper method to update slider values based on mouse position
    private void updateSliderValue(Rectangle sliderRect, float mouseX, ref int value) {
        // Calculate the position of the slider handle
        float sliderLeft = sliderRect.x;
        float sliderRight = sliderRect.x + sliderRect.width;
        
        // Clamp the mouse position to the slider bounds
        float clampedX = max(sliderLeft, min(mouseX, sliderRight));
        
        // Calculate the value (0-100) based on the position
        float percentage = (clampedX - sliderLeft) / sliderRect.width;
        int newValue = cast(int)(percentage * 100);
        
        // Only apply if value has changed
        if (value != newValue) {
            value = newValue;
            // Apply audio settings immediately for real-time feedback
            applyAudioSettings();
        }
    }

    private Tuple!(string, string)[string] parseIniSection(string[] lines, string sectionName) {
        Tuple!(string, string)[string] sectionData = null; // Initialize as null
        bool inSection = false;
        foreach (line; lines) {
            string sLine = line.strip();
            if (sLine.startsWith("[") && sLine.endsWith("]")) {
                inSection = (sLine == "[" ~ sectionName ~ "]");
                continue;
            }
            if (inSection && !sLine.startsWith("#") && !sLine.empty) {
                auto idx = sLine.indexOf('='); // Find the first '='
                if (idx != -1) {
                    string key = sLine[0 .. idx].strip();
                    string value = sLine[idx+1 .. $].strip();
                    if (sectionData is null) { // Allocate on first use
                        sectionData = new Tuple!(string, string)[string]; // Corrected: Allocate empty AA
                    }
                    sectionData[key] = tuple(key, value);
                }
            }
        }
        // If the section was never found or had no valid entries, sectionData might still be null.
        // It's often better to return an empty, non-null map in such cases.
        if (sectionData is null) {
            sectionData = new Tuple!(string, string)[string]; // Corrected: Allocate empty AA
        }
        return sectionData;
    }

    private string getIniValue(Tuple!(string, string)[string] sectionData, string key, string defaultValue = "") {
        if (key in sectionData) { // Corrected
            return sectionData[key].tupleof[1]; // Return the value part of the tuple
        }
        return defaultValue;
    }

    private void loadOptionsFromFile() {
        if (!exists(optionsFilePath)) {
            writeln("Options file not found, creating with defaults: ", optionsFilePath);
            // Set explicit defaults before saving, as GameOptions.init might be all zeros/false/null
            currentOptions.fullscreen = false;
            currentOptions.resolution = "1600x900"; // Default to a 16:9 resolution
            currentOptions.vsync = true;
            currentOptions.brightness = 1.0f;
            currentOptions.contrast = 1.0f;
            currentOptions.gamma = 1.0f;
            currentOptions.masterVolume = 80;
            currentOptions.musicVolume = 70;
            currentOptions.sfxVolume = 75;
            currentOptions.mute = false;
            currentOptions.autoSave = true;
            currentOptions.randomBackdrops = true;
            currentOptions.gemStyle = 1; // Classic
            currentOptions.systemMode = 1; // Original
            currentOptions.musicStyle = 2; // Default music style to Arranged
            currentOptions.playerName = "Player"; // Default player name
            currentOptions.hasPendingResolutionChange = false; // Initialize the flag
            
            // Update data module with default player name
            data.playerSavedName = currentOptions.playerName;
            data.playerHasSavedName = false; // No custom name saved yet

            saveOptionsToFile(); // Create it with defaults
            return;
        }

        try {
            string content = readText(optionsFilePath);
            string[] lines = content.splitLines();

            auto videoSection = parseIniSection(lines, "VideoSettings"); // Updated section name
            currentOptions.fullscreen = getIniValue(videoSection, "fullscreen", "false").to!bool;
            currentOptions.resolution = getIniValue(videoSection, "resolution", "1600x900");
            // After loading, re-check and enforce 16:9 if necessary
            string[] parts = currentOptions.resolution.split('x');
            bool is16by9 = false;
            if (parts.length == 2) {
                try {
                    int w = parts[0].to!int;
                    int h = parts[1].to!int;
                    if (w * 9 == h * 16) {
                        is16by9 = true;
                    }
                } catch (Exception e) { /* ignore parsing error */ }
            }
            if (!is16by9) {
                writeln("Loaded resolution '", currentOptions.resolution, "' is not 16:9. Resetting to default 16:9.");
                currentOptions.resolution = "1600x900"; // Default 16:9
                // No need to set hasPendingResolutionChange here, initializeResolutionIndex will handle it
            }
            currentOptions.vsync = getIniValue(videoSection, "vsync", "true").to!bool;

            // Display settings are placeholders for now
            auto displaySection = parseIniSection(lines, "DisplaySettings");
            currentOptions.brightness = getIniValue(displaySection, "brightness", "1.0").to!float;
            currentOptions.contrast = getIniValue(displaySection, "contrast", "1.0").to!float;
            currentOptions.gamma = getIniValue(displaySection, "gamma", "1.0").to!float;
            currentOptions.hasPendingResolutionChange = getIniValue(displaySection, "pending_resolution_change", "false").to!bool;

            auto audioSection = parseIniSection(lines, "AudioSettings"); // Updated section name
            currentOptions.masterVolume = getIniValue(audioSection, "master_volume", "80").to!int;
            currentOptions.musicVolume = getIniValue(audioSection, "music_volume", "70").to!int;
            currentOptions.sfxVolume = getIniValue(audioSection, "sfx_volume", "75").to!int;
            currentOptions.mute = getIniValue(audioSection, "mute", "false").to!bool;


            auto gameplaySection = parseIniSection(lines, "GameplaySettings"); // Updated section name
            currentOptions.autoSave = getIniValue(gameplaySection, "auto_save", "true").to!bool;
            currentOptions.randomBackdrops = getIniValue(gameplaySection, "random_backdrops", "true").to!bool;
            currentOptions.gemStyle = getIniValue(gameplaySection, "gem_style", "1").to!int;
            currentOptions.systemMode = getIniValue(gameplaySection, "system_mode", "1").to!int;
            currentOptions.musicStyle = getIniValue(gameplaySection, "music_style", "2").to!int; // Load musicStyle, default to Arranged

            auto playerSection = parseIniSection(lines, "PlayerSettings"); // New section for player name
            currentOptions.playerName = getIniValue(playerSection, "player_name", "Player"); // Load playerName
            
            // Update data module based on loaded player name
            data.playerSavedName = currentOptions.playerName;
            if (!currentOptions.playerName.empty && currentOptions.playerName != "Player") {
                data.playerHasSavedName = true;
            } else {
                data.playerHasSavedName = false;
                // Ensure data.playerSavedName is "Player" if loaded name is empty or "Player"
                data.playerSavedName = "Player"; 
            }
            
            // writeln("Loaded options: ", currentOptions.to!string); // .to!string for struct might need custom impl or use std.json
            printCurrentOptions();


        } catch (Exception e) {
            writeln("Error loading options: ", e.msg);
            // Fallback to defaults if loading fails
            currentOptions = GameOptions.init; // Re-init to defaults
            currentOptions.resolution = "1600x900"; // Default to a 16:9 resolution
            currentOptions.masterVolume = 80;
            currentOptions.musicVolume = 70;
            currentOptions.sfxVolume = 75;
            currentOptions.musicStyle = 2; // Default music style to Arranged
            currentOptions.playerName = "Player"; // Default player name
            
            // Update data module with default player name on error
            data.playerSavedName = currentOptions.playerName;
            data.playerHasSavedName = false;

            currentOptions.hasPendingResolutionChange = false; // Ensure this is set to false when error occurs
        }
    }

    private void saveOptionsToFile() {
        string[] lines;
        lines ~= "[VideoSettings]"; // Updated section name
        lines ~= "fullscreen=" ~ currentOptions.fullscreen.to!string;
        lines ~= "resolution=" ~ currentOptions.resolution;
        lines ~= "vsync=" ~ currentOptions.vsync.to!string;
        lines ~= "";
        lines ~= "[DisplaySettings]";
        lines ~= "brightness=" ~ currentOptions.brightness.to!string;
        lines ~= "contrast=" ~ currentOptions.contrast.to!string;
        lines ~= "gamma=" ~ currentOptions.gamma.to!string;
        lines ~= "pending_resolution_change=" ~ currentOptions.hasPendingResolutionChange.to!string;
        lines ~= "";
        lines ~= "[AudioSettings]"; // Updated section name
        lines ~= "master_volume=" ~ currentOptions.masterVolume.to!string;
        lines ~= "music_volume=" ~ currentOptions.musicVolume.to!string;
        lines ~= "sfx_volume=" ~ currentOptions.sfxVolume.to!string;
        lines ~= "mute=" ~ currentOptions.mute.to!string;
        lines ~= "";
        lines ~= "[GameplaySettings]"; // Updated section name
        lines ~= "auto_save=" ~ currentOptions.autoSave.to!string;
        lines ~= "random_backdrops=" ~ currentOptions.randomBackdrops.to!string;
        lines ~= "gem_style=" ~ currentOptions.gemStyle.to!string;
        lines ~= "system_mode=" ~ currentOptions.systemMode.to!string;
        lines ~= "music_style=" ~ currentOptions.musicStyle.to!string; // Save musicStyle
        lines ~= "";
        lines ~= "[PlayerSettings]"; // New section for player name
        // Update currentOptions.playerName from data module right before saving
        if (data.playerHasSavedName && !data.playerSavedName.empty && data.playerSavedName != "Player") {
            currentOptions.playerName = data.playerSavedName;
        } else {
            currentOptions.playerName = "Player"; // Default if no custom name is set
        }
        lines ~= "player_name=" ~ currentOptions.playerName; // Save playerName
        lines ~= "";
        lines ~= "[ControlsSettings]"; // Added for completeness
        lines ~= "# Control settings here";


        try {
            std.file.write(optionsFilePath, lines.join("\n")); // Corrected file writing
            writeln("Options saved to ", optionsFilePath);
        } catch (Exception e) {
            writeln("Error saving options: ", e.msg);
        }
    }
    
    private void applyAudioSettings() {
        if (audioManager is null) return;
        
        // Get the AudioSettings instance
        auto settings = audioManager.audioSettings;
        if (settings is null) return;
        
        // Apply master volume to AudioSettings
        settings.masterVolume = currentOptions.masterVolume * 0.01f; // Convert from 0-100 to 0.0-1.0
        
        // Apply music volume to AudioSettings
        settings.musicVolume = currentOptions.musicVolume * 0.01f;
        
        // Apply SFX volume to AudioSettings
        settings.sfxVolume = currentOptions.sfxVolume * 0.01f;
        
        // Apply mute setting (enable/disable audio types based on mute)
        // This affects whether playSound will play sounds of these types
        settings.isMusicEnabled = !currentOptions.mute;
        settings.isSFXEnabled = !currentOptions.mute;
        settings.isVoxEnabled = !currentOptions.mute;
        settings.isAmbienceEnabled = !currentOptions.mute;
        
        // Save the settings to the config file
        settings.saveSettings();
        
        // Set Raylib's global master volume (affects all sounds and music)
        if (currentOptions.mute) {
            SetMasterVolume(0.0f);
        } else {
            SetMasterVolume(settings.masterVolume);
        }

        // Update the volume of currently playing music stream
        audioManager.updateLiveMusicVolume();

        writeln("Audio settings applied: MasterVol=", currentOptions.masterVolume, 
                ", MusicVol=", currentOptions.musicVolume,
                ", SFXVol=", currentOptions.sfxVolume,
                ", Mute=", currentOptions.mute);
    }

    private void applyVideoSettings(bool skipResolutionChanges = false) {
        // Only apply VSync setting, which shouldn't cause screen flashes
        if (currentOptions.vsync) {
            SetWindowState(ConfigFlags.FLAG_VSYNC_HINT);
        } else {
            ClearWindowState(ConfigFlags.FLAG_VSYNC_HINT);
        }
        
        // Skip fullscreen and resolution changes by default to avoid flashing
        // Only apply these settings when explicitly requested (e.g., when saving options)
        if (!skipResolutionChanges) {
            // Fullscreen (borderless windowed) toggle - only do this when explicitly requested
            if (currentOptions.fullscreen && !IsWindowState(ConfigFlags.FLAG_WINDOW_UNDECORATED)) { // Changed to FLAG_WINDOW_UNDECORATED
                writeln("Borderless windowed would be enabled (deferred to game restart or explicit apply)");
                // ToggleBorderlessWindowed(); // Prefer to do this via hasPendingResolutionChange
            } else if (!currentOptions.fullscreen && IsWindowState(ConfigFlags.FLAG_WINDOW_UNDECORATED)) { // Changed to FLAG_WINDOW_UNDECORATED
                writeln("Borderless windowed would be disabled (deferred to game restart or explicit apply)");
                // ToggleBorderlessWindowed(); // Prefer to do this via hasPendingResolutionChange
            }
            
            // Resolution changes are deferred to avoid disrupting gameplay
            writeln("Resolution changes deferred to game restart: ", currentOptions.resolution);
        } else {
            writeln("Video settings partially applied (VSync only): VSync=", currentOptions.vsync);
        }
    }

    private void applyGameplaySettings() {
        // These would typically call functions in your 'data' module or similar game logic controllers
        // data.setAutoSave(currentOptions.autoSave); // Example, if data.d had this
        // data.setRandomBackdrops(currentOptions.randomBackdrops);
        
        // Apply Gem Style - Assuming a similar mechanism to System Mode or a direct setting
        // Example: data.setGemStyle(currentOptions.gemStyle); 
        
        // Apply Music Style - Don't set immediately, wait until options menu is closed
        // The music style will be applied in hide() method when options are closed
        // if (audioManager !is null) {
        //     audioManager.setMusicStyle(currentOptions.musicStyle);
        // }

        if (currentOptions.systemMode == 1) data.setCurrentGameMode(GameMode.ORIGINAL);
        else if (currentOptions.systemMode == 2) data.setCurrentGameMode(GameMode.ARRANGED);

        writeln("Gameplay settings applied: AutoSave=", currentOptions.autoSave, 
                ", RandomBackdrops=", currentOptions.randomBackdrops, 
                ", GemStyle=", currentOptions.gemStyle, 
                ", SystemMode=", currentOptions.systemMode,
                ", MusicStyle=", currentOptions.musicStyle); // Added MusicStyle to log
    }

    // Call this method to apply all settings, e.g., when closing the options screen
    private void applySettings(bool applyVideoChanges = false) {
        applyAudioSettings();
        applyVideoSettings(!applyVideoChanges);
        applyGameplaySettings();
        writeln("Settings applied (video changes: ", applyVideoChanges ? "yes" : "limited", ")");
    }

    void printCurrentOptions() {
        writeln("Current GameOptions:");
        writeln("  Fullscreen: ", currentOptions.fullscreen);
        writeln("  Resolution: ", currentOptions.resolution);
        writeln("  VSync: ", currentOptions.vsync);
        writeln("  Brightness: ", currentOptions.brightness);
        writeln("  Contrast: ", currentOptions.contrast);
        writeln("  Gamma: ", currentOptions.gamma);
        writeln("  Master Volume: ", currentOptions.masterVolume);
        writeln("  Music Volume: ", currentOptions.musicVolume);
        writeln("  SFX Volume: ", currentOptions.sfxVolume);
        writeln("  Mute: ", currentOptions.mute);
        writeln("  Auto Save: ", currentOptions.autoSave);
        writeln("  Random Backdrops: ", currentOptions.randomBackdrops);
        writeln("  Gem Style: ", currentOptions.gemStyle);
        writeln("  System Mode: ", currentOptions.systemMode);
        writeln("  Music Style: ", currentOptions.musicStyle); // Added Music Style
        writeln("  Player Name: ", currentOptions.playerName); // Added Player Name
    }
}