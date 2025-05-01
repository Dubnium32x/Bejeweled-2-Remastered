module app;

import raylib;

import std.stdio;
import std.file;
import std.process;
import std.path;
import std.string;
import std.algorithm;

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
Font[] fontFamily;

void main() {
    InitWindow(1280, 720, "Bejeweled 2 Remastered");
    SetTargetFPS(60);

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

    // DEBUG play a voice sample
    // audioManager.loadSound("resources/audio/vox/welcome.ogg", AudioType.VOX);

    // start main game loop
    while(!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(Colors.RAYWHITE);

        // Update the current screen
        ScreenManager.getInstance().update(GetFrameTime());
        // Draw the current screen
        ScreenManager.getInstance().draw();
        EndDrawing();
    }
}