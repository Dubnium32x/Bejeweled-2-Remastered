module screens.popups.quit_dialog;

import raylib;

import std.stdio;
import std.string;
import std.conv;

import world.screen_manager;
import world.screen_states;
import world.memory_manager;
import world.audio_manager;
import data;
import app;
import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, GetMousePositionVirtual, fontFamily;

enum QuitDialogState {
    ACTIVE,
    CONFIRMED,
    CANCELLED,
    DONE
}

class QuitDialog {
    private MemoryManager memoryManager;
    private AudioManager audioManager;
    
    // Dialog textures
    private Texture2D dialogBoxTexture;
    private Texture2D dialogButtonTexture;
    private Texture2D dialogButtonHoverTexture;
    private Texture2D dialogBoxAlphaMask;
    private Texture2D dialogButtonAlpha;
    private Texture2D dialogButtonHoverAlpha;
    
    // Dialog state
    private QuitDialogState dialogState = QuitDialogState.ACTIVE;
    private bool isActive = false;
    
    // Layout variables
    private Vector2 dialogBoxPosition;
    private Rectangle yesButtonRect;
    private Rectangle noButtonRect;
    private bool yesButtonHovered = false;
    private bool noButtonHovered = false;
    
    // Animation variables
    private float dialogBoxScale = 0.0f;
    private float dialogBoxAlpha = 0.0f;
    private float animationSpeed = 3.0f;
    
    // Text content
    private string quitMessage = "Are you sure you want to quit?";
    private string goodbyeMessage = "Goodbye.";
    private bool showingGoodbye = false;
    private float goodbyeTimer = 0.0f;
    private float goodbyeDisplayTime = 2.0f;
    private bool userConfirmedQuit = false; // Track if user actually confirmed quit
    
    public this() {
        memoryManager = MemoryManager.instance();
        audioManager = AudioManager.getInstance();
        initialize();
    }
    
