module screens.init_screen;

import raylib;

import std.stdio;
import std.file;
import std.json;
import std.path;
import std.process;
import std.algorithm;
import std.conv : to;
import std.math;
import std.string : toStringz;

import world.screen_manager;
import world.memory_manager;
import world.audio_manager;
import world.screen_states;
import app;
import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT; // Specifically import the constants

// ---- LOCAL VARIABLES ----
Texture popcapTexture;

// Animation properties
float fadeAlpha = 0.0f;
float displayTimer = 0.0f;

// Phase timing (in seconds)
float anniversaryFadeInTime = 1.0f;
float anniversaryDisplayTime = 6.0f; // Show anniversary message for 6 seconds
float anniversaryFadeOutTime = 1.0f;
float fadeInTime = 1.0f;
float displayTime = 2.5f;
float fadeOutTime = 1.0f;

// Loading states
enum LoadingPhase {
    ANNIVERSARY_FADE_IN,
    ANNIVERSARY_DISPLAY,
    ANNIVERSARY_FADE_OUT,
    FADE_IN,
    DISPLAY,
    FADE_OUT
}
LoadingPhase currentPhase = LoadingPhase.ANNIVERSARY_FADE_IN;

// ---- ENUMS ----
enum InitScreenState {
    UNINITIALIZED,
    INITIALIZED
}

// ---- CLASS ----
class InitScreen : IScreen {
    // Singleton instance
    private __gshared InitScreen instance;
    // Memory manager reference
    private MemoryManager memoryManager;
    // Audio manager reference
    private AudioManager audioManager;
    // Current state of the screen
    InitScreenState state;
    
    // Timer for animations
    private float timer = 0.0f;
    // Resources to preload
    private string[] texturesToPreload;
    private string[] soundsToPreload;
    private string[] musicToPreload;

    this() {
        instance = this;
        state = InitScreenState.UNINITIALIZED;
        memoryManager = MemoryManager.instance();
        audioManager = AudioManager.getInstance();
        
        // Define resources to preload (Removed unused loading bar/placeholder assets)
        texturesToPreload = [
            "resources/image/title_popcap.png",
            "resources/image/title_popcap_.png", // alpha
        ];
    }
    static InitScreen getInstance() {
        if (instance is null) {
            synchronized {
                if (instance is null) {
                    instance = new InitScreen();
                }
            }
        }
        return instance;
    }

