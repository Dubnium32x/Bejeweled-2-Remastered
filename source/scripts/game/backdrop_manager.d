module game.backdrop_manager;

import raylib;
import std.stdio;
import std.file;
import std.path;
import std.string;
import std.random;
import std.algorithm;
import std.conv : to;

import world.memory_manager;
import data;
import screens.popups.options;

/**
 * BackdropManager
 * 
 * Manages loading and rendering of game backdrops.
 * Supports both sequential and random backdrop selection.
 */
class BackdropManager {
    private {
        // Backdrop textures
        Texture2D[] backdrops;
        string[] backdropPaths;
        
        // Current backdrop
        int currentBackdropIndex = 0;
        Texture2D currentBackdrop;
        
        // Simple backdrop tracking (following user's pseudocode)
        int backdropNum = 0;
        int backdropCount = 16;
        
        // Backdrop settings
        bool randomBackdrops = true;
        bool initialized = false;
        
        // Memory manager reference
        MemoryManager memoryManager;
        
        // Options screen reference for settings
        OptionsScreen optionsScreen;
        
        // Animation properties
        float fadeAlpha = 1.0f;
        bool isFading = false;
        float fadeSpeed = 2.0f;
        
        // Singleton instance
        __gshared BackdropManager _instance;
    }

    /**
     * Get singleton instance
     */
    static BackdropManager getInstance() {
        if (_instance is null) {
            synchronized {
                if (_instance is null) {
                    _instance = new BackdropManager();
                }
            }
        }
        return _instance;
    }

    /**
     * Initialize the backdrop manager
     */
    void initialize() {
        if (initialized) return;
        
        memoryManager = MemoryManager.instance();
        
        // Get reference to options screen to read settings
        import app : optionsScreen;
        this.optionsScreen = optionsScreen;
        
        // Load all backdrop paths
        loadBackdropPaths();
        
        // Load initial backdrop
        if (backdropPaths.length > 0) {
            selectInitialBackdrop();
        }
        
        initialized = true;
        writeln("BackdropManager initialized with ", backdropPaths.length, " backdrops");
    }

    /**
     * Load all available backdrop file paths
     */
    private void loadBackdropPaths() {
        string backdropDir = "resources/image/backdrops";
        
        if (!exists(backdropDir) || !isDir(backdropDir)) {
            writeln("ERROR: Backdrop directory not found: ", backdropDir);
            return;
        }
        
        // Get all PNG files in the backdrops directory
        auto entries = dirEntries(backdropDir, "*.png", SpanMode.shallow);
        
        foreach (entry; entries) {
            // Skip the title backdrop for gameplay
            if (entry.name.indexOf("title") == -1) {
                backdropPaths ~= entry.name;
                writeln("Found backdrop file: ", entry.name);
            }
        }
        
        // Sort for consistent ordering
        backdropPaths.sort();
        
        writefln("BackdropManager: Found %d backdrop files", backdropPaths.length);
        foreach (i, path; backdropPaths) {
            writefln("  [%d] %s", i, path);
        }
    }

    /**
     * Select the initial backdrop based on game mode and settings
     */
    private void selectInitialBackdrop() {
        if (backdropPaths.length == 0) return;
        
        // Use the new level 1 start logic
        onLevel1Start();
    }

    /**
     * Get backdrop index based on current game mode
     */
    private int getBackdropForGameMode() {
        int gameMode = data.getMostRecentGameMode();
        
        // Map game modes to backdrop ranges
        switch (gameMode) {
            case 0: // Classic
                return 0; // Start with backdrop00
            case 1: // Action
                return 3; // Start with backdrop03
            case 2: // Endless
                return 6; // Start with backdrop06
            case 3: // Puzzle
                return 9; // Start with backdrop09
            default:
                return 0;
        }
    }

