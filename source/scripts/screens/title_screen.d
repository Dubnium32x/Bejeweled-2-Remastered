module screens.title_screen;

import raylib;

import std.stdio;
import std.file;
import std.path;
import std.string : toStringz;

import world.screen_manager;
import world.memory_manager; // Added import
import world.audio_manager; // Added import
import world.screen_states; // Added import

// ---- LOCAL VARIABLES ----
// Textures (will be loaded by MemoryManager)
Texture titleLogoTexture;
Texture titleLogo2Texture;
Texture clickHereTexture;
Texture clickHereOverTexture;
Texture currentClickTexture; // To hold the current texture for the click bar
Texture backgroundTexture; // Added for the background

// ---- ENUMS ----
enum TitleScreenState {
    UNINITIALIZED,
    INITIALIZING,
    FADING_IN,       // Initial fade from black
    LOGO_FLYING_IN,  // Main logo animation
    LOGO2_FADING_IN, // "2" logo animation
    LOADER_FADING_IN,// "Click here" bar animation
    ACTIVE,          // Waiting for user input
    FADING_OUT       // Transitioning to next screen
}

// ---- CLASS ----
class TitleScreen : IScreen {
    // Singleton instance
    private __gshared TitleScreen instance; // Made private and __gshared as per previous convention

    // Managers
    private MemoryManager memoryManager;
    private AudioManager audioManager;

    // Current state of the title screen
    TitleScreenState state;

    // Resources to preload
    private string[] texturesToPreload;
    private string[] soundsToPreload;
    private string[] musicToPreload;

    // Animation Timers & Durations (in seconds)
    private float fadeInTimer = 0.0f;
    private const float fadeInDuration = 1.0f;

    private float logoFlyInTimer = 0.0f;
    private const float logoFlyInDuration = 0.75f;

    private float logo2FadeInTimer = 0.0f;
    private const float logo2FadeInDuration = 0.5f;

    private float loaderFadeInTimer = 0.0f;
    private const float loaderFadeInDuration = 0.5f;

    // Animation Properties
    private float currentAlpha = 0.0f; // General alpha for fades
    private Vector2 titleLogoPos;
    private float titleLogoStartY;
    private float titleLogoEndY;

    private float logo2Alpha = 0.0f;
    private float loaderAlpha = 0.0f;

    // Interaction
    private Rectangle clickHereBounds;
    private bool isMouseOverClickHere = false;

    this() {
        instance = this;
        state = TitleScreenState.UNINITIALIZED;
        memoryManager = MemoryManager.instance(); // Get instance
        audioManager = AudioManager.getInstance(); // Get instance

        // Define the resources to preload
        texturesToPreload = [
            "resources/image/title_logo.png",
            // "resources/image/title_logo_.png", // alpha - Handled manually
            "resources/image/title_logo2.png",
            // "resources/image/title_logo2_.png", // alpha - Handled manually
            "resources/image/title_loaderbar_clickhere.png",
            "resources/image/title_loaderbar_clickhere_over.png",
            // "resources/image/title_loaderbarlit_.png", // alpha - Handled manually
            "resources/image/placeholder_1.png", // Added background
        ];

        soundsToPreload = [
            "resources/audio/sfx/select.ogg",
            "resources/audio/sfx/mainmenu_mouseclick.ogg"
        ];
        
        musicToPreload = [
            "resources/audio/music/arranged/Main Theme Bejeweled 2.ogg",
            // "resources/audio/music/arranged/Autonomous.ogg" // Removed unless needed for title
        ];
    }
    static TitleScreen getInstance() {
        if (instance is null) {
            synchronized {
                if (instance is null) {
                    instance = new TitleScreen();
                }
            }
        }
        return instance;
    }   

