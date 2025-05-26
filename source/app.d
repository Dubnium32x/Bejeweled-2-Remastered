module app;

import raylib;

import std.stdio;
import std.file;
import std.process;
import std.path;
import std.string;
import std.algorithm;

import data;
import world.screen_manager;
import world.audio_manager;
import world.memory_manager;
import world.screen_states;
import screens.init_screen;
import screens.title_screen; // Import the new title screen

// ---- LOAD RESOURCES ----
Font continuumBold;
Font continuumLight;
Font continuumMedium;
Font cristal;
Font quincy;
// Use __gshared to ensure proper sharing across modules
__gshared Font[] fontFamily;

// Virtual screen setup
private const int VIRTUAL_SCREEN_WIDTH = 1600;
private const int VIRTUAL_SCREEN_HEIGHT = 900;
private __gshared RenderTexture2D virtualScreen; // __gshared if other modules need direct access, otherwise private


// Function to get mouse position in virtual screen coordinates
Vector2 GetMousePositionVirtual() {
    Vector2 mouseScreenPos = GetMousePosition();
    
    float scale = min(cast(float)GetScreenWidth() / VIRTUAL_SCREEN_WIDTH, 
                      cast(float)GetScreenHeight() / VIRTUAL_SCREEN_HEIGHT);
                      
    // Calculate the top-left position of the scaled virtual screen on the actual screen
    float destX = (GetScreenWidth() - (VIRTUAL_SCREEN_WIDTH * scale)) / 2.0f;
    float destY = (GetScreenHeight() - (VIRTUAL_SCREEN_HEIGHT * scale)) / 2.0f;

    // Convert screen mouse position to virtual screen mouse position
    float virtualMouseX = (mouseScreenPos.x - destX) / scale;
    float virtualMouseY = (mouseScreenPos.y - destY) / scale;

    // Clamp to virtual screen bounds if necessary, though often not strictly needed
    // virtualMouseX = clamp(virtualMouseX, 0, VIRTUAL_SCREEN_WIDTH);
    // virtualMouseY = clamp(virtualMouseY, 0, VIRTUAL_SCREEN_HEIGHT);

    return Vector2(virtualMouseX, virtualMouseY);
}


void main() {
    InitWindow(1600, 900, "Bejeweled 2 Remastered"); // Actual window size
    SetTargetFPS(60);
    // ToggleBorderlessWindowed(); // Optional: Toggle borderless window mode for fullscreen-like experience

    // Set the default game mode
    data.setCurrentGameMode(GameMode.ORIGINAL);

    // Initialize virtual screen
    virtualScreen = LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT);
    SetTextureFilter(virtualScreen.texture, TextureFilter.TEXTURE_FILTER_BILINEAR);

    // Load fonts at runtime using MemoryManager
    auto memManager = MemoryManager.instance();
    continuumBold = memManager.loadFont("resources/font/contb.ttf", 24);
    continuumLight = memManager.loadFont("resources/font/contl.ttf", 24);
    continuumMedium = memManager.loadFont("resources/font/contm.ttf", 24);
    cristal = memManager.loadFont("resources/font/cristal.ttf", 24);
    quincy = memManager.loadFont("resources/font/quincy.ttf", 24);
    
    fontFamily = [continuumBold, continuumLight, continuumMedium, cristal, quincy];

    // Initialize audio device first
    InitAudioDevice();
    
    // Initialize memory manager
    auto memoryManager = MemoryManager.instance();
    memoryManager.initialize();
    
    // Initialize audio manager
    auto audioManager = AudioManager.getInstance();
    if (audioManager !is null) {
        audioManager.initialize();
    }

    // Initialize screen manager
    auto screenManager = ScreenManager.getInstance();
    screenManager.initialize();
    
    // Register screens
    screenManager.registerScreen(ScreenState.INIT, InitScreen.getInstance());
    screenManager.registerScreen(ScreenState.TITLE, TitleScreen.getInstance()); // Register TitleScreen
    // TODO: Register other screens (Gameplay, Options, Highscores, etc.)
    
    // Set the initial screen state using the appropriate method
    screenManager.changeState(ScreenState.INIT);

    // Load the screen

    // start main game loop
    // Use the existing audioManager and screenManager variables
    float lastTime = 0;
    float currentTime = 0;
    float frameTime = 0;

    while(!WindowShouldClose()) {
        // Calculate frame time for performance monitoring
        currentTime = GetTime();
        frameTime = currentTime - lastTime;
        lastTime = currentTime;
        
        // Check for severe slowdown
        if (frameTime > 0.1f) { // More than 100ms per frame = less than 10 FPS
            writeln("Performance warning: Frame time: ", frameTime * 1000, " ms");
        }
        
        // --- UPDATE GAME LOGIC ---
        audioManager.update();
        screenManager.update(GetFrameTime());
        
        // --- DRAW GAME TO VIRTUAL SCREEN ---
        BeginTextureMode(virtualScreen);
            ClearBackground(Colors.BLANK); // Clear virtual screen to fully transparent
            BeginBlendMode(BlendMode.BLEND_ALPHA); // Ensure standard alpha blending for drawing operations
            
            // The active screen (e.g., TitleScreen) is responsible for 
            // drawing its own background and elements onto this now-cleared virtual screen.
            screenManager.draw(); 
            
            EndBlendMode();
        EndTextureMode();
        
        // --- DRAW VIRTUAL SCREEN TO ACTUAL WINDOW ---
        BeginDrawing();
            ClearBackground(Colors.BLACK); // Clear letterbox/pillarbox area to black

            // Calculate scale to fit virtual screen into actual screen, maintaining aspect ratio
            float scale = min(cast(float)GetScreenWidth() / VIRTUAL_SCREEN_WIDTH, 
                              cast(float)GetScreenHeight() / VIRTUAL_SCREEN_HEIGHT);
            
            // Calculate position to center the scaled virtual screen
            float destX = (GetScreenWidth() - (VIRTUAL_SCREEN_WIDTH * scale)) / 2.0f;
            float destY = (GetScreenHeight() - (VIRTUAL_SCREEN_HEIGHT * scale)) / 2.0f;

            // Define source and destination rectangles for drawing the texture
            // Note: Raylib render textures are Y-flipped by default. Negative height in sourceRec flips it back.
            Rectangle sourceRec = Rectangle(0, 0, VIRTUAL_SCREEN_WIDTH, -VIRTUAL_SCREEN_HEIGHT); 
            Rectangle destRec = Rectangle(destX, destY, VIRTUAL_SCREEN_WIDTH * scale, VIRTUAL_SCREEN_HEIGHT * scale);
            Vector2 origin = Vector2(0, 0); // Top-left origin

            BeginBlendMode(BlendMode.BLEND_ALPHA_PREMULTIPLY);
            DrawTexturePro(virtualScreen.texture, sourceRec, destRec, origin, 0.0f, Colors.WHITE);
            EndBlendMode();
            
            // Optional: Display FPS in debug mode (drawn on top of the scaled virtual screen)
            DrawFPS(10, 10);
            
        EndDrawing();
    }

    // De-Initialization
    UnloadRenderTexture(virtualScreen); // Unload the render texture
    // Unload fonts
    // ... existing deinitialization ...
}