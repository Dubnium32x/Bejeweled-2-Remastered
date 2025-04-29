module screens.init_screen;

import raylib;
import std.stdio;
import std.file;
import std.path;
import std.array;
import std.process;
import std.json;

import world.jxl_converter;
import world.display_manager;
import world.audio_manager;
import world.game_manager;
import image_paths;

// ---- DATA POOL ----
public Texture[] textures;

// ---- ENUMS ----
enum InitScreenState {
    LOADING,
    DONE
}

// ---- LOCALS ----
private bool isLoading = true;

// ---- CLASS ----
class InitScreen : World {
    // Singleton instance
    static InitScreen instance;
    // Current state of the screen
    InitScreenState state;
    DisplayManager displayManager;
    AudioManager audioManager;
    this() {
        instance = this;
        state = InitScreenState.LOADING;
        displayManager = new DisplayManager();
        audioManager = new AudioManager();
    }
    
    void initialize() {

    }
    void update() {
        // TODO: Add update logic for InitScreen
    }
    void render() {
        // TODO: Add render logic for InitScreen
    }

}