module world.transition_manager;

import raylib;
import std.stdio;
import std.math;
import world.screen_states;
import world.screen_manager;
import world.memory_manager;
import world.audio_manager; // Add audio manager import
import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT;

enum TransitionType {
    NONE,
    WORMHOLE,
    FADE,
    SLIDE
}

enum TransitionState {
    IDLE,
    TRANSITIONING_OUT,
    TRANSITIONING_IN,
    COMPLETE
}

class TransitionManager {
    private static TransitionManager _instance;
    
    // Transition properties
    private TransitionType currentTransitionType = TransitionType.NONE;
    private TransitionState transitionState = TransitionState.IDLE;
    private float transitionProgress = 0.0f;
    private float transitionDuration = 1.0f;
    
    // Screen transition data
    private ScreenState fromState;
    private ScreenState toState;
    private RenderTexture2D fromScreenCapture;
    private RenderTexture2D toScreenCapture;
    private bool hasFromCapture = false;
    private bool hasToCapture = false;
    
    // Audio management
    private AudioManager audioManager;
    private bool musicFadeStarted = false;
    private bool soundsPlayed = false;
    private float soundSequenceTimer = 0.0f;
    
    // Wormhole effect properties
    private Texture2D wormholeTexture;
    private int currentWormholeFrame = 0; // 0, 1, or 2 for the 3 frames
    private float frameTimer = 0.0f;
    private float frameRate = 0.15f; // Time per frame (150ms)
    private float wormholeScale = 0.1f;
    private Vector2 wormholeCenter;
    
    // Initialize singleton
    static TransitionManager getInstance() {
        if (_instance is null) {
            _instance = new TransitionManager();
        }
        return _instance;
    }
    