    // Initialize the screen
    void initialize() {
        if (state == InitScreenState.INITIALIZED) {
            writeln("InitScreen already initialized.");
            return;
        }

        // Perform initialization tasks here
        writeln("Initializing InitScreen...");
        
        // Reset animation variables
        fadeAlpha = 0.0f;
        timer = 0.0f;
        displayTimer = 0.0f;
        currentPhase = LoadingPhase.ANNIVERSARY_FADE_IN;

        // Load textures using the memory manager for caching
        popcapTexture = memoryManager.loadTexture("resources/image/title_popcap.png");
        // backgroundTexture = memoryManager.loadTexture("resources/image/placeholder_1.png"); // Removed loading
        
        // Preload resources silently at initialization time
        preloadResources();

        // Apply texture filtering to fonts for better quality
        // Note: fontFamily is imported from app module
        foreach (font; fontFamily) {
            if (font.texture.id > 0) {
                SetTextureFilter(font.texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
                writeln("Applied bilinear filtering to font texture ID: ", font.texture.id);
            }
        }

        state = InitScreenState.INITIALIZED;
        writeln("InitScreen initialized successfully.");
    }

    void update(float deltaTime) {
        if (state != InitScreenState.INITIALIZED) {
            writeln("InitScreen not initialized. Cannot update.");
            return;
        }

        // Update animation timer
        timer += deltaTime;
        
        // Handle the different phases of the intro screen
        final switch (currentPhase) {
            case LoadingPhase.ANNIVERSARY_FADE_IN:
                // Fade in anniversary message
                fadeAlpha += deltaTime * (1.0f / anniversaryFadeInTime);
                if (fadeAlpha >= 1.0f) {
                    fadeAlpha = 1.0f;
                    currentPhase = LoadingPhase.ANNIVERSARY_DISPLAY;
                    timer = 0.0f;
                }
                break;
                
            case LoadingPhase.ANNIVERSARY_DISPLAY:
                // Display anniversary message
                if (timer >= anniversaryDisplayTime) {
                    currentPhase = LoadingPhase.ANNIVERSARY_FADE_OUT;
                    timer = 0.0f;
                }
                break;
                
            case LoadingPhase.ANNIVERSARY_FADE_OUT:
                // Fade out anniversary message
                fadeAlpha -= deltaTime * (1.0f / anniversaryFadeOutTime);
                if (fadeAlpha <= 0.0f) {
                    fadeAlpha = 0.0f;
                    currentPhase = LoadingPhase.FADE_IN;
                    timer = 0.0f;
                }
                break;
                
            case LoadingPhase.FADE_IN:
                // Fade in PopCap logo
                fadeAlpha += deltaTime * (1.0f / fadeInTime);
                if (fadeAlpha >= 1.0f) {
                    fadeAlpha = 1.0f;
                    currentPhase = LoadingPhase.DISPLAY;
                    timer = 0.0f; // Reset timer for the display phase
                }
                break;
                
            case LoadingPhase.DISPLAY:
                // Just display the PopCap logo and text for a fixed time
                if (timer >= displayTime) {
                    currentPhase = LoadingPhase.FADE_OUT;
                    timer = 0.0f; // Reset timer for the fade out phase
                }
                break;
                
            case LoadingPhase.FADE_OUT:
                // Fade out animation
                fadeAlpha -= deltaTime * (1.0f / fadeOutTime);
                if (fadeAlpha <= 0.0f) {
                    fadeAlpha = 0.0f;
                    
                    // Clean up before transitioning
                    writeln("Transitioning to Title screen");
                    
                    // Start playing music for the title screen
                    if (exists("resources/audio/music/arranged/Main Theme Bejeweled 2.ogg")) {
                        audioManager.playMusic("resources/audio/music/arranged/Main Theme Bejeweled 2.ogg");
                    }
                    
                    // Change to the title screen
                    ScreenManager.getInstance().changeState(ScreenState.TITLE);
                }
                break;
        }
    }
    
    /**
     * Preload game resources in the background
     */
    private void preloadResources() {
        writeln("Starting resource preloading...");
        
        // Use the memory manager to preload resources
        // First preload all regular textures
        foreach(texturePath; texturesToPreload) {
            if (!texturePath.endsWith("_.png")) { // Skip alpha maps for now
                if (exists(texturePath)) {
                    Texture2D texture = memoryManager.loadTexture(texturePath);
                    if (texture.id == 0) {
                        writeln("ERROR: Failed to load texture: ", texturePath);
                    } else {
                        writeln("Successfully loaded texture: ", texturePath);
                    }
                } else {
                    writeln("Warning: Resource not found: ", texturePath);
                }
            }
        }
        
        // Now load the alpha maps and associate them with their base textures
        foreach(alphaPath; texturesToPreload) {
            if (alphaPath.endsWith("_.png")) { // This is an alpha map
                if (exists(alphaPath)) {
                    // Get the base texture path by removing the trailing "_"
                    string basePath = alphaPath[0..$-5] ~ ".png";
                    
                    if (memoryManager.hasTexture(basePath)) {
                        // Load the alpha map
                        Texture2D alphaTex = memoryManager.loadTexture(alphaPath);
                        if (alphaTex.id == 0) {
                            writeln("ERROR: Failed to load alpha texture: ", alphaPath);
                        } else {
                            writeln("Successfully loaded alpha texture: ", alphaPath, " for base texture: ", basePath);
                        }
                    }
                } else {
                    writeln("Warning: Alpha map not found: ", alphaPath);
                }
            }
        }
        
        // Use audio manager to preload audio
        foreach(soundPath; soundsToPreload) {
            if (exists(soundPath)) {
                bool loaded = audioManager.playSFX(soundPath, 0.0f); // Load with volume 0 to avoid playing sounds
                if (!loaded) {
                    writeln("ERROR: Failed to load sound: ", soundPath);
                } else {
                    writeln("Successfully loaded sound: ", soundPath);
                }
            } else {
                writeln("Warning: Sound resource not found: ", soundPath);
            }
        }
        
        foreach(musicPath; musicToPreload) {
            if (exists(musicPath)) {
                bool loaded = audioManager.playMusic(musicPath, 0.0f, false); // Load with volume 0 and don't play
                if (!loaded) {
                    writeln("ERROR: Failed to load music: ", musicPath);
                } else {
                    writeln("Successfully loaded music: ", musicPath);
                }
            } else {
                writeln("Warning: Music resource not found: ", musicPath);
            }
        }
        
        writeln("Resource preloading complete");
    }

    void draw() {
        if (state != InitScreenState.INITIALIZED) {
            writeln("InitScreen not initialized. Cannot draw.");
            return;
        }

        // Draw black background
        DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, Colors.BLACK);
        
        // Create fade color based on the current phase
        Color fadeColor = Colors.WHITE;
        fadeColor.a = cast(ubyte)(255 * fadeAlpha);
        
        // Draw different content based on current phase
        if (currentPhase == LoadingPhase.ANNIVERSARY_FADE_IN || 
            currentPhase == LoadingPhase.ANNIVERSARY_DISPLAY || 
            currentPhase == LoadingPhase.ANNIVERSARY_FADE_OUT) {
            
            // Draw anniversary celebration message
            string[] anniversaryLines = [
                "CELEBRATING 25 YEARS OF BEJEWELED!",
                "",
                "This fan-made remaster is created with love and respect",
                "for the original masterpiece by PopCap Games.",
                "",
                "This project has NO official endorsement or affiliation",
                "with the original developers or current rights holders.",
                "",
                "Please support the original creators by purchasing",
                "official Bejeweled games and products!",
                "",
                "Thank you to PopCap Games for creating this timeless classic."
            ];
            
            float fontSize = 32.0f; // Increased from 24.0f
            float lineHeight = 40.0f; // Increased from 32.0f
            float totalHeight = anniversaryLines.length * lineHeight;
            float startY = (VIRTUAL_SCREEN_HEIGHT - totalHeight) / 2.0f;
            
            foreach (i, line; anniversaryLines) {
                if (line.length > 0) { // Skip empty lines for drawing
                    float currentFontSize = (i == 0) ? 36.0f : 28.0f; // Different size for title
                    Font currentFont = (i == 0) ? fontFamily[2] : fontFamily[1];
                    
                    float textWidth = MeasureTextEx(currentFont, line.toStringz(), currentFontSize, 1.0f).x;
                    float textX = (VIRTUAL_SCREEN_WIDTH - textWidth) / 2.0f;
                    float textY = startY + i * lineHeight;
                    
                    // Draw text with improved quality from bilinear filtering
                    DrawTextEx(currentFont, line.toStringz(), Vector2(textX, textY), currentFontSize, 1.0f, fadeColor);
                }
            }
            
        } else {
            // Draw PopCap logo and "Original game by" text
            DrawTexture(
                popcapTexture, 
                (VIRTUAL_SCREEN_WIDTH - popcapTexture.width) / 2,
                (VIRTUAL_SCREEN_HEIGHT - popcapTexture.height) / 2 + 20, // Adjusted Y position slightly down
                fadeColor
            );
            
            // Draw "Original game by" text above the logo
            string originalByText = "Original game by:";
            DrawTextEx(
                fontFamily[2],
                originalByText.toStringz(),
                Vector2(
                    (VIRTUAL_SCREEN_WIDTH - MeasureTextEx(fontFamily[2], originalByText.toStringz(), 20, 1.0f).x) / 2,
                    (VIRTUAL_SCREEN_HEIGHT - popcapTexture.height) / 2 - 20 // Centered horizontally and positioned slightly above the logo
                ),
                20,
                1.0f, // Spacing between characters
                fadeColor
            );
        }
    }

    void unload() {
        if (state != InitScreenState.INITIALIZED) {
            writeln("InitScreen not initialized. Cannot unload.");
            return;
        }

        // Note: We don't need to manually unload resources since they're managed by MemoryManager
        // Just mark the screen as uninitialized
        
        state = InitScreenState.UNINITIALIZED;
        writeln("InitScreen unloaded successfully.");
    }
}