    /**
     * Load the current backdrop texture
     */
    private void loadCurrentBackdrop() {
        if (currentBackdropIndex >= 0 && currentBackdropIndex < backdropPaths.length) {
            string backdropPath = backdropPaths[currentBackdropIndex];
            currentBackdrop = memoryManager.loadTexture(backdropPath);
            
            if (currentBackdrop.id == 0) {
                writeln("ERROR: Failed to load backdrop: ", backdropPath);
            } else {
                writefln("BackdropManager: Loaded backdrop: %s (index %d, texture ID %d)", 
                        backdropPath, currentBackdropIndex, currentBackdrop.id);
            }
        }
    }

    /**
     * Change to the next backdrop
     */
    void nextBackdrop() {
        if (backdropPaths.length <= 1) return;
        
        // Update randomBackdrops setting from options
        updateRandomBackdropsSetting();
        
        if (randomBackdrops) {
            // Select a random backdrop different from current
            auto rng = Random(unpredictableSeed);
            int newIndex;
            do {
                newIndex = uniform(0, cast(int)backdropPaths.length, rng);
            } while (newIndex == currentBackdropIndex && backdropPaths.length > 1);
            currentBackdropIndex = newIndex;
            writeln("BackdropManager: Random next backdrop selected");
        } else {
            // Move to next backdrop in sequence
            currentBackdropIndex = (currentBackdropIndex + 1) % cast(int)backdropPaths.length;
            writeln("BackdropManager: Sequential next backdrop selected");
        }
        
        loadCurrentBackdrop();
        writefln("BackdropManager: Changed to backdrop index %d", currentBackdropIndex);
    }

    /**
     * Change to the previous backdrop
     */
    void previousBackdrop() {
        if (backdropPaths.length <= 1) return;
        
        // Update randomBackdrops setting from options
        updateRandomBackdropsSetting();
        
        if (randomBackdrops) {
            // Select a random backdrop different from current
            auto rng = Random(unpredictableSeed);
            int newIndex;
            do {
                newIndex = uniform(0, cast(int)backdropPaths.length, rng);
            } while (newIndex == currentBackdropIndex && backdropPaths.length > 1);
            currentBackdropIndex = newIndex;
            writeln("BackdropManager: Random previous backdrop selected");
        } else {
            // Move to previous backdrop in sequence
            currentBackdropIndex = (currentBackdropIndex - 1 + cast(int)backdropPaths.length) % cast(int)backdropPaths.length;
            writeln("BackdropManager: Sequential previous backdrop selected");
        }
        
        loadCurrentBackdrop();
        writefln("BackdropManager: Changed to backdrop index %d", currentBackdropIndex);
    }

    /**
     * Set a specific backdrop by index
     */
    void setBackdrop(int index) {
        if (index >= 0 && index < backdropPaths.length) {
            currentBackdropIndex = index;
            loadCurrentBackdrop();
            writefln("Set backdrop to index %d", index);
        } else {
            writeln("ERROR: Invalid backdrop index: ", index);
        }
    }

    /**
     * Update the random backdrops setting from options
     */
    private void updateRandomBackdropsSetting() {
        if (optionsScreen !is null) {
            randomBackdrops = optionsScreen.getRandomBackdrops();
        }
    }

    /**
     * Set random backdrop mode
     */
    void setRandomBackdrops(bool random) {
        randomBackdrops = random;
        writefln("BackdropManager: Random backdrops %s", random ? "enabled" : "disabled");
    }

    /**
     * Refresh the random backdrops setting from options (call this when options change)
     */
    void refreshRandomBackdropsSetting() {
        updateRandomBackdropsSetting();
        writefln("BackdropManager: Refreshed random backdrops setting: %s", randomBackdrops);
    }

    /**
     * Start a fade transition
     */
    void startFadeTransition(float duration = 1.0f) {
        isFading = true;
        fadeSpeed = 1.0f / duration;
    }

    /**
     * Update backdrop animations
     */
    void update(float deltaTime) {
        if (isFading) {
            fadeAlpha -= fadeSpeed * deltaTime;
            if (fadeAlpha <= 0.0f) {
                fadeAlpha = 0.0f;
                isFading = false;
                // Here you could trigger backdrop change and fade back in
            }
        }
    }