    // Initialize the title screen
    void initialize() {
        if (state != TitleScreenState.UNINITIALIZED) {
            writeln("TitleScreen already initialized or initializing.");
            return;
        }
        state = TitleScreenState.INITIALIZING;
        writeln("Initializing TitleScreen...");

        // --- Apply Alpha Masks ---
        // Helper function to load, mask, and update texture
        Texture applyAlphaMask(string texturePath, string alphaPath) {
            Texture baseTex = memoryManager.loadTexture(texturePath);
            if (baseTex.id == 0) {
                writeln("Warning: Base texture not found: ", texturePath);
                return baseTex; // Return unloaded texture
            }
            if (!exists(alphaPath)) {
                 writeln("Warning: Alpha mask not found: ", alphaPath);
                 return baseTex; // Return original texture if no mask
            }

            Image baseImage = LoadImageFromTexture(baseTex);
            Image alphaImage = LoadImage(alphaPath.toStringz());

            if (alphaImage.data !is null) {
                // Ensure dimensions match (optional but good practice)
                if (baseImage.width == alphaImage.width && baseImage.height == alphaImage.height) {
                    ImageAlphaMask(&baseImage, alphaImage);
                    // Unload the old texture before loading the new one from the modified image
                    // Update the local Texture variable instead of trying to replace it in the manager.
                    UnloadTexture(baseTex); // Unload the texture loaded by manager initially
                    baseTex = LoadTextureFromImage(baseImage); // Load new texture from masked image
                    writeln("Applied alpha mask: ", alphaPath);

                } else {
                    writeln("Warning: Dimension mismatch between texture and alpha mask: ", texturePath, " and ", alphaPath);
                }
                UnloadImage(alphaImage); // Unload alpha mask image
            } else {
                 writeln("Warning: Failed to load alpha mask image: ", alphaPath);
            }
            UnloadImage(baseImage); // Unload base image
            return baseTex; // Return the (potentially new) texture
        }

        // Load essential textures and apply masks
        titleLogoTexture = applyAlphaMask("resources/image/title_logo.png", "resources/image/title_logo_.png");
        titleLogo2Texture = applyAlphaMask("resources/image/title_logo2.png", "resources/image/title_logo2_.png");

        // Load other textures normally, applying alpha mask to loader bar
        clickHereTexture = applyAlphaMask("resources/image/title_loaderbar_clickhere.png", "resources/image/title_loaderbarlit_.png");
        clickHereOverTexture = applyAlphaMask("resources/image/title_loaderbar_clickhere_over.png", "resources/image/title_loaderbarlit_.png");
        backgroundTexture = memoryManager.loadTexture("resources/image/placeholder_1.png"); // Load background
        currentClickTexture = clickHereTexture; // Start with normal texture

        // Preload other resources (alpha maps removed from list in previous step)
        preloadResources(); 

        // Setup animation start/end values
        titleLogoEndY = 100; // Target Y position for the main logo
        titleLogoStartY = GetScreenHeight(); // Start off-screen below
        // Ensure texture width is valid before calculating position
        if (titleLogoTexture.id != 0) {
             titleLogoPos = Vector2( (GetScreenWidth() - titleLogoTexture.width) / 2.0f, titleLogoStartY );
        } else {
             titleLogoPos = Vector2( GetScreenWidth() / 2.0f, titleLogoStartY ); // Fallback position
             writeln("Warning: titleLogoTexture invalid, using fallback position.");
        }


        // Calculate bounds for the click bar (adjust Y as needed)
        if (clickHereTexture.id != 0) {
            float clickBarX = (GetScreenWidth() - clickHereTexture.width) / 2.0f;
            float clickBarY = GetScreenHeight() * 0.75f; // Example position
            clickHereBounds = Rectangle(clickBarX, clickBarY, clickHereTexture.width, clickHereTexture.height);
        } else {
             clickHereBounds = Rectangle(0, 0, 0, 0); // Fallback bounds
             writeln("Warning: clickHereTexture invalid, using fallback bounds.");
        }


        // Reset timers and alphas
        fadeInTimer = 0.0f;
        logoFlyInTimer = 0.0f;
        logo2FadeInTimer = 0.0f;
        loaderFadeInTimer = 0.0f;
        currentAlpha = 0.0f;
        logo2Alpha = 0.0f;
        loaderAlpha = 0.0f;
        isMouseOverClickHere = false;

        // Start the fade in
        state = TitleScreenState.FADING_IN;
        writeln("TitleScreen initialized. Starting fade in.");
    }