    void initialize() {
        // Calculate dialog position (center of screen)
        dialogBoxPosition = Vector2(
            VIRTUAL_SCREEN_WIDTH / 2.0f,
            VIRTUAL_SCREEN_HEIGHT / 2.0f
        );
        
        // Load textures if available, otherwise use fallback rectangles
        try {
            dialogBoxTexture = memoryManager.loadTexture("resources/image/DIALOGBOX.png");
            SetTextureFilter(dialogBoxTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
            dialogBoxAlphaMask = memoryManager.loadTexture("resources/image/DIALOGBOX_.png");
            SetTextureFilter(dialogBoxAlphaMask, TextureFilter.TEXTURE_FILTER_BILINEAR);
        } catch (Exception e) {
            writeln("Could not load dialog box texture: ", e.msg);
        }
        
        try {
            dialogButtonTexture = memoryManager.loadTexture("resources/image/DialogButton.png");
            SetTextureFilter(dialogButtonTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
            dialogButtonAlpha = memoryManager.loadTexture("resources/image/DialogButton_.png");
            SetTextureFilter(dialogButtonAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
            dialogButtonHoverTexture = memoryManager.loadTexture("resources/image/DialogButtonglow.png");
            SetTextureFilter(dialogButtonHoverTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
            dialogButtonHoverAlpha = memoryManager.loadTexture("resources/image/DialogButtonglow_.png");
            SetTextureFilter(dialogButtonHoverAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        } catch (Exception e) {
            writeln("Could not load dialog button textures: ", e.msg);
        }
        
        // Set up button rectangles
        updateButtonRects();
        
        writeln("QuitDialog initialized");

        // Apply alpha masks if available
        if (dialogBoxAlphaMask.id != 0) {
            Image dialogBoxImage = LoadImageFromTexture(dialogBoxTexture);
            ImageAlphaMask(&dialogBoxImage, LoadImageFromTexture(dialogBoxAlphaMask));
            dialogBoxTexture = LoadTextureFromImage(dialogBoxImage);
            SetTextureFilter(dialogBoxTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        }
        if (dialogButtonAlpha.id != 0) {
            Image buttonImage = LoadImageFromTexture(dialogButtonTexture);
            ImageAlphaMask(&buttonImage, LoadImageFromTexture(dialogButtonAlpha));
            dialogButtonTexture = LoadTextureFromImage(buttonImage);
            SetTextureFilter(dialogButtonTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        }
        if (dialogButtonHoverAlpha.id != 0) {
            Image buttonHoverImage = LoadImageFromTexture(dialogButtonHoverTexture);
            ImageAlphaMask(&buttonHoverImage, LoadImageFromTexture(dialogButtonHoverAlpha));
            dialogButtonHoverTexture = LoadTextureFromImage(buttonHoverImage);
            SetTextureFilter(dialogButtonHoverTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        }
        // Ensure textures are properly unloaded when done

    }
    
    private void updateButtonRects() {
        float buttonWidth = 120.0f;
        float buttonHeight = 40.0f;
        float buttonSpacing = 40.0f;
        
        // Position buttons side by side below the message
        float buttonsY = dialogBoxPosition.y + 40.0f;
        float totalButtonsWidth = (buttonWidth * 2) + buttonSpacing;
        float buttonsStartX = dialogBoxPosition.x - (totalButtonsWidth / 2.0f);
        
        yesButtonRect = Rectangle(
            buttonsStartX,
            buttonsY,
            buttonWidth,
            buttonHeight
        );
        
        noButtonRect = Rectangle(
            buttonsStartX + buttonWidth + buttonSpacing,
            buttonsY,
            buttonWidth,
            buttonHeight
        );
    }
    
    public void show() {
        isActive = true;
        dialogState = QuitDialogState.ACTIVE;
        showingGoodbye = false;
        goodbyeTimer = 0.0f;
        
        // Reset animation
        dialogBoxScale = 0.0f;
        dialogBoxAlpha = 0.0f;
        
        // Play dialog open sound
        if (audioManager !is null) {
            audioManager.playSound("resources/audio/sfx/twist_notify.ogg", AudioType.SFX);
        }
        
        writeln("QuitDialog shown");
    }
    
    public void hide() {
        isActive = false;
        dialogState = QuitDialogState.CANCELLED;
        
        // Play dialog close sound
        if (audioManager !is null) {
            audioManager.playSound("resources/audio/sfx/menuclick.ogg", AudioType.SFX);
        }
        
        writeln("QuitDialog hidden");
    }
    
    public bool isDialogActive() {
        return isActive;
    }
    
    public bool isConfirmed() {
        return dialogState == QuitDialogState.CONFIRMED;
    }
    
    public bool isCancelled() {
        return dialogState == QuitDialogState.CANCELLED;
    }
    
    public bool isDone() {
        return dialogState == QuitDialogState.DONE;
    }
    
    void update(float deltaTime) {
        if (!isActive) return;
        
        // Update animations
        if (dialogBoxScale < 1.0f) {
            dialogBoxScale += animationSpeed * deltaTime;
            if (dialogBoxScale > 1.0f) dialogBoxScale = 1.0f;
        }
        
        if (dialogBoxAlpha < 1.0f) {
            dialogBoxAlpha += animationSpeed * deltaTime;
            if (dialogBoxAlpha > 1.0f) dialogBoxAlpha = 1.0f;
        }
        
        // Handle goodbye message timer
        if (showingGoodbye) {
            goodbyeTimer += deltaTime;
            if (goodbyeTimer >= goodbyeDisplayTime) {
                dialogState = QuitDialogState.DONE;
                isActive = false;
                return;
            }
        } else {
            // Handle input only if not showing goodbye
            Vector2 mousePos = GetMousePositionVirtual();
            
            // Update button hover states
            yesButtonHovered = CheckCollisionPointRec(mousePos, yesButtonRect);
            noButtonHovered = CheckCollisionPointRec(mousePos, noButtonRect);
            
            // Handle button clicks
            if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
                if (yesButtonHovered) {
                    // User confirmed quit
                    dialogState = QuitDialogState.CONFIRMED;
                    showingGoodbye = true;
                    goodbyeTimer = 0.0f;
                    
                    if (audioManager !is null) {
                        audioManager.playSound("resources/audio/sfx/menuclick.ogg", AudioType.SFX);
                        audioManager.playSound("resources/audio/vox/goodbye.ogg", AudioType.SFX);
                    }
                    
                    writeln("Quit confirmed - showing goodbye message");
                } else if (noButtonHovered) {
                    // User cancelled quit
                    hide();
                }
            }
            
            // Handle keyboard input
            if (IsKeyPressed(KeyboardKey.KEY_Y) || IsKeyPressed(KeyboardKey.KEY_ENTER)) {
                // Yes, quit
                dialogState = QuitDialogState.CONFIRMED;
                showingGoodbye = true;
                goodbyeTimer = 0.0f;
                
                if (audioManager !is null) {
                    audioManager.playSound("resources/audio/vox/goodbye.ogg", AudioType.SFX);
                }
                
                writeln("Quit confirmed via keyboard - showing goodbye message");
            } else if (IsKeyPressed(KeyboardKey.KEY_N)) {
                // No, cancel
                hide();
            }
        }
    }
    
    void draw() {
        if (!isActive) return;
        
        // Draw semi-transparent background overlay
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, Color(0, 0, 0, 150));
        
        // Calculate current dialog dimensions based on animation
        float dialogWidth = 400.0f * dialogBoxScale;
        float dialogHeight = 200.0f * dialogBoxScale;
        
        // Draw dialog box
        if (dialogBoxTexture.id != 0) {
            // Use loaded texture
            DrawTexturePro(
                dialogBoxTexture,
                Rectangle(0, 0, dialogBoxTexture.width, dialogBoxTexture.height),
                Rectangle(
                    dialogBoxPosition.x - dialogWidth / 2.0f,
                    dialogBoxPosition.y - dialogHeight / 2.0f,
                    dialogWidth,
                    dialogHeight
                ),
                Vector2(0, 0),
                0.0f,
                Color(255, 255, 255, cast(ubyte)(255 * dialogBoxAlpha))
            );
        } else {
            // Use fallback rectangle
            DrawRectangleRounded(
                Rectangle(
                    dialogBoxPosition.x - dialogWidth / 2.0f,
                    dialogBoxPosition.y - dialogHeight / 2.0f,
                    dialogWidth,
                    dialogHeight
                ),
                0.1f,
                10,
                Color(50, 50, 50, cast(ubyte)(200 * dialogBoxAlpha))
            );
            
            DrawRectangleRoundedLinesEx(
                Rectangle(
                    dialogBoxPosition.x - dialogWidth / 2.0f,
                    dialogBoxPosition.y - dialogHeight / 2.0f,
                    dialogWidth,
                    dialogHeight
                ),
                0.1f,
                10,
                2.0f,
                Color(100, 100, 100, cast(ubyte)(255 * dialogBoxAlpha))
            );
        }
        
        // Only draw content if dialog is fully scaled
        if (dialogBoxScale >= 0.8f) {
            if (showingGoodbye) {
                // Draw goodbye message
                float fontSize = 32.0f;
                Vector2 textSize = MeasureTextEx(fontFamily[0], goodbyeMessage.toStringz(), fontSize, 1.0f);
                Vector2 textPos = Vector2(
                    dialogBoxPosition.x - textSize.x / 2.0f,
                    dialogBoxPosition.y - textSize.y / 2.0f
                );
                
                DrawTextEx(
                    fontFamily[0],
                    goodbyeMessage.toStringz(),
                    textPos,
                    fontSize,
                    1.0f,
                    Colors.WHITE
                );
            } else {
                // Draw quit confirmation message
                float fontSize = 24.0f;
                Vector2 textSize = MeasureTextEx(fontFamily[0], quitMessage.toStringz(), fontSize, 1.0f);
                Vector2 textPos = Vector2(
                    dialogBoxPosition.x - textSize.x / 2.0f,
                    dialogBoxPosition.y - 30.0f
                );
                
                DrawTextEx(
                    fontFamily[0],
                    quitMessage.toStringz(),
                    textPos,
                    fontSize,
                    1.0f,
                    Colors.WHITE
                );
                
                // Draw buttons
                drawButton(yesButtonRect, "YES", yesButtonHovered);
                drawButton(noButtonRect, "NO", noButtonHovered);
                
                // Draw keyboard hints
                string hint = "Press Y for Yes, N for No";
                float hintFontSize = 14.0f;
                Vector2 hintSize = MeasureTextEx(fontFamily[2], hint.toStringz(), hintFontSize, 1.0f);
                Vector2 hintPos = Vector2(
                    dialogBoxPosition.x - hintSize.x / 2.0f,
                    dialogBoxPosition.y + 100.0f
                );
                
                DrawTextEx(
                    fontFamily[2],
                    hint.toStringz(),
                    hintPos,
                    hintFontSize,
                    1.0f,
                    Colors.LIGHTGRAY
                );
            }
        }
    }
    
    private void drawButton(Rectangle buttonRect, string text, bool isHovered) {
        Color buttonColor = isHovered ? Color(100, 150, 100, 255) : Color(70, 70, 70, 255);
        Color textColor = isHovered ? Colors.YELLOW : Colors.WHITE;
        
        if (dialogButtonTexture.id != 0) {
            // First draw the base button texture (always use the non-hover version as base)
            DrawTexturePro(
                dialogButtonTexture,
                Rectangle(0, 0, dialogButtonTexture.width, dialogButtonTexture.height),
                buttonRect,
                Vector2(0, 0),
                0.0f,
                Colors.WHITE
            );
            
            // If hovered, draw the glow texture with additive blending
            if (isHovered && dialogButtonHoverTexture.id != 0) {
                BeginBlendMode(BlendMode.BLEND_ADDITIVE);
                DrawTexturePro(
                    dialogButtonHoverTexture,
                    Rectangle(0, 0, dialogButtonHoverTexture.width, dialogButtonHoverTexture.height),
                    buttonRect,
                    Vector2(0, 0),
                    0.0f,
                    Colors.WHITE
                );
                EndBlendMode();
            }
        } else {
            // Use fallback rectangles
            DrawRectangleRounded(buttonRect, 0.2f, 6, buttonColor);
            DrawRectangleRoundedLinesEx(buttonRect, 0.2f, 6, 1.0f, Colors.GRAY);
        }
        
        // Draw button text
        float buttonFontSize = 20.0f;
        Vector2 textSize = MeasureTextEx(fontFamily[1], text.toStringz(), buttonFontSize, 1.0f);
        Vector2 textPos = Vector2(
            buttonRect.x + (buttonRect.width - textSize.x) / 2.0f,
            buttonRect.y + (buttonRect.height - textSize.y) / 2.0f
        );
        
        DrawTextEx(
            fontFamily[1],
            text.toStringz(),
            textPos,
            buttonFontSize,
            1.0f,
            textColor
        );
    }
    
    void unload() {
        // Resources are managed by MemoryManager, no manual cleanup needed
        writeln("QuitDialog unloaded");
    }
}
