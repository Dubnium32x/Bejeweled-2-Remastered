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
    private Texture2D toggleTexture;
    private Texture2D dialogBoxAlphaMask;
    private Texture2D toggleAlphaMask;
    
    // Dialog state
    private QuitDialogState dialogState = QuitDialogState.ACTIVE;
    private bool isActive = false;
    
    // Layout variables
    private Vector2 dialogBoxPosition;
    private Rectangle toggleRect;
    private Rectangle noSideRect;
    private Rectangle yesSideRect;
    private bool noSideHovered = false;
    private bool yesSideHovered = false;
    
    // Keyboard navigation
    private int selectedOption = 0; // 0 = No, 1 = Yes
    
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
            toggleTexture = memoryManager.loadTexture("resources/image/Toggle.png");
            SetTextureFilter(toggleTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
            toggleAlphaMask = memoryManager.loadTexture("resources/image/Toggle_.png");
            SetTextureFilter(toggleAlphaMask, TextureFilter.TEXTURE_FILTER_BILINEAR);
        } catch (Exception e) {
            writeln("Could not load toggle texture: ", e.msg);
        }
        
        // Set up button rectangles
        updateButtonRects();

        // Apply texture filtering to fonts for better quality
        foreach (font; fontFamily) {
            if (font.texture.id > 0) {
                SetTextureFilter(font.texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
            }
        }
        
        writeln("QuitDialog initialized");

        // Apply alpha masks if available
        if (dialogBoxAlphaMask.id != 0) {
            Image dialogBoxImage = LoadImageFromTexture(dialogBoxTexture);
            ImageAlphaMask(&dialogBoxImage, LoadImageFromTexture(dialogBoxAlphaMask));
            dialogBoxTexture = LoadTextureFromImage(dialogBoxImage);
            SetTextureFilter(dialogBoxTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        }
        if (toggleAlphaMask.id != 0) {
            Image toggleImage = LoadImageFromTexture(toggleTexture);
            ImageAlphaMask(&toggleImage, LoadImageFromTexture(toggleAlphaMask));
            toggleTexture = LoadTextureFromImage(toggleImage);
            SetTextureFilter(toggleTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        }
        // Ensure textures are properly unloaded when done

    }
    
    private void updateButtonRects() {
        // Position toggle below the message
        float toggleY = dialogBoxPosition.y + 40.0f;
        
        // Use the actual toggle texture dimensions if available, otherwise fallback
        float toggleWidth = (toggleTexture.id != 0) ? toggleTexture.width : 200.0f;
        float toggleHeight = (toggleTexture.id != 0) ? toggleTexture.height : 60.0f;
        
        // Center the toggle horizontally
        float toggleX = dialogBoxPosition.x - (toggleWidth / 2.0f);
        
        toggleRect = Rectangle(
            toggleX,
            toggleY,
            toggleWidth,
            toggleHeight
        );
        
        // Split the toggle into two clickable halves
        // Left half = NO, Right half = YES
        noSideRect = Rectangle(
            toggleX,
            toggleY,
            toggleWidth / 2.0f,
            toggleHeight
        );
        
        yesSideRect = Rectangle(
            toggleX + (toggleWidth / 2.0f),
            toggleY,
            toggleWidth / 2.0f,
            toggleHeight
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
        
        // Reset selection to "No" (safer default)
        selectedOption = 0;
        
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
            
            // Update hover states for toggle sides
            bool mouseOnNo = CheckCollisionPointRec(mousePos, noSideRect);
            bool mouseOnYes = CheckCollisionPointRec(mousePos, yesSideRect);
            
            // Update selection based on mouse position, but maintain keyboard selection otherwise
            if (mouseOnNo) {
                selectedOption = 0;
                noSideHovered = true;
                yesSideHovered = false;
            } else if (mouseOnYes) {
                selectedOption = 1;
                noSideHovered = false;
                yesSideHovered = true;
            } else {
                // No mouse hover, use keyboard selection to set hover states
                noSideHovered = (selectedOption == 0);
                yesSideHovered = (selectedOption == 1);
            }
            
            // Handle button clicks
            if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
                if (yesSideHovered) {
                    // User confirmed quit (clicked YES side)
                    dialogState = QuitDialogState.CONFIRMED;
                    showingGoodbye = true;
                    goodbyeTimer = 0.0f;
                    
                    if (audioManager !is null) {
                        audioManager.playSound("resources/audio/sfx/menuclick.ogg", AudioType.SFX);
                        audioManager.playSound("resources/audio/vox/goodbye.ogg", AudioType.SFX);
                    }
                    
                    writeln("Quit confirmed - showing goodbye message");
                } else if (noSideHovered) {
                    // User cancelled quit (clicked NO side)
                    hide();
                }
            }
            
            // Handle keyboard navigation
            // Left/Right or A/D to navigate between No and Yes
            if (IsKeyPressed(KeyboardKey.KEY_LEFT) || IsKeyPressed(KeyboardKey.KEY_A)) {
                selectedOption = 0; // Select "No"
                if (audioManager !is null) {
                    audioManager.playSound("resources/audio/sfx/mainmenu_mouseover.ogg", AudioType.SFX);
                }
            } else if (IsKeyPressed(KeyboardKey.KEY_RIGHT) || IsKeyPressed(KeyboardKey.KEY_D)) {
                selectedOption = 1; // Select "Yes"
                if (audioManager !is null) {
                    audioManager.playSound("resources/audio/sfx/mainmenu_mouseover.ogg", AudioType.SFX);
                }
            }
            
            // Enter to confirm current selection
            if (IsKeyPressed(KeyboardKey.KEY_ENTER)) {
                if (selectedOption == 1) {
                    // Yes selected - quit
                    dialogState = QuitDialogState.CONFIRMED;
                    showingGoodbye = true;
                    goodbyeTimer = 0.0f;
                    
                    if (audioManager !is null) {
                        audioManager.playSound("resources/audio/sfx/menuclick.ogg", AudioType.SFX);
                        audioManager.playSound("resources/audio/vox/goodbye.ogg", AudioType.SFX);
                    }
                    
                    writeln("Quit confirmed via Enter - showing goodbye message");
                } else {
                    // No selected - cancel
                    hide();
                }
            }
            
            // Escape to cancel (go back)
            if (IsKeyPressed(KeyboardKey.KEY_ESCAPE)) {
                hide();
            }
            
            // Legacy direct keys for quick access (optional)
            if (IsKeyPressed(KeyboardKey.KEY_Y)) {
                selectedOption = 1; // Auto-select Yes
                dialogState = QuitDialogState.CONFIRMED;
                showingGoodbye = true;
                goodbyeTimer = 0.0f;
                
                if (audioManager !is null) {
                    audioManager.playSound("resources/audio/sfx/menuclick.ogg", AudioType.SFX);
                    audioManager.playSound("resources/audio/vox/goodbye.ogg", AudioType.SFX);
                }
                
                writeln("Quit confirmed via Y key - showing goodbye message");
            } else if (IsKeyPressed(KeyboardKey.KEY_N)) {
                selectedOption = 0; // Auto-select No
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
                
                // Draw toggle
                drawToggle();
                
                // Draw keyboard hints
                string hint = "Left/Right or A/D to navigate, Enter to confirm, ESC to cancel";
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
    
    private void drawToggle() {
        if (toggleTexture.id != 0) {
            // Draw the toggle texture
            DrawTexturePro(
                toggleTexture,
                Rectangle(0, 0, toggleTexture.width, toggleTexture.height),
                toggleRect,
                Vector2(0, 0),
                0.0f,
                Colors.WHITE
            );
            
            // Add highlight effects for hover states using additive blending
            if (noSideHovered || yesSideHovered) {
                BeginBlendMode(BlendMode.BLEND_ADDITIVE);
                
                Color highlightColor;
                Rectangle highlightRect;
                
                if (noSideHovered) {
                    // Soft red highlight for NO side
                    highlightColor = Color(150, 50, 50, 80);
                    highlightRect = Rectangle(
                        noSideRect.x + 4,
                        noSideRect.y + 4,
                        noSideRect.width - 8,
                        noSideRect.height - 8
                    );
                } else if (yesSideHovered) {
                    // Soft green highlight for YES side
                    highlightColor = Color(50, 150, 50, 80);
                    highlightRect = Rectangle(
                        yesSideRect.x + 4,
                        yesSideRect.y + 4,
                        yesSideRect.width - 8,
                        yesSideRect.height - 8
                    );
                }
                
                DrawRectangleRounded(highlightRect, 0.3f, 8, highlightColor);
                EndBlendMode();
            }
            
            // Draw "No" and "Yes" text labels over the toggle
            float textSize = 24.0f;
            
            // "No" text (left side)
            string noText = "No";
            Vector2 noTextMeasure = MeasureTextEx(fontFamily[1], noText.toStringz(), textSize, 1.0f);
            Vector2 noTextPos = Vector2(
                noSideRect.x + (noSideRect.width - noTextMeasure.x) / 2.0f,
                noSideRect.y + (noSideRect.height - noTextMeasure.y) / 2.0f
            );
            
            // Color changes based on hover
            Color noTextColor = noSideHovered ? Color(255, 200, 200, 255) : Color(220, 220, 220, 255);
            
            // Draw text shadow first
            DrawTextEx(fontFamily[1], noText.toStringz(), 
                      Vector2(noTextPos.x + 2, noTextPos.y + 2), textSize, 1.0f, 
                      Color(0, 0, 0, 180));
            
            // Draw main text
            DrawTextEx(fontFamily[1], noText.toStringz(), noTextPos, textSize, 1.0f, noTextColor);
            
            // "Yes" text (right side)
            string yesText = "Yes";
            Vector2 yesTextMeasure = MeasureTextEx(fontFamily[1], yesText.toStringz(), textSize, 1.0f);
            Vector2 yesTextPos = Vector2(
                yesSideRect.x + (yesSideRect.width - yesTextMeasure.x) / 2.0f,
                yesSideRect.y + (yesSideRect.height - yesTextMeasure.y) / 2.0f
            );
            
            // Color changes based on hover
            Color yesTextColor = yesSideHovered ? Color(200, 255, 200, 255) : Color(220, 220, 220, 255);
            
            // Draw text shadow first
            DrawTextEx(fontFamily[1], yesText.toStringz(), 
                      Vector2(yesTextPos.x + 2, yesTextPos.y + 2), textSize, 1.0f, 
                      Color(0, 0, 0, 180));
            
            // Draw main text
            DrawTextEx(fontFamily[1], yesText.toStringz(), yesTextPos, textSize, 1.0f, yesTextColor);
            
        } else {
            // Fallback: draw two separate rectangles for NO and YES
            Color noColor = noSideHovered ? Color(180, 100, 100, 255) : Color(120, 120, 120, 255);
            Color yesColor = yesSideHovered ? Color(100, 180, 100, 255) : Color(120, 120, 120, 255);
            
            DrawRectangleRounded(noSideRect, 0.1f, 6, noColor);
            DrawRectangleRounded(yesSideRect, 0.1f, 6, yesColor);
            
            // Draw border
            DrawRectangleRoundedLinesEx(toggleRect, 0.1f, 6, 2.0f, Colors.GRAY);
            
            // Draw text labels for fallback
            float fontSize = 20.0f;
            
            // NO text
            Vector2 noTextSize = MeasureTextEx(fontFamily[1], "NO".toStringz(), fontSize, 1.0f);
            Vector2 noTextPos = Vector2(
                noSideRect.x + (noSideRect.width - noTextSize.x) / 2.0f,
                noSideRect.y + (noSideRect.height - noTextSize.y) / 2.0f
            );
            DrawTextEx(fontFamily[1], "NO".toStringz(), noTextPos, fontSize, 1.0f, Colors.WHITE);
            
            // YES text  
            Vector2 yesTextSize = MeasureTextEx(fontFamily[1], "YES".toStringz(), fontSize, 1.0f);
            Vector2 yesTextPos = Vector2(
                yesSideRect.x + (yesSideRect.width - yesTextSize.x) / 2.0f,
                yesSideRect.y + (yesSideRect.height - yesTextSize.y) / 2.0f
            );
            DrawTextEx(fontFamily[1], "YES".toStringz(), yesTextPos, fontSize, 1.0f, Colors.WHITE);
        }
    }
    
    void unload() {
        // Resources are managed by MemoryManager, no manual cleanup needed
        writeln("QuitDialog unloaded");
    }
}