    private void preloadResources() {
        writeln("Starting TitleScreen resource preloading...");
        
        // Preload textures
        foreach(texturePath; texturesToPreload) {
             if (exists(texturePath)) {
                 memoryManager.loadTexture(texturePath); // Load and cache
             } else {
                 writeln("Warning: TitleScreen texture not found: ", texturePath);
             }
        }
        
        // Preload sounds
        foreach(soundPath; soundsToPreload) {
            if (exists(soundPath)) {
                // Load sound into memory (AudioManager might handle this differently, adjust if needed)
                // For Raylib, loading sounds might happen on first play, but pre-caching is good.
                // Wave wave = LoadWave(soundPath.toStringz()); // Example if direct loading needed
                // UnloadWave(wave); 
                // Or use AudioManager's potential preload mechanism
                audioManager.playSFX(soundPath, 0.0f); // Load with volume 0
            } else {
                writeln("Warning: TitleScreen sound not found: ", soundPath);
            }
        }
        
        // Preload music (already handled by InitScreen, but good practice)
        foreach(musicPath; musicToPreload) {
            if (exists(musicPath)) {
                // audioManager.playMusic(musicPath, 0.0f, false); // Load with volume 0, don't play
            } else {
                writeln("Warning: TitleScreen music not found: ", musicPath);
            }
        }
        
        writeln("TitleScreen resource preloading complete");
    }

    void update(float deltaTime) {
        if (state == TitleScreenState.UNINITIALIZED || state == TitleScreenState.INITIALIZING) return;

        Vector2 mousePos = GetMousePosition();

        // Update based on state
        final switch (state) {
            case TitleScreenState.FADING_IN:
                fadeInTimer += deltaTime;
                currentAlpha = fadeInTimer / fadeInDuration;
                if (currentAlpha > 1.0f) currentAlpha = 1.0f;
                
                if (fadeInTimer >= fadeInDuration) {
                    state = TitleScreenState.LOGO_FLYING_IN;
                    fadeInTimer = 0.0f; // Reset timer for potential reuse
                    writeln("TitleScreen: Fade in complete. Starting logo fly-in.");
                }
                break;

            case TitleScreenState.LOGO_FLYING_IN:
                logoFlyInTimer += deltaTime;
                float flyInRatio = logoFlyInTimer / logoFlyInDuration;
                if (flyInRatio > 1.0f) flyInRatio = 1.0f;

                // Use Lerp for smooth movement
                titleLogoPos.y = Lerp(titleLogoStartY, titleLogoEndY, flyInRatio);

                if (logoFlyInTimer >= logoFlyInDuration) {
                    titleLogoPos.y = titleLogoEndY; // Ensure it ends exactly at the target
                    state = TitleScreenState.LOGO2_FADING_IN;
                    logoFlyInTimer = 0.0f;
                    writeln("TitleScreen: Logo fly-in complete. Starting logo 2 fade-in.");
                }
                break;

            case TitleScreenState.LOGO2_FADING_IN:
                logo2FadeInTimer += deltaTime;
                logo2Alpha = logo2FadeInTimer / logo2FadeInDuration;
                if (logo2Alpha > 1.0f) logo2Alpha = 1.0f;

                if (logo2FadeInTimer >= logo2FadeInDuration) {
                    state = TitleScreenState.LOADER_FADING_IN;
                    logo2FadeInTimer = 0.0f;
                    writeln("TitleScreen: Logo 2 fade-in complete. Starting loader fade-in.");
                }
                break;

            case TitleScreenState.LOADER_FADING_IN:
                loaderFadeInTimer += deltaTime;
                loaderAlpha = loaderFadeInTimer / loaderFadeInDuration;
                if (loaderAlpha > 1.0f) loaderAlpha = 1.0f;

                if (loaderFadeInTimer >= loaderFadeInDuration) {
                    state = TitleScreenState.ACTIVE;
                    loaderFadeInTimer = 0.0f;
                    writeln("TitleScreen: Loader fade-in complete. Active.");
                }
                break;

            case TitleScreenState.ACTIVE:
                // Check for mouse hover over the click bar
                isMouseOverClickHere = CheckCollisionPointRec(mousePos, clickHereBounds);

                if (isMouseOverClickHere) {
                    currentClickTexture = clickHereOverTexture;
                    // Optionally play a hover sound (if desired and available)
                    // if (!wasMouseOverClickHereLastFrame) audioManager.playSFX("resources/audio/sfx/button_hover.ogg"); 
                } else {
                    currentClickTexture = clickHereTexture;
                }

                // Check for click
                if (isMouseOverClickHere && IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) { // Corrected enum member
                    writeln("TitleScreen: Clicked 'Click Here to Play'. Transitioning...");
                    audioManager.playSFX("resources/audio/sfx/mainmenu_mouseclick.ogg");
                    // TODO: Transition to the actual main menu screen state
                    // For now, let's just fade out or go back to init for testing
                    // state = TitleScreenState.FADING_OUT; 
                    ScreenManager.instance.changeState(ScreenState.INIT); // Changed instance() to instance
                }
                break;

            case TitleScreenState.FADING_OUT:
                // Implement fade-out logic if needed before changing screen
                // Example: currentAlpha -= deltaTime / fadeOutDuration;
                // if (currentAlpha <= 0) { ... change screen ... }
                break;
            
            case TitleScreenState.UNINITIALIZED:
            case TitleScreenState.INITIALIZING:
                break; // Should not happen due to check at start
        }
    }

