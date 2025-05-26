module screens.popups.name_entry;

import raylib;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.algorithm;

import world.screen_manager;
import world.screen_states;
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
string playerName = "";
bool nameEntryActive = false;
bool nameEntryConfirmed = false;
bool nameEntryCancelled = false;
bool nameEntryDone = false;
int maxNameLength = 20;
string greeting = "Welcome! Have we met before?";
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
    Vector2 dialogBoxSize;
    Vector2 dialogButtonPosition;
    Vector2 dialogButtonSize;
    Vector2 editBoxPosition;
    Vector2 editBoxSize;
    Vector2 dialogTitlePosition; // Position for the dialog title

    NameEntryState nameEntryState = NameEntryState.ACTIVE; // Current state of the name entry
    // NameEntryCharacter selectedCharacter = NameEntryCharacter.NONE; // Currently selected character for name entry - REMOVED, direct char input
    private string currentInputName; // Internal buffer for player name

    // Define variables for animating the dialog box
    float dialogBoxScale = 0.0f; // Scale for the dialog box animation
    float dialogBoxAlphaValue = 0.0f; // Alpha value for the dialog box fade-in
    float dialogButtonScale = 0.0f; // Scale for the dialog button animation
    float dialogButtonAlphaValue = 0.0f; // Alpha value for the dialog button fade-in
    float editBoxScale = 0.0f; // Scale for the edit box animation
    float editBoxAlphaValue = 0.0f; // Alpha value for the edit box fade-in
    float dialogTitleScale = 0.0f; // Scale for the dialog title animation
    float dialogTitleAlphaValue = 0.0f; // Alpha value for the dialog title fade-in
    float dialogAnimationSpeed = 0.05f; // Speed of the dialog box assets

    // Constructor to initialize the name entry screen
    public this() {
        // NOTE: Texture and Sound loading moved to initialize()
        // Initialize dialog box position and size
        initialize();
        currentInputName = ""; // Initialize player name
    }

    static NameEntry create() {
        // PlaySound(LoadSound("resources/audio/sfx/twist_notify.ogg")); // Sound will be played by TitleScreen
        return new NameEntry();
    }

    void initialize() {
        // Initialize dialog box position and size
        // Centering the dialog box (though it's not drawn for now)
        dialogBoxSize = Vector2(500, 250); // Adjusted size
        dialogBoxPosition = Vector2(
            (VIRTUAL_SCREEN_WIDTH - dialogBoxSize.x) / 2,
            (VIRTUAL_SCREEN_HEIGHT - dialogBoxSize.y) / 2
        );

        // These are not used if the box isn't drawn, but kept for potential future use
        dialogButtonPosition = Vector2(dialogBoxPosition.x + 50, dialogBoxPosition.y + dialogBoxSize.y - 70);
        dialogButtonSize = Vector2(150, 40);
        editBoxPosition = Vector2(dialogBoxPosition.x + 50, dialogBoxPosition.y + 150);
        editBoxSize = Vector2(dialogBoxSize.x - 100, 40);
        dialogTitlePosition = Vector2(dialogBoxPosition.x + (dialogBoxSize.x / 2), dialogBoxPosition.y + 20);

        dialogBoxTexture = LoadTexture("resources/image/DIALOGBOX.png");
        SetTextureFilter(dialogBoxTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        dialogBoxAlpha = LoadTexture("resources/image/DIALOGBOX_.png");
        SetTextureFilter(dialogBoxAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        dialogButtonTexture = LoadTexture("resources/image/DialogButton.png");
        SetTextureFilter(dialogButtonTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        dialogButtonAlpha = LoadTexture("resources/image/DialogButton_.png");
        SetTextureFilter(dialogButtonAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        dialogButtonHover = LoadTexture("resources/image/DialogButtonglow.png");
        SetTextureFilter(dialogButtonHover, TextureFilter.TEXTURE_FILTER_BILINEAR);
        dialogButtonHoverAlpha = LoadTexture("resources/image/DialogButtonglow_.png");
        SetTextureFilter(dialogButtonHoverAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        dialogTitleTexture = LoadTexture("resources/image/DialogTitle.png");
        SetTextureFilter(dialogTitleTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        dialogTitleAlpha = LoadTexture("resources/image/DialogTitle_.png");
        SetTextureFilter(dialogTitleAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        editBoxTexture = LoadTexture("resources/image/EditBox.png");
        // SetTextureFilter(editBoxTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        
        // Load sounds
        dialogOpenSound = LoadSound("resources/audio/sfx/twist_notify.ogg");
        dialogCloseSound = LoadSound("resources/audio/sfx/dialog_close.ogg");
        dialogButtonHoverSound = LoadSound("resources/audio/sfx/mainmenu_mouseover.ogg");
        dialogButtonClickSound = LoadSound("resources/audio/sfx/mainmenu_mouseclick.ogg"); // Changed from mainmenu_click.ogg
        dialogTypeSound = LoadSound("resources/audio/sfx/click.ogg");

        reset(); // Call reset to initialize states
    }

    void reset() {
        currentInputName = "";
        nameEntryState = NameEntryState.ACTIVE;
        nameEntryActive = true; // Dialog becomes active
        nameEntryConfirmed = false;
        nameEntryCancelled = false;
        // Reset animation states if they were used
        dialogBoxScale = 0.0f; 
        dialogBoxAlphaValue = 0.0f;
        // ... reset other animation values if needed
    }
    
    string getPlayerName() {
        return currentInputName;
    }

    bool hasNameEntry() {
        return nameEntryActive;
    }
    
    bool isNameEntryConfirmed() {
        return nameEntryConfirmed;
    }

    bool isNameEntryCancelled() {
        return nameEntryCancelled;
    }

    void update(float deltaTime) {
        if (!nameEntryActive) return;
        switch (nameEntryState) {
            case NameEntryState.ACTIVE:
            // Animate dialog box elements (optional, for future use)
            if (dialogBoxScale < 1.0f) {
                dialogBoxScale += dialogAnimationSpeed * deltaTime;
                dialogBoxAlphaValue += dialogAnimationSpeed * deltaTime;
            } else {
                dialogBoxScale = 1.0f;
                dialogBoxAlphaValue = 1.0f;
            }
            if (dialogButtonScale < 1.0f) {
                dialogButtonScale += dialogAnimationSpeed * deltaTime;
                dialogButtonAlphaValue += dialogAnimationSpeed * deltaTime;
            } else {
                dialogButtonScale = 1.0f;
                dialogButtonAlphaValue = 1.0f;
            }
            if (editBoxScale < 1.0f) {
                editBoxScale += dialogAnimationSpeed * deltaTime;
                editBoxAlphaValue += dialogAnimationSpeed * deltaTime;
            } else {
                editBoxScale = 1.0f;
                editBoxAlphaValue = 1.0f;
            }
            if (dialogTitleScale < 1.0f) {
                dialogTitleScale += dialogAnimationSpeed * deltaTime;
                dialogTitleAlphaValue += dialogAnimationSpeed * deltaTime;
            } else {
                dialogTitleScale = 1.0f;
                dialogTitleAlphaValue = 1.0f;
            }
            dialogBoxAlphaValue = clamp(dialogBoxAlphaValue, 0.0f, 1.0f);
            dialogButtonAlphaValue = clamp(dialogButtonAlphaValue, 0.0f, 1.0f);
            editBoxAlphaValue = clamp(editBoxAlphaValue, 0.0f, 1.0f);
            dialogTitleAlphaValue = clamp(dialogTitleAlphaValue, 0.0f, 1.0f);

            // --- Username entry logic ---
            // Confirm name with Enter
            if (IsKeyPressed(KeyboardKey.KEY_ENTER)) {
                if (currentInputName.length > 0) {
                nameEntryConfirmed = true;
                nameEntryState = NameEntryState.CONFIRMED;
                nameEntryActive = false;
                PlaySound(dialogButtonClickSound);
                } else {
                // Optionally play a "cannot confirm empty name" sound
                }
            }
            // Cancel with Escape
            else if (IsKeyPressed(KeyboardKey.KEY_ESCAPE)) {
                nameEntryCancelled = true;
                nameEntryState = NameEntryState.CANCELLED;
                nameEntryActive = false;
                PlaySound(dialogCloseSound);
            }
            // Handle character input
            else {
                int key;
                // Read all pressed keys this frame
                while ((key = GetKeyPressed()) != 0) {
                // Handle backspace
                if (key == KeyboardKey.KEY_BACKSPACE) {
                    if (currentInputName.length > 0) {
                    currentInputName = currentInputName[0 .. $ - 1];
                    PlaySound(dialogTypeSound);
                    }
                }
                // Accept letters, numbers, and space
                else if (currentInputName.length < maxNameLength) {
                    // Letters A-Z
                    if (key >= KeyboardKey.KEY_A && key <= KeyboardKey.KEY_Z) {
                    char c;
                    if (IsKeyDown(KeyboardKey.KEY_LEFT_SHIFT) || IsKeyDown(KeyboardKey.KEY_RIGHT_SHIFT) || IsKeyDown(KeyboardKey.KEY_CAPS_LOCK)) {
                        c = cast(char)('A' + (key - KeyboardKey.KEY_A));
                    } else {
                        c = cast(char)('a' + (key - KeyboardKey.KEY_A));
                    }
                    currentInputName ~= c;
                    PlaySound(dialogTypeSound);
                    }
                    // Numbers 0-9
                    else if (key >= KeyboardKey.KEY_ZERO && key <= KeyboardKey.KEY_NINE) {
                    char c = cast(char)('0' + (key - KeyboardKey.KEY_ZERO));
                    currentInputName ~= c;
                    PlaySound(dialogTypeSound);
                    }
                    // Space
                    else if (key == KeyboardKey.KEY_SPACE) {
                    currentInputName ~= ' ';
                    PlaySound(dialogTypeSound);
                    }
                }
                }
            }
            break;

            case NameEntryState.CONFIRMED:
                nameEntryActive = false; // Dialog is no longer active
                break;

            case NameEntryState.CANCELLED:
                nameEntryActive = false; // Dialog is no longer active
                break;
            default:
                break;
        }
    }

    void draw() {
        if (!nameEntryActive && nameEntryState != NameEntryState.ACTIVE) { // Only draw if active
             // If we want a fade out effect, it could be handled here based on state
            // For now, if not active, don't draw.
            // return; 
        }

        // Draw the name entry popup
        DrawTexturePro(dialogBoxTexture, Rectangle(0, 0, dialogBoxTexture.width, dialogBoxTexture.height), 
            Rectangle(dialogBoxPosition.x, dialogBoxPosition.y, dialogBoxSize.x * dialogBoxScale, dialogBoxSize.y * dialogBoxScale), 
            Vector2(0, 0), 0.0f, ColorAlpha(Colors.WHITE, dialogBoxAlphaValue));
        DrawTexturePro(dialogBoxAlpha, Rectangle(0, 0, dialogBoxAlpha.width, dialogBoxAlpha.height),
            Rectangle(dialogBoxPosition.x, dialogBoxPosition.y, dialogBoxSize.x * dialogBoxScale, dialogBoxSize.y * dialogBoxScale), 
            Vector2(0, 0), 0.0f, ColorAlpha(Colors.WHITE, dialogBoxAlphaValue));
        DrawTexturePro(dialogTitleTexture, Rectangle(0, 0, dialogTitleTexture.width, dialogTitleTexture.height),
            Rectangle(dialogTitlePosition.x - dialogTitleTexture.width / 2, dialogTitlePosition.y, dialogTitleTexture.width * dialogTitleScale, dialogTitleTexture.height * dialogTitleScale), 
            Vector2(dialogTitleTexture.width / 2, 0), 0.0f, ColorAlpha(Colors.WHITE, dialogTitleAlphaValue));
        DrawTexturePro(dialogTitleAlpha, Rectangle(0, 0, dialogTitleAlpha.width, dialogTitleAlpha.height),
            Rectangle(dialogTitlePosition.x - dialogTitleAlpha.width / 2, dialogTitlePosition.y, dialogTitleAlpha.width * dialogTitleScale, dialogTitleAlpha.height * dialogTitleScale), 
            Vector2(dialogTitleAlpha.width / 2, 0), 0.0f, ColorAlpha(Colors.WHITE, dialogTitleAlphaValue));
        DrawTexturePro(editBoxTexture, Rectangle(0, 0, editBoxTexture.width, editBoxTexture.height),
            Rectangle(editBoxPosition.x, editBoxPosition.y, editBoxSize.x * editBoxScale, editBoxSize.y * editBoxScale), 
            Vector2(0, 0), 0.0f, ColorAlpha(Colors.WHITE, editBoxAlphaValue));
        

        float greetingFontSize = 28.0f;
        float promptFontSize = 22.0f;
        float nameFontSize = 22.0f;
        Color textColor = Colors.WHITE; // Text is white in the screenshot
        Font textFont = app.fontFamily[0]; // Using a default game font, adjust if needed

        // Greeting Text
        Vector2 greetingTextSize = MeasureTextEx(textFont, greeting.toStringz(), greetingFontSize, 1.0f);
        float greetingX = (VIRTUAL_SCREEN_WIDTH - greetingTextSize.x) / 2.0f;
        float greetingY = VIRTUAL_SCREEN_HEIGHT / 2.0f - greetingTextSize.y - promptFontSize - 10; // Position above prompt
        DrawTextEx(textFont, greeting.toStringz(), Vector2(greetingX, greetingY), greetingFontSize, 1.0f, textColor);

        // Prompt Text
        Vector2 promptTextSize = MeasureTextEx(textFont, nameEntryPrompt.toStringz(), promptFontSize, 1.0f);
        float promptX = (VIRTUAL_SCREEN_WIDTH - promptTextSize.x) / 2.0f;
        float promptY = VIRTUAL_SCREEN_HEIGHT / 2.0f - promptTextSize.y / 2.0f; // Center vertically
        DrawTextEx(textFont, nameEntryPrompt.toStringz(), Vector2(promptX, promptY), promptFontSize, 1.0f, textColor);
        
        // Player Name Text (acting as the input field display)
        string displayPlayerName = currentInputName;
        // Add a blinking cursor or underscore for visual feedback
        // For simplicity, just display the name for now. A cursor would require a timer.
        // if (nameEntryState == NameEntryState.ACTIVE && cast(int)(GetTime() * 2.0f) % 2 == 0) { // Blinking cursor
        //    displayPlayerName ~= "_";
        // }

        Vector2 playerNameTextSize = MeasureTextEx(textFont, displayPlayerName.toStringz(), nameFontSize, 1.0f);
        float playerNameX = (VIRTUAL_SCREEN_WIDTH - playerNameTextSize.x) / 2.0f; // Centered
        float playerNameY = promptY + promptTextSize.y + 10; // Position below prompt
        DrawTextEx(textFont, displayPlayerName.toStringz(), Vector2(playerNameX, playerNameY), nameFontSize, 1.0f, textColor);

    }

    override void unload() {
        // Unload textures and sounds
        UnloadTexture(dialogBoxTexture);
        UnloadTexture(dialogBoxAlpha);
        UnloadTexture(dialogButtonTexture);
        UnloadTexture(dialogButtonAlpha);
        UnloadTexture(dialogButtonHover);
        UnloadTexture(dialogButtonHoverAlpha);
        UnloadTexture(dialogTitleTexture);
        UnloadTexture(dialogTitleAlpha);
        UnloadTexture(editBoxTexture);

        UnloadSound(dialogOpenSound);
        UnloadSound(dialogCloseSound);
        UnloadSound(dialogButtonHoverSound);
        UnloadSound(dialogButtonClickSound);
        UnloadSound(dialogTypeSound);

        // Reset name entry variables
        currentInputName = ""; // Changed from playerName
        nameEntryActive = false;
        nameEntryConfirmed = false;
        nameEntryCancelled = false;
    }
}