module data;

import std.stdio;
import std.array;
import std.file;
import std.json;
import std.path;
import std.conv : to;

// Check if the player has chosen Original or Arranged mode
enum GameMode {
    ORIGINAL,
    ARRANGED
}

enum PlayMode {
    CLASSIC = 0,
    ACTION = 1,
    ENDLESS = 2,
    PUZZLE = 3,
    TWILIGHT = 4,
    HYPER = 5,
    COGNITO = 6,
    FINITY = 7,
    ORIGINAL = 8
}

GameMode currentGameMode;
PlayMode currentPlayMode;

// Track the most recently played game mode (0=Classic, 1=Action, 2=Endless, 3=Puzzle)
int mostRecentGameMode = 0; // Default to Classic

// Check if the player has saved data for each game mode
bool playerHasSavedGame = false;
bool playerHasSavedClassicGame = false;
bool playerHasSavedActionGame = false;
bool playerHasSavedPuzzleGame = false;
bool playerHasSavedEndlessGame = false;
bool playerHasSavedTwilightGame = false;
bool playerHasSavedHyperGame = false;
bool playerHasSavedCognitoGame = false;
bool playerHasSavedFinityGame = false;
bool playerHasSavedOriginalGame = false;

// Check if the player has saved name entry
bool playerHasSavedName = false;
string playerSavedName = "Player"; // Default name

// Variables to track the player's progress in puzzle mode, both in Original and Arranged
int percentPuzzleCompletionOriginal = 0; // Percentage of puzzle completion in Original mode
int percentPuzzleCompletionArranged = 0; // Percentage of puzzle completion in Arranged mode

// Variables and functions to track the player's progress in each game mode
int playerSavedClassicLevel = 1;
int playerSavedActionLevel = 1;

// 16 worlds, 5 puzzles each: track completion status
bool[16][5] playerHasCompletedPuzzle;

// Initialize the puzzle completion status for each world and puzzle
void initializePuzzleCompletion() {
    foreach (world; 0 .. 16) {
        foreach (puzzle; 0 .. 5) {
            playerHasCompletedPuzzle[world][puzzle] = false; // All puzzles start as incomplete
        }
    }
    writeln("Puzzle completion status initialized for all worlds and puzzles.");
}

// Function to mark a puzzle as completed
void markThisPuzzleCompleted(int world, int puzzle) {
    if (world < 0 || world >= 16 || puzzle < 0 || puzzle >= 5) {
        writeln("Invalid world or puzzle index.");
        return;
    }
    playerHasCompletedPuzzle[world][puzzle] = true;
    writeln("Puzzle ", puzzle, " in world ", world, " has been marked as completed.");
}

// Function to check if a world is completed
bool isWorldCompleted(int world) {
    if (world < 0 || world >= 16) {
        writeln("Invalid world index.");
        return false;
    }
    // Check if all puzzles in this world are completed
    foreach (puzzle; 0 .. 5) {
        if (!playerHasCompletedPuzzle[world][puzzle]) {
            return false; // Not all puzzles are completed
        }
    }
    return true; // All puzzles are completed
}

// Function to check if this world is new
// ... if so, set the puzzle index to 0 and prepare for tutorial puzzle (if it exists)
bool isNewWorld(int world) {
    if (world < 0 || world >= 16) {
        writeln("Invalid world index.");
        return false;
    }
    // Check if any puzzle in this world is completed
    foreach (puzzle; 0 .. 5) {
        if (playerHasCompletedPuzzle[world][puzzle]) {
            return false; // Not a new world
        }
    }
    return true; // All puzzles are incomplete, so it's a new world
}

// Function to get the completion status of a specific puzzle
bool isThisPuzzleCompleted(int world, int puzzle) {
    if (world < 0 || world >= 16 || puzzle < 0 || puzzle >= 5) {
        writeln("Invalid world or puzzle index.");
        return false;
    }
    return playerHasCompletedPuzzle[world][puzzle];
    writeln("Puzzle solved! World: ", world, ", Puzzle: ", puzzle);
}

// Function to check if "warp drive" is available
bool isWarpDriveAvailable(int world) {
    if (world < 0 || world >= 16) {
        writeln("Invalid world index.");
        return false;
    }
    int completedCount = 0;
    foreach (puzzle; 0 .. 5) {
        if (playerHasCompletedPuzzle[world][puzzle]) {
            completedCount++;
        }
    }
    return completedCount >= 4; // Warp drive available if at least 4 puzzles are completed
    writefln("Warp-drive ready!");
    writefln("Progress: World ", world, " with ", completedCount, " puzzles completed.");
}

// Function to reset all puzzle completion statuses
void resetPuzzleCompletion() {
    foreach (world; 0 .. 16)
        foreach (puzzle; 0 .. 5)
            playerHasCompletedPuzzle[world][puzzle] = false;
    writeln("All puzzle completion statuses have been reset.");
}