    /**
     * Draw the current backdrop
     */
    void draw() {
        if (currentBackdrop.id == 0) return;
        
        // Draw backdrop to fill the entire screen with proper alpha blending
        import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT;
        
        Rectangle sourceRect = Rectangle(0, 0, currentBackdrop.width, currentBackdrop.height);
        Rectangle destRect = Rectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT);
        
        // Use WHITE tint with fadeAlpha to preserve alpha channel from texture
        Color tint = Color(255, 255, 255, cast(ubyte)(fadeAlpha * 255));
        
        // DrawTexturePro with WHITE preserves the original alpha map
        DrawTexturePro(currentBackdrop, sourceRect, destRect, Vector2(0, 0), 0.0f, tint);
    }

    /**
     * Draw the backdrop with custom tint and alpha
     */
    void draw(Color tint) {
        if (currentBackdrop.id == 0) return;
        
        import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT;
        
        Rectangle sourceRect = Rectangle(0, 0, currentBackdrop.width, currentBackdrop.height);
        Rectangle destRect = Rectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT);
        
        // DrawTexturePro preserves alpha maps when using proper blending
        DrawTexturePro(currentBackdrop, sourceRect, destRect, Vector2(0, 0), 0.0f, tint);
    }

    /**
     * Get the current backdrop texture
     */
    Texture2D getCurrentBackdrop() {
        return currentBackdrop;
    }

    /**
     * Get the current backdrop index
     */
    int getCurrentBackdropIndex() {
        return currentBackdropIndex;
    }

    /**
     * Get the total number of backdrops
     */
    int getBackdropCount() {
        return cast(int)backdropPaths.length;
    }

    /**
     * Get the current backdrop filename
     */
    string getCurrentBackdropName() {
        if (currentBackdropIndex >= 0 && currentBackdropIndex < backdropPaths.length) {
            return baseName(backdropPaths[currentBackdropIndex]);
        }
        return "None";
    }

    /**
     * Preload all backdrops for smooth transitions
     */
    void preloadAllBackdrops() {
        writeln("Preloading all backdrops...");
        
        foreach (i, backdropPath; backdropPaths) {
            Texture2D texture = memoryManager.loadTexture(backdropPath);
            if (texture.id == 0) {
                writeln("WARNING: Failed to preload backdrop: ", backdropPath);
            }
        }
        
        writefln("Preloaded %d backdrops", backdropPaths.length);
    }

    /**
     * Unload all backdrop resources
     */
    void unload() {
        // The memory manager will handle unloading textures
        initialized = false;
        writeln("BackdropManager unloaded");
    }

    /**
     * Call this when level 1 starts or when starting a new game
     */
    void onLevel1Start() {
        updateRandomBackdropsSetting();
        
        if (randomBackdrops) {
            // Select a random number between 0 and actual backdrop count-1
            auto rng = Random(unpredictableSeed);
            backdropNum = uniform(0, cast(int)backdropPaths.length, rng);
            writefln("Level 1 start: Random backdrop selected - backdrop%02d", backdropNum);
        } else {
            // Start with backdrop00
            backdropNum = 0;
            writeln("Level 1 start: Sequential backdrop - backdrop00");
        }
        
        currentBackdropIndex = backdropNum;
        loadCurrentBackdrop();
    }

    /**
     * Call this when advancing to the next level
     */
    void onLevelAdvance() {
        updateRandomBackdropsSetting();
        
        if (randomBackdrops) {
            // Select a random number between 0 and actual backdrop count-1
            auto rng = Random(unpredictableSeed);
            backdropNum = uniform(0, cast(int)backdropPaths.length, rng);
            writefln("Level advance: Random backdrop selected - backdrop%02d", backdropNum);
        } else {
            // Increment backdrop number sequentially
            backdropNum++;
            if (backdropNum >= cast(int)backdropPaths.length) {
                backdropNum = 0; // Loop back to backdrop00
            }
            writefln("Level advance: Sequential backdrop - backdrop%02d", backdropNum);
        }
        
        currentBackdropIndex = backdropNum;
        loadCurrentBackdrop();
    }
}