    void draw() {
        if (state == TitleScreenState.UNINITIALIZED || state == TitleScreenState.INITIALIZING) return;

        // Always clear background first (optional if background covers everything)
        // ClearBackground(Colors.BLACK);

        // Draw background element
        if (backgroundTexture.id != 0) {
            DrawTexture(backgroundTexture, 0, 0, Colors.WHITE);
        } else {
            ClearBackground(Colors.BLACK); // Fallback if background not loaded
        }

        // Draw main logo - visible after initial fade, moves during fly-in
        if (state >= TitleScreenState.LOGO_FLYING_IN && titleLogoTexture.id != 0) {
             DrawTextureV(titleLogoTexture, titleLogoPos, Colors.WHITE);
        }

        // Draw "2" logo - fades in after main logo arrives
        if (state >= TitleScreenState.LOGO2_FADING_IN && titleLogo2Texture.id != 0 && titleLogoTexture.id != 0) {
            // Calculate position relative to the main logo (centered horizontally, slightly below)
            float logo2PosX = titleLogoPos.x + (titleLogoTexture.width / 2.0f) - (titleLogo2Texture.width / 2.0f);
            float logo2PosY = titleLogoPos.y + titleLogoTexture.height - 40; // Adjust Y offset as needed
            Vector2 logo2Pos = Vector2(logo2PosX, logo2PosY); 
            DrawTextureV(titleLogo2Texture, logo2Pos, ColorAlpha(Colors.WHITE, logo2Alpha));
        }

        // Draw "Click Here" bar - fades in last
        if (state >= TitleScreenState.LOADER_FADING_IN && currentClickTexture.id != 0) {
            DrawTextureRec(
                currentClickTexture, 
                Rectangle(0, 0, currentClickTexture.width, currentClickTexture.height), // Source rect
                Vector2(clickHereBounds.x, clickHereBounds.y), // Position
                ColorAlpha(Colors.WHITE, loaderAlpha) // Tint with fade alpha
            );
        }

        // If just fading in (before logo appears), fade the whole screen from black
        if (state == TitleScreenState.FADING_IN) {
            DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), ColorAlpha(Colors.BLACK, 1.0f - currentAlpha));
        }
    }

    void unload() {
        if (state == TitleScreenState.UNINITIALIZED) {
            writeln("TitleScreen not initialized. Cannot unload.");
            return;
        }
        writeln("Unloading TitleScreen...");
        // Resources are managed by MemoryManager, no manual texture unloading needed.
        // Reset state
        state = TitleScreenState.UNINITIALIZED;
        // Reset variables
        fadeInTimer = 0.0f;
        logoFlyInTimer = 0.0f;
        logo2FadeInTimer = 0.0f;
        loaderFadeInTimer = 0.0f;
        currentAlpha = 0.0f;
        logo2Alpha = 0.0f;
        loaderAlpha = 0.0f;
        isMouseOverClickHere = false;
        writeln("TitleScreen unloaded successfully.");
    }
}