// Function to get percentage of puzzle completion in both game modes


int playerSavedPuzzleLevel = 1; // Default puzzle level
int playerSavedEndlessLevel = 1; // Default endless level
int playerSavedTwilightLevel = 1; // Default twilight level
int playerSavedHyperLevel = 1; // Default hyper level
int playerSavedCognitoLevel = 1; // Default cognito level
int playerSavedFinityLevel = 1; // Default finity level
int playerSavedOriginalLevel = 1; // Default original level

// Variables to set the player's scores
int playerSavedClassicScore = 0; // Default classic score
int playerSavedActionScore = 0; // Default action score
int playerSavedEndlessScore = 0; // Default endless score
int playerSavedTwilightScore = 0; // Default twilight score
int playerSavedHyperScore = 0; // Default hyper score
int playerSavedCognitoScore = 0; // Default cognito score
int playerSavedFinityScore = 0; // Default finity score
int playerSavedOriginalScore = 0; // Default original score

// Function to save the player's name
void savePlayerName(string name) {
    playerHasSavedName = true;
    playerSavedName = name;
    writeln("Player name has been saved.");
}

// Function to check if the player has saved a name
bool hasSavedPlayerName() {
    return playerHasSavedName;
}

// Function to check if there is a saved game for a specific mode
bool hasSavedGame(string mode) {
    switch (mode) {
        case "classic":
            return playerHasSavedClassicGame;
        case "action":
            return playerHasSavedActionGame;
        case "puzzle":
            return playerHasSavedPuzzleGame;
        case "endless":
            return playerHasSavedEndlessGame;
        case "twilight":
            return playerHasSavedTwilightGame;
        case "hyper":
            return playerHasSavedHyperGame;
        case "cognito":
            return playerHasSavedCognitoGame;
        case "finity":
            return playerHasSavedFinityGame;
        case "original":
            return playerHasSavedOriginalGame;
        default:
            writeln("Unknown game mode: ", mode);
            return false;
    }
}

// Function to check if there is a saved game at all
bool hasSavedGame() {
    return playerHasSavedGame;
}

// Function to save a game for a specific mode
void saveGame(string mode) {
    switch (mode) {
        case "classic":
            playerHasSavedClassicGame = true;
            break;
        case "action":
            playerHasSavedActionGame = true;
            break;
        case "puzzle":
            playerHasSavedPuzzleGame = true;
            break;
        case "endless":
            playerHasSavedEndlessGame = true;
            break;
        case "twilight":
            playerHasSavedTwilightGame = true;
            break;
        case "hyper":
            playerHasSavedHyperGame = true;
            break;
        case "cognito":
            playerHasSavedCognitoGame = true;
            break;
        case "finity":
            playerHasSavedFinityGame = true;
            break;
        case "original":
            playerHasSavedOriginalGame = true;
            break;
        default:
            writeln("Unknown game mode: ", mode);
            return;
    }
    playerHasSavedGame = true;
    writeln("Game has been saved for mode: ", mode);
}

// Function to load a saved game for a specific mode
void loadGame(string mode) {
    if (!hasSavedGame(mode)) {
        writeln("No saved game found for mode: ", mode);
        return;
    }
    // Logic to load the game state for the specified mode
    writeln("Loading saved game for mode: ", mode);
    // Here you would typically restore the game state from a file or memory
}

// Function to reset all saved game data
void resetAllSavedData() {
    playerHasSavedGame = false;

    playerHasSavedClassicGame = false;
    playerSavedClassicLevel = 1; // Reset classic level
    playerSavedClassicScore = 0; // Reset classic score

    playerHasSavedActionGame = false;
    playerSavedActionLevel = 1; // Reset action level
    playerSavedActionScore = 0; // Reset action score

    playerHasSavedPuzzleGame = false;
    resetPuzzleCompletion();

    playerHasSavedEndlessGame = false;
    playerSavedEndlessLevel = 1; // Reset endless level
    playerSavedEndlessScore = 0; // Reset endless score
    
    playerHasSavedTwilightGame = false;
    playerSavedTwilightLevel = 1; // Reset twilight level
    playerSavedTwilightScore = 0; // Reset twilight score

    playerHasSavedHyperGame = false;
    playerSavedHyperLevel = 1; // Reset hyper level
    playerSavedHyperScore = 0; // Reset hyper score

    playerHasSavedCognitoGame = false;
    playerSavedCognitoLevel = 1; // Reset cognito level
    playerSavedCognitoScore = 0; // Reset cognito score

    playerHasSavedFinityGame = false;
    playerSavedFinityLevel = 1; // Reset finity level
    playerSavedFinityScore = 0; // Reset finity score

    playerHasSavedOriginalGame = false;
    playerSavedOriginalLevel = 1; // Reset original level
    playerSavedOriginalScore = 0; // Reset original score

    playerHasSavedName = false;
    playerSavedName = "Player"; // Reset to default name
    resetPuzzleCompletion(); // Reset all puzzle completion statuses
    writeln("All saved game data has been reset.");
}

