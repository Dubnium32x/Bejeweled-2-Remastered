module world.game_manager;

import raylib;

import std.stdio;
import std.file;
import std.process;
import std.json;
import std.path;
import std.algorithm : map;
import std.string;
import std.array;

import world.display_manager;
import world.audio_manager;

import screens.init_screen;
import screens.title_screen;


// ---- ENUMS ----
enum GameState {
    INIT,
    TITLE,
    GAMEPLAY,
    GAMEOVER
}

enum GameplayState {
    PLAYING,
    PAUSED,
    GAMEOVER
}

enum GameplayType {
    CLASSIC,
    ACTION,
    PUZZLE,
    ENDLESS,
    TWILIGHT,
    HYPER,
    COGNITO,
    FINITY
}

enum TitleState {
    LOGO,
    MAINMENU
}

// ---- GLOBALS ----

// display settings 
public bool isFullscreen = false;
public bool isVSyncEnabled = true;
public int[] resolution = [1280, 720]; // Default resolution

// in-game settings
public int score = 0;
public int highScore = 0;
public bool isPaused = false;

// audio settings
public float musicVolume = 0.5;
public float sfxVolume = 0.5;
public float voxVolume = 0.5;
public float ambienceVolume = 0.5;

// gameplay settings
public bool autoSaveEnabled = false;
public bool randomBackdrops = false;
public enum GemStyle {
    CLASSIC,
    MODERN,
    RETRO
}

interface World {
    void initialize();
    void update();
    void render();
}

public GemStyle currentGemStyle = GemStyle.CLASSIC;

// ---- CLASS ----
class writeToJSON {
    // Function to write game settings to a JSON file
    void saveSettings(string filePath) {
        import std.json : JSONValue;
        import std.file : write;

        JSONValue settings = JSONValue([
            "isFullscreen": JSONValue(isFullscreen),
            "isVSyncEnabled": JSONValue(isVSyncEnabled),
            "resolution": JSONValue(resolution.map!(v => JSONValue(v)).array),
            "score": JSONValue(score),
            "highScore": JSONValue(highScore),
            "isPaused": JSONValue(isPaused),
            "musicVolume": JSONValue(musicVolume),
            "sfxVolume": JSONValue(sfxVolume),
            "voxVolume": JSONValue(voxVolume),
            "ambienceVolume": JSONValue(ambienceVolume),
            "autoSaveEnabled": JSONValue(autoSaveEnabled),
            "randomBackdrops": JSONValue(randomBackdrops),
            "gemStyle": JSONValue(cast(int)currentGemStyle)
        ]);

        string jsonString = settings.toString();
        write(filePath, jsonString);
    }
}

class GameManager : World {
    private static GameManager instance;
    GameState gameState;
    GameplayState gameplayState;
    TitleState titleState;
    DisplayManager displayManager;
    AudioManager audioManager;

    this() {
        initialize();
    }

    // Singleton accessor
    public static GameManager getInstance() {
        if (instance is null) {
            instance = new GameManager();
        }
        return instance;
    }

    // initalize the game
    void initialize() {
        // Ensure managers are constructed
        displayManager = new DisplayManager();
        audioManager = new AudioManager();

        import std.file : readText, exists;
        import std.json : parseJSON, JSONValue;
        import std.algorithm : map;
        gameState = GameState.INIT;
        gameplayState = GameplayState.PLAYING;
        titleState = TitleState.LOGO;

        // Load settings from JSON file if it exists
        if (exists("settings.json")) {
            string jsonString = readText("settings.json");
            JSONValue settings = parseJSON(jsonString);

            isFullscreen = settings["isFullscreen"].get!bool;
            isVSyncEnabled = settings["isVSyncEnabled"].get!bool;
            resolution = settings["resolution"].array.map!(v => v.get!int).array;
            score = settings["score"].get!int;
            highScore = settings["highScore"].get!int;
            isPaused = settings["isPaused"].get!bool;
            musicVolume = settings["musicVolume"].get!float;
            sfxVolume = settings["sfxVolume"].get!float;
            voxVolume = settings["voxVolume"].get!float;
            ambienceVolume = settings["ambienceVolume"].get!float;
            autoSaveEnabled = settings["autoSaveEnabled"].get!bool;
            randomBackdrops = settings["randomBackdrops"].get!bool;
            currentGemStyle = cast(GemStyle)(settings["gemStyle"].get!int);
        }
        else {
            // Default values if no settings file exists
            isFullscreen = false;
            isVSyncEnabled = true;
            resolution = [800, 600];
            score = 0;
            highScore = 0;
            isPaused = false;
        }

        // Apply display settings
        displayManager.setResolution(Resolution.RES_1280x720);
        displayManager.setFrameRate(60);
    }

    void update() {
        // Handle game state updates
        switch (gameState) {
            case GameState.INIT:
                // Initialization logic if needed
                gameState = GameState.INIT;
                break;
            case GameState.TITLE:
                // Update title state
                switch (titleState) {
                    case TitleState.LOGO:
                        // Logic for logo state
                        break;
                    case TitleState.MAINMENU:
                        // Logic for main menu state
                        break;
                    default:
                        writefln("Not able to update for title state: %s", titleState);
                        break;
                }
                break;
            case GameState.GAMEPLAY:
                if (!isPaused) {
                    // Update gameplay logic
                }
                break;
            case GameState.GAMEOVER:
                // Handle game over logic
                break;
            default:
                writefln("Not able to update for state: %s", gameState);
                break;
        }
    }

    void render() {
        // Render game based on current state
        switch (gameState) {
            case GameState.INIT:
                // Render initialization screen if needed
                
                break;
            case GameState.TITLE:
                switch (titleState) {
                    case TitleState.LOGO:
                        // Render logo screen
                        // writeln("Rendering logo state...");
                        break;
                    case TitleState.MAINMENU:
                        // Render main menu screen
                        // writeln("Rendering main menu state...");
                        break;
                    default:
                        writefln("Not able to render for title state: %s", titleState);
                        break;
                }
                break;
            case GameState.GAMEPLAY:
                if (!isPaused) {
                    // Render gameplay elements
                    // writeln("Rendering gameplay state...");
                }
                break;
            case GameState.GAMEOVER:
                // Render game over screen
                break;
            default:
                writefln("Not able to draw for state: %s", gameState);
                break;
        }
    }

    void cleanup() {
        // Save settings to JSON file
        writeToJSON writer = new writeToJSON();
        writer.saveSettings("settings.json");
    }
}