    private this() {
        // Initialize render textures for screen capture
        fromScreenCapture = LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT);
        toScreenCapture = LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT);
        
        // Set wormhole center to screen center
        wormholeCenter = Vector2(VIRTUAL_SCREEN_WIDTH / 2.0f, VIRTUAL_SCREEN_HEIGHT / 2.0f);
        
        // Load wormhole texture
        auto memManager = MemoryManager.instance();
        wormholeTexture = memManager.loadTexture("resources/image/nr_ringdude.png");
        SetTextureFilter(wormholeTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        
        // Initialize audio manager
        audioManager = AudioManager.getInstance();
        
        writeln("TransitionManager initialized");
    }
    
    // Start a transition between screens
    void startTransition(ScreenState from, ScreenState to, TransitionType type = TransitionType.WORMHOLE, float duration = 1.0f) {
        if (transitionState != TransitionState.IDLE) {
            writeln("TransitionManager: Transition already in progress, ignoring new request");
            return;
        }
        
        fromState = from;
        toState = to;
        currentTransitionType = type;
        transitionDuration = duration;
        transitionProgress = 0.0f;
        transitionState = TransitionState.TRANSITIONING_OUT;
        
        // Reset wormhole properties
        currentWormholeFrame = 0;
        frameTimer = 0.0f;
        wormholeScale = 0.0f; // Start from zero scale
        musicFadeStarted = false;
        
        // IMMEDIATELY capture current screen and switch to prepare the "to" screen
        captureCurrentScreen();
        performActualScreenSwitch();
        
        // Play transition start sound effects using AudioManager for proper sequencing
        if (audioManager !is null) {
            // Play mouse click immediately, then game start sound after a short delay
            string[] sounds = [
                "resources/audio/sfx/mainmenu_mouseclick.ogg",
                "resources/audio/sfx/mainmenu_gamestart.ogg"
            ];
            float[] delays = [0.0f, 0.1f]; // Click immediately, game start after 100ms
            audioManager.playSoundSequence(sounds, delays, AudioType.SFX);
            writeln("TransitionManager: Started sound sequence for transition");
        }
        
        writeln("TransitionManager: Starting ", type, " transition from ", from, " to ", to);
    }
    
    // Update transition animation
    void update(float deltaTime) {
        if (transitionState == TransitionState.IDLE) return;
        
        // Update transition progress
        transitionProgress += deltaTime / transitionDuration;
        
        // Handle music fading at the start of transition
        if (!musicFadeStarted && transitionProgress > 0.1f && audioManager !is null) {
            // Start fading out the current music and prepare next music based on destination
            string nextMusicPath = getNextMusicForState(toState);
            if (nextMusicPath != "") {
                // Add delay for gameplay music to create a pause before the full suite starts
                float musicDelay = (toState == ScreenState.GAMEPLAY) ? 0.6f : 0.0f;
                audioManager.fadeOutMusicWithStyle(transitionDuration * 0.6f, nextMusicPath, -1.0f, true, musicDelay);
                writeln("TransitionManager: Started music fade to: ", nextMusicPath, " with delay: ", musicDelay, "s");
            }
            musicFadeStarted = true;
        }
        
        // Update wormhole animation properties
        if (currentTransitionType == TransitionType.WORMHOLE) {
            updateWormholeEffect(deltaTime);
        }
        
        // Handle transition state changes
        switch (transitionState) {
            case TransitionState.TRANSITIONING_OUT:
                // No need to wait - we already captured and switched immediately
                // Just let the transition complete normally
                if (transitionProgress >= 1.0f) {
                    completeTransition();
                }
                break;
                
            case TransitionState.TRANSITIONING_IN:
                if (transitionProgress >= 1.0f) {
                    // Transition complete
                    completeTransition();
                }
                break;
                
            default:
                break;
        }
    }
    
    // Update wormhole-specific effects
    private void updateWormholeEffect(float deltaTime) {
        // Animate through the 3 frames of the wormhole sprite sheet
        frameTimer += deltaTime;
        if (frameTimer >= frameRate) {
            frameTimer = 0.0f;
            currentWormholeFrame = (currentWormholeFrame + 1) % 3; // Cycle through 0, 1, 2
        }
        
        // Animate scale based on transition progress - MUCH FASTER scaling
        // Scale grows from 0 to full screen coverage quickly
        float maxScale = (VIRTUAL_SCREEN_WIDTH > VIRTUAL_SCREEN_HEIGHT ? VIRTUAL_SCREEN_WIDTH : VIRTUAL_SCREEN_HEIGHT) / (cast(float)wormholeTexture.width / 3.0f) * 2.5f;
        // Use a power curve to make it scale faster initially
        float scaleCurve = transitionProgress * transitionProgress * 3.0f; // Quadratic growth, 3x faster
        wormholeScale = scaleCurve * maxScale;
        
        // Keep the wormhole always centered
        wormholeCenter = Vector2(VIRTUAL_SCREEN_WIDTH / 2.0f, VIRTUAL_SCREEN_HEIGHT / 2.0f);
    }
    
    // Capture the current screen to texture
    private void captureCurrentScreen() {
        auto screenManager = ScreenManager.getInstance();
        
        BeginTextureMode(fromScreenCapture);
        ClearBackground(Colors.BLACK);
        if (screenManager.getActiveScreen() !is null) {
            screenManager.getActiveScreen().draw();
        }
        EndTextureMode();
        
        hasFromCapture = true;
        writeln("TransitionManager: Captured current screen");
    }
    
    // Perform the actual screen switch through ScreenManager
    private void performActualScreenSwitch() {
        auto screenManager = ScreenManager.getInstance();
        screenManager.changeState(toState);
        
        // Give the new screen a frame to initialize and then capture it
        // We'll capture it in the next draw call
        hasToCapture = false;
        writeln("TransitionManager: Performed screen switch to ", toState);
    }
    
    // Complete the transition
    private void completeTransition() {
        transitionState = TransitionState.COMPLETE;
        transitionProgress = 1.0f;
        
        // Clean up
        hasFromCapture = false;
        hasToCapture = false;
        
        writeln("TransitionManager: Transition complete");
        
        // Reset to idle after a brief delay
        transitionState = TransitionState.IDLE;
    }
    
    // Check if a transition is active
    bool isTransitioning() {
        return transitionState != TransitionState.IDLE && transitionState != TransitionState.COMPLETE;
    }
    
    // Draw the transition effect
    void draw() {
        if (transitionState == TransitionState.IDLE) return;
        
        auto screenManager = ScreenManager.getInstance();
        
        // Capture the "to" screen immediately if we haven't yet
        if (!hasToCapture) {
            BeginTextureMode(toScreenCapture);
            ClearBackground(Colors.BLACK);
            if (screenManager.getActiveScreen() !is null) {
                screenManager.getActiveScreen().draw();
            }
            EndTextureMode();
            hasToCapture = true;
            writeln("TransitionManager: Captured 'to' screen for masking");
        }
        
        // Draw the transition effect based on type
        switch (currentTransitionType) {
            case TransitionType.WORMHOLE:
                drawWormholeTransition();
                break;
            case TransitionType.FADE:
                drawFadeTransition();
                break;
            default:
                // Fallback - just draw current screen
                if (screenManager.getActiveScreen() !is null) {
                    screenManager.getActiveScreen().draw();
                }
                break;
        }
    }
    
    // Draw wormhole transition effect
    private void drawWormholeTransition() {
        auto screenManager = ScreenManager.getInstance();
        
        // Debug output
        if (cast(int)(transitionProgress * 10) != cast(int)((transitionProgress - GetFrameTime() / transitionDuration) * 10)) {
            writeln("Wormhole transition progress: ", transitionProgress, 
                   " scale: ", wormholeScale, 
                   " frame: ", currentWormholeFrame,
                   " state: ", transitionState);
        }
        
        // Always draw the "from" screen as background
        if (hasFromCapture) {
            // Draw the captured "from" screen (title screen)
            DrawTexturePro(
                fromScreenCapture.texture,
                Rectangle(0, 0, fromScreenCapture.texture.width, -fromScreenCapture.texture.height),
                Rectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT),
                Vector2(0, 0),
                0.0f,
                Colors.WHITE
            );
        } else if (screenManager.getActiveScreen() !is null) {
            // Fallback to live drawing of current screen
            screenManager.getActiveScreen().draw();
        }
        
        // Only draw the "to" screen through the wormhole mask - START FROM PIXEL SIZE
        if (wormholeScale > 0.0f && hasToCapture) {
            // Calculate wormhole position and size (always centered)
            // Note: Each frame is 1/3 of the texture width
            float frameWidth = wormholeTexture.width / 3.0f;
            float frameHeight = wormholeTexture.height;
            float wormholeWidth = frameWidth * wormholeScale;
            float wormholeHeight = frameHeight * wormholeScale;
            
            // Make the cookie-cutter smaller to fit within the actual hole of the wormhole
            // The hole is roughly 50% of the total wormhole size
            float holeRatio = 0.5f;
            float holeWidth = wormholeWidth * holeRatio;
            float holeHeight = wormholeHeight * holeRatio;
            
            // Ensure minimum 1 pixel size for the scissor mode
            int scissorWidth = cast(int)holeWidth;
            int scissorHeight = cast(int)holeHeight;
            if (scissorWidth < 1) scissorWidth = 1;
            if (scissorHeight < 1) scissorHeight = 1;
            
            // Use the smaller hole size for the scissor mask
            BeginScissorMode(
                cast(int)(wormholeCenter.x - scissorWidth / 2.0f), 
                cast(int)(wormholeCenter.y - scissorHeight / 2.0f),
                scissorWidth,
                scissorHeight
            );
            
            // Draw the captured "to" screen (game screen)
            DrawTexturePro(
                toScreenCapture.texture,
                Rectangle(0, 0, toScreenCapture.texture.width, -toScreenCapture.texture.height),
                Rectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT),
                Vector2(0, 0),
                0.0f,
                Colors.WHITE
            );
            
            EndScissorMode();
        }
        
        // Draw the wormhole border/ring for visual effect - NO TRANSPARENCY, NORMAL DRAWING
        if (wormholeScale > 0.01f) {
            // Calculate the source rectangle for the current frame
            float frameWidth = wormholeTexture.width / 3.0f; // Each frame is 1/3 of texture width
            float frameHeight = wormholeTexture.height;
            Rectangle sourceRect = Rectangle(
                currentWormholeFrame * frameWidth, // X offset based on current frame
                0,                                 // Y is always 0
                frameWidth,                        // Width of one frame
                frameHeight                        // Full height
            );
            
            // Draw the current wormhole frame NORMALLY - no transparency
            Color normalColor = Colors.WHITE; // Draw it normally, no transparency
            
            DrawTexturePro(
                wormholeTexture,
                sourceRect,
                Rectangle(
                    wormholeCenter.x,
                    wormholeCenter.y,
                    frameWidth * wormholeScale,
                    frameHeight * wormholeScale
                ),
                Vector2((frameWidth * wormholeScale) / 2.0f, (frameHeight * wormholeScale) / 2.0f),
                0.0f, // No rotation needed, we're animating frames
                normalColor
            );
        }
    }
    
    // Draw fade transition effect
    private void drawFadeTransition() {
        auto screenManager = ScreenManager.getInstance();
        
        // Simple fade effect - just draw current screen with varying alpha
        if (screenManager.getActiveScreen() !is null) {
            screenManager.getActiveScreen().draw();
        }
        
        // Overlay fade effect
        float fadeAlpha = 0.0f;
        if (transitionState == TransitionState.TRANSITIONING_OUT) {
            fadeAlpha = transitionProgress * 2.0f;
        } else if (transitionState == TransitionState.TRANSITIONING_IN) {
            fadeAlpha = 1.0f - ((transitionProgress - 0.5f) * 2.0f);
        }
        
        if (fadeAlpha > 0.0f) {
            DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, 
                         Color(0, 0, 0, cast(ubyte)(255 * fadeAlpha)));
        }
    }
    
    // Helper function to determine what music should play for each screen state
    private string getNextMusicForState(ScreenState state) {
        switch (state) {
            case ScreenState.TITLE:
                return "Main Theme - Bejeweled 2.ogg";
            case ScreenState.GAMEPLAY:
                // For game screen, we could check the game mode and return appropriate music
                // For now, return a default game music
                return "BeyondTheNetworkMix2025.ogg"; // Use full suite for gameplay
            case ScreenState.SETTINGS:
                return "Main Theme - Bejeweled 2.ogg"; // Keep title music for settings
            case ScreenState.INIT:
                return "Main Theme - Bejeweled 2.ogg";
            default:
                return "Main Theme - Bejeweled 2.ogg"; // Default fallback
        }
    }

    // Cleanup
    void unload() {
        if (fromScreenCapture.id > 0) {
            UnloadRenderTexture(fromScreenCapture);
        }
        if (toScreenCapture.id > 0) {
            UnloadRenderTexture(toScreenCapture);
        }
        if (wormholeTexture.id > 0) {
            UnloadTexture(wormholeTexture);
        }
        writeln("TransitionManager unloaded");
    }
}