// Function to reset a specific game mode's data
void resetGameModeData(string mode) {
    switch (mode) {
        case "classic":
            playerHasSavedClassicGame = false;
            playerSavedClassicLevel = 1;
            playerSavedClassicScore = 0;
            break;
        case "action":
            playerHasSavedActionGame = false;
            playerSavedActionLevel = 1;
            playerSavedActionScore = 0;
            break;
        case "puzzle":
            playerHasSavedPuzzleGame = false;
            playerSavedPuzzleLevel = 1;
            break;
        case "endless":
            playerHasSavedEndlessGame = false;
            playerSavedEndlessLevel = 1;
            playerSavedEndlessScore = 0;
            break;
        case "twilight":
            playerHasSavedTwilightGame = false;
            playerSavedTwilightLevel = 1;
            playerSavedTwilightScore = 0;
            break;
        case "hyper":
            playerHasSavedHyperGame = false;
            playerSavedHyperLevel = 1;
            playerSavedHyperScore = 0;
            break;
        case "cognito":
            playerHasSavedCognitoGame = false;
            playerSavedCognitoLevel = 1;
            playerSavedCognitoScore = 0;
            break;
        case "finity":
            playerHasSavedFinityGame = false;
            playerSavedFinityLevel = 1;
            playerSavedFinityScore = 0;
            break;
        case "original":
            playerHasSavedOriginalGame = false;
            playerSavedOriginalLevel = 1; // Reset original level
            break;
        default:
            writeln("Unknown game mode: ", mode);
    }
    writeln("Data for mode ", mode, " has been reset.");
}

// Function to reset all puzzle completion
void resetAllPuzzleCompletion() {
    foreach (world; 0 .. 16)
        foreach (puzzle; 0 .. 5)
            playerHasCompletedPuzzle[world][puzzle] = false;
    writeln("All puzzle completion statuses have been reset.");
}

// Function to check which game mode is currently active
GameMode getCurrentGameMode() {
    return currentGameMode;
}

// Function to set the current game mode
void setCurrentGameMode(GameMode mode) {
    // Validate the mode before setting it
    if (mode != GameMode.ORIGINAL && mode != GameMode.ARRANGED) {
        writeln("Invalid game mode: ", mode);
        return;
    }
    currentGameMode = mode;
    writeln("Current game mode set to: ", mode);
}

// Function to check which play mode is currently active
PlayMode getCurrentPlayMode() {
    return currentPlayMode;
}

// Function to set the current play mode
void setCurrentPlayMode(PlayMode mode) {
    currentPlayMode = mode;
    writeln("Current play mode set to: ", mode);
}

// Function to save the most recent game mode to JSON file
void saveMostRecentGameMode(int mode) {
    try {
        JSONValue json;
        json["mostRecentGameMode"] = mode;
        
        string saveDir = "save";
        if (!exists(saveDir)) {
            mkdir(saveDir);
        }
        
        string filePath = buildPath(saveDir, "most_recent_mode.json");
        std.file.write(filePath, json.toString());
        mostRecentGameMode = mode; // Update the variable
        writeln("Most recent game mode saved: ", mode);
    } catch (Exception e) {
        writeln("Error saving most recent game mode: ", e.msg);
    }
}

// Function to load the most recent game mode from JSON file
void loadMostRecentGameMode() {
    try {
        string filePath = buildPath("save", "most_recent_mode.json");
        if (exists(filePath)) {
            string jsonData = cast(string) std.file.read(filePath);
            JSONValue json = parseJSON(jsonData);
            mostRecentGameMode = json["mostRecentGameMode"].integer.to!int;
            writeln("Most recent game mode loaded: ", mostRecentGameMode);
        } else {
            writeln("No saved most recent game mode found, using default (Classic)");
            mostRecentGameMode = 0; // Default to Classic
        }
    } catch (Exception e) {
        writeln("Error loading most recent game mode: ", e.msg, " - using default (Classic)");
        mostRecentGameMode = 0; // Default to Classic on error
    }
}

// Function to get the most recent game mode
int getMostRecentGameMode() {
    return mostRecentGameMode;
}

// Test function to set the most recent game mode (for testing different modes)
void setMostRecentGameMode(int mode) {
    if (mode >= 0 && mode <= 3) {
        mostRecentGameMode = mode;
        saveMostRecentGameMode(mode);
        writeln("Test: Set most recent game mode to ", mode, " (", 
               mode == 0 ? "Classic" : mode == 1 ? "Action" : mode == 2 ? "Endless" : "Puzzle", ")");
    } else {
        writeln("Invalid mode: ", mode, " (valid range: 0-3)");
    }
}