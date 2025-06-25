module screens.popups.name_entry;

import raylib;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.algorithm;

import world.screen_manager;
import world.screen_states;
import world.memory_manager;
import world.audio_manager;
import data;
import app;
import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, GetMousePositionVirtual;

// Define name entry textures
// Texture dialogBoxTexture;
// Texture dialogBoxAlpha;
// Texture dialogButtonTexture;
// Texture dialogButtonAlpha;
// Texture dialogButtonHover;
// Texture dialogButtonHoverAlpha;
// Texture dialogTitleTexture;
// Texture dialogTitleAlpha;
// Texture editBoxTexture;

Sound dialogOpenSound;
Sound dialogCloseSound;
Sound dialogButtonHoverSound;
Sound dialogButtonClickSound;
Sound dialogTypeSound;

// Enum for name entry states
enum NameEntryState {
    ACTIVE,
    CONFIRMED,
    CANCELLED,
    DONE
};

// Define name entry variables
int maxNameLength = 12; // Maximum length for the name entry
string greeting = "Welcome!";
string followUpQuestion = "Have we met before?";
string nameEntryPrompt = "Please enter your name:";

// Allow for a robust selection of the name entry characters
enum NameEntryCharacter {
    A, B, C, D, E, F, G, H, I, J,
    K, L, M, N, O, P, Q, R, S, T,
    U, V, W, X, Y, Z,
    NUM_0, NUM_1, NUM_2, NUM_3, NUM_4, NUM_5, NUM_6, NUM_7, NUM_8, NUM_9,
    SPACE = 36,
    BACKSPACE = 37,
    ENTER = 38,
    ESCAPE = 39,
    NONE = 40
}

class NameEntry : IScreen {
    private MemoryManager memoryManager;
    private AudioManager audioManager;
    
    private Texture2D dialogBoxTexture;
    private Texture2D dialogBoxAlpha;
    private Texture2D dialogButtonTexture;
    private Texture2D dialogButtonAlpha;
    private Texture2D dialogButtonHover;
    private Texture2D dialogButtonHoverAlpha;
    private Texture2D dialogTitleTexture;
    private Texture2D dialogTitleAlpha;
    private Texture2D editBoxTexture;

    private Sound dialogOpenSound;
    private Sound dialogCloseSound;
    private Sound dialogButtonHoverSound;
    private Sound dialogButtonClickSound;
    private Sound dialogTypeSound;

    Vector2 dialogBoxPosition;
    float dialogBoxSize;
    Vector2 dialogButtonPosition;
    float dialogButtonSize;
    Vector2 editBoxPosition;
    float editBoxSize;
    Vector2 dialogTitlePosition;

    NameEntryState nameEntryState = NameEntryState.ACTIVE;
    private string currentInputName;
    public string playerNameOutput;

    // Animation variables
    float dialogBoxScale = 0.0f;
    float dialogBoxAlphaValue = 0.0f;
    float dialogButtonScale = 0.0f;
    float dialogButtonAlphaValue = 0.0f;
    float editBoxScale = 0.0f;
    float editBoxAlphaValue = 0.0f;
    float dialogTitleScale = 0.0f;
    float dialogTitleAlphaValue = 0.0f;
    float dialogAnimationSpeed = 2.0f;

    // Public flag to indicate if the dialog is currently active
    private bool isActive = false;
    
    // Text box properties
    Rectangle textBox;
    float cursorBlinkTimer = 0.0f;

    public this() {
        memoryManager = MemoryManager.instance();
        audioManager = AudioManager.getInstance();
        initialize();
    }

    void initialize() {
        // Initialize dialog box position and size
        dialogBoxSize = 2.0f;
        dialogBoxPosition = Vector2(
            (VIRTUAL_SCREEN_WIDTH - dialogBoxSize) / 2.0f,
            (VIRTUAL_SCREEN_HEIGHT - dialogBoxSize) / 2.0f
        );

        // Load textures
        dialogBoxTexture = memoryManager.loadTexture("resources/image/ui/dialog/dialog_box.png");
        // dialogBoxAlpha = memoryManager.loadTexture("resources/image/ui/dialog/dialog_box_alpha.png");
        // dialogButtonTexture = memoryManager.loadTexture("resources/image/ui/dialog/dialog_button.png");
        // dialogButtonAlpha = memoryManager.loadTexture("resources/image/ui/dialog/dialog_button_alpha.png");
        // dialogButtonHover = memoryManager.loadTexture("resources/image/ui/dialog/dialog_button_hover.png");
        // dialogButtonHoverAlpha = memoryManager.loadTexture("resources/image/ui/dialog/dialog_button_hover_alpha.png");
        // dialogTitleTexture = memoryManager.loadTexture("resources/image/ui/dialog/dialog_title.png");
        // dialogTitleAlpha = memoryManager.loadTexture("resources/image/ui/dialog/dialog_title_alpha.png");
        // editBoxTexture = memoryManager.loadTexture("resources/image/ui/dialog/edit_box.png");

        // Initialize text box
        textBox = Rectangle(
            VIRTUAL_SCREEN_WIDTH / 2 - 100, 
            dialogBoxPosition.y + 20, 
            200, 
            40
        );

        // Apply texture filtering to fonts for better quality
        foreach (font; fontFamily) {
            if (font.texture.id > 0) {
                SetTextureFilter(font.texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
                writeln("NameEntry: Applied bilinear filtering to font texture ID: ", font.texture.id);
            }
        }

        reset();
        writeln("NameEntry: Initialized.");
    }
    
    // Call this to activate and show the dialog
    public void show() {
        reset(); // Resets currentInputName to ""
        isActive = true;
        nameEntryState = NameEntryState.ACTIVE;

        // Pre-fill with saved name if available
        if (data.playerHasSavedName && !data.playerSavedName.empty) {
            currentInputName = data.playerSavedName;
        } else {
            currentInputName = ""; // Ensure it's empty if no valid saved name
        }
        
        // Explicitly play the "twist_notify.ogg" sound when the dialog is shown.
        if (audioManager !is null) {
            // Assuming playSound takes the full path and AudioType.
            // If "twist_notify.ogg" is not loaded elsewhere, playSound might handle loading it,
            // or it might fail if it expects pre-loaded sounds by a shorter name/ID.
            // For now, let's use the full path as per AudioManager's playSound signature.
            audioManager.playSound("resources/audio/sfx/twist_notify.ogg", AudioType.SFX);
        }
        
        writeln("NameEntry: Dialog shown, attempting to play twist_notify.ogg.");
    }

    // Call this to deactivate and hide the dialog
    public void hide() {
        isActive = false;
        
        // Play the dialog close sound
        if (audioManager !is null) {
            audioManager.playSFX("resources/audio/sfx/menuclick.ogg"); // Assuming this is how your AudioManager plays sounds
        }
        
        writeln("NameEntry: Dialog hidden.");
    }

    void reset() {
        isActive = false;
        nameEntryState = NameEntryState.ACTIVE;
        // currentInputName = ""; // Do not reset here, show() will handle pre-filling or clearing
        playerNameOutput = "";
        
        // Reset animation states
        dialogBoxScale = 0.0f;
        dialogBoxAlphaValue = 0.0f;
        dialogButtonScale = 0.0f;
        dialogButtonAlphaValue = 0.0f;
        editBoxScale = 0.0f;
        editBoxAlphaValue = 0.0f;
        dialogTitleScale = 0.0f;
        dialogTitleAlphaValue = 0.0f;
        cursorBlinkTimer = 0.0f;
    

        writeln("NameEntry: Reset to initial state.");
    }
    
    string getPlayerName() {
        return playerNameOutput;
    }

    // This method checks if the dialog is currently active
    bool hasNameEntry() {
        return isActive;
    }
    
    bool isNameEntryConfirmed() {
        return nameEntryState == NameEntryState.CONFIRMED;
    }

    bool isNameEntryCancelled() {
        return nameEntryState == NameEntryState.CANCELLED;
    }

    void update(float deltaTime) {
        if (!isActive) return;

        // Update animation scales
        if (dialogBoxScale < 1.0f) {
            dialogBoxScale += dialogAnimationSpeed * deltaTime;
            if (dialogBoxScale > 1.0f) dialogBoxScale = 1.0f;
        }
        
        if (dialogButtonScale < 1.0f) {
            dialogButtonScale += dialogAnimationSpeed * deltaTime;
            if (dialogButtonScale > 1.0f) dialogButtonScale = 1.0f;
        }

        // Update cursor blink timer
        cursorBlinkTimer += deltaTime;
        if (cursorBlinkTimer >= 0.5f) {
            cursorBlinkTimer = 0.0f;
        }

        // Handle keyboard input for name entry
        int key = GetKeyPressed();
        while (key > 0) {
            if ((key >= 32) && (key <= 125) && (currentInputName.length < maxNameLength)) {
                currentInputName ~= cast(char)key;
                
                if (audioManager !is null) {
                    // Assuming "click.ogg" is the typing sound and it's loaded.
                    // If AudioManager uses short names for preloaded sounds, adjust this.
                    audioManager.playSound("resources/audio/sfx/click.ogg", AudioType.SFX);
                }
            }
            key = GetKeyPressed();
        }

        // Handle backspace
        if (IsKeyPressed(KeyboardKey.KEY_BACKSPACE)) {
            if (currentInputName.length > 0) {
                currentInputName = currentInputName[0 .. $ - 1];
                
                if (audioManager !is null) {
                    audioManager.playSound("resources/audio/sfx/click.ogg", AudioType.SFX);
                }
            }
        }

        // Handle enter (confirm)
        if (IsKeyPressed(KeyboardKey.KEY_ENTER)) {
            if (currentInputName.length > 0) {
                playerNameOutput = currentInputName;
                data.playerSavedName = playerNameOutput;
                data.playerHasSavedName = true;
                nameEntryState = NameEntryState.CONFIRMED;
                isActive = false;
                
                if (audioManager !is null) {
                    // Assuming "dialog_button_click.ogg" is loaded.
                    audioManager.playSound("resources/audio/sfx/dialog_button_click.ogg", AudioType.SFX);
                }
                
                writeln("NameEntry: Name confirmed - ", playerNameOutput);
            }
        }

        // ESC key functionality removed - players must enter a name to proceed
        // This ensures proper name entry and avoids state transition issues
    }

    void draw() {
        if (!isActive) return;

        // Draw dialog box background
        if (dialogBoxTexture.id != 0) {
            float currentWidth = dialogBoxTexture.width * dialogBoxScale;
            float currentHeight = dialogBoxTexture.height * dialogBoxScale;
            float drawX = dialogBoxPosition.x - currentWidth / 2.0f;
            float drawY = dialogBoxPosition.y - currentHeight / 2.0f;

            DrawTexturePro(
                dialogBoxTexture,
                Rectangle(0, 0, dialogBoxTexture.width, dialogBoxTexture.height),
                Rectangle(drawX, drawY, currentWidth, currentHeight),
                Vector2(0, 0), 0.0f, Colors.WHITE
            );
        } else {
            // Fallback drawing if texture not loaded
            DrawRectangleRec(Rectangle(VIRTUAL_SCREEN_WIDTH/2 - 150, VIRTUAL_SCREEN_HEIGHT/2 - 75, 300, 150), Fade(Colors.DARKGRAY, 0.8f));
        }

        // Draw greeting and prompt
        DrawTextEx(app.fontFamily[0], greeting.toStringz(), 
                   Vector2(VIRTUAL_SCREEN_WIDTH / 2 - MeasureTextEx(app.fontFamily[0], greeting.toStringz(), 28, 1).x / 2, 
                   dialogBoxPosition.y - 60), 28, 1, Colors.WHITE);
        
        DrawTextEx(app.fontFamily[0], nameEntryPrompt.toStringz(), 
                  Vector2(VIRTUAL_SCREEN_WIDTH / 2 - MeasureTextEx(app.fontFamily[0], nameEntryPrompt.toStringz(), 20, 1).x / 2, 
                  dialogBoxPosition.y - 20), 20, 1, Colors.WHITE);
        
        // Draw text input box
        DrawRectangleRec(textBox, Colors.LIGHTGRAY);
        DrawRectangleLinesEx(textBox, 2, Colors.DARKGRAY);
        DrawTextEx(app.fontFamily[0], currentInputName.toStringz(), 
                  Vector2(textBox.x + 5, textBox.y + 8), 24, 1, Colors.BLACK);

        // Draw blinking cursor
        if (cursorBlinkTimer < 0.25f) {
            Vector2 textSize = MeasureTextEx(app.fontFamily[0], currentInputName.toStringz(), 24, 1);
            DrawTextEx(app.fontFamily[0], "_".toStringz(), 
                      Vector2(textBox.x + 5 + textSize.x, textBox.y + 8), 24, 1, Colors.BLACK);
        }
        
        // Draw instructions
        DrawTextEx(app.fontFamily[0], "Press ENTER to confirm.".toStringz(), 
                  Vector2(VIRTUAL_SCREEN_WIDTH / 2 - MeasureTextEx(app.fontFamily[0], "Press ENTER to confirm.".toStringz(), 16, 1).x / 2, 
                  dialogBoxPosition.y + 80), 16, 1, Colors.WHITE);
    }

    void unload() {
        // Unload textures
        if (dialogBoxTexture.id != 0) UnloadTexture(dialogBoxTexture);
        // Unload other textures when they're implemented
        
        // Unload sounds when they're implemented
        writeln("NameEntry: Unloaded resources.");
    }
}