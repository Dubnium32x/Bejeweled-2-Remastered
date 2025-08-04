module screens.game_screen;

import raylib;

import std.stdio;
import std.array;
import std.algorithm;
import std.conv : to;
import std.file;
import std.math;
import std.string : toStringz;

import data;
import world.screen_manager;
import world.screen_states;
import world.memory_manager;
import world.audio_manager;
import game.backdrop_manager;
import game.game_board;

/*

    ---- NOTES ----

    ** General Game Screen Design **

    Upon your first time playing, there should be a popup that shows you how to play the game, which slides in from the top of the screen.
    The game board should be a 2D array of 8 by 8 tiles, each tile can be a different type of gem.

    The game board slides in from the right side.
    The menu bubbles and the score counter should slide in from the left side.

    The game board should be somewhat centered on the screen, moreso to the right, with the menu bubbles and score counter on the left side.
    
    When starting the game, the game board should be empty. After a second, the gems should start falling from the top of the game board.
    This also applies when the game is reset or a new level is started.

    When the game starts, the player should be able to make one of a generated 7 to 10 matches on the game board.
    The player should be able to make matches by clicking on two adjacent gems to swap them.
    If the player makes a match, the gems will animate and shrink down to nothing, with a particle effect of sparkles or stars.
    If the player makes a match that does not result in a match, the gems will automatically swap back to their original positions.

    ** Game Board Differentiation **

    In Classic and Endless modes, the game board is a 2D array of 8 by 8 gems. No special rules apply.

    In Puzzle mode, the game board is a 2D array of 8 by 8 tiles, but it will load a specific puzzle from the puzzles folder.
    Each tile is a specific gem type. Perhaps consider loading them from a CSV file or a JSON file.
    Original and Arranged modes will have different puzzles, so the game will need to load the appropriate puzzle based on the mode.

    In Action mode, the game board is a 2D array of 8 by 8 gems.
    Similar to Classic mode. The game board will have a progress bar that fills up as the player scores points.
    However, the progress bar will drain over time, and the player must score points to fill it back up.

    In Time Attack mode, the game board is a 2D array of 8 by 8 gems.
    Similar to Classic mode, but the player has a limited amount of time to score as many points as possible.
    Time Attack mode drains the player's progress bar over time, and the player can gain time by scoring points.
    Once the time runs out, the game ends and the player is taken to the game over screen.
    Alternatively, once the player reaches the maximum score, the player advances a level.

    In Twilight mode, the game board is a 2D array of 8 by 8 gems.
    Similar to Classic mode, but the board drops gems from the bottom of the screen instead of the top every other turn.
    The player must match gems to score points, but the gems will alternate between dropping from the top and bottom of the screen.
    This also encourages us to develop a game speed mechanic, where in this case, the game speed is lowered to emulate the feeling of twilight.
    UNLOCKED: The player must reach level 10 in Classic mode.

    In Hyper mode, the game board is a 2D array of 8 by 8 gems.
    Similar to Action mode, but the game speed is doubled.
    UNLOCKED: The player must reach level 6 in Action mode.

    In Finity mode, the game board is a 2D array of 8 by 8 gems.
    Similar to Classic mode, but the game board has bombs, coal, and other special gems that can be used to clear the board.
    It also has similar rules to Action mode, where the player must score points to advance to the next level.
    UNLOCKED: The player must reach level 50 in Endless mode.

    In Cognito mode, thte game board is a 2D array of 8 by 8 tiles.
    Similar to Puzzle mode, but the player must match gems to score points.
    UNLOCKED: The player must complete Puzzle mode.

    In Original mode, the game board is a 2D array of 8 by 8 gems.
    Similar to Classic mode, but the game board has a different set of gems and rules.
    Rather than it playing like a normal game (whether that be Original or Arranged),
    the gameplay is akin to Bejeweled 1, where the player must match gems to score points.
    No special gems are present, and the player must score points to advance to the next level.
    ORIGINAL WILL NOT BE SELECTABLE.
    To activate Original mode, the player must do a clockwise rotation of the game mode selection wheel 8 times.
    UNLOCKED: The player must reach level 20 in Classic mode.


    ** Gem Types **
    The game board will have different types of gems, each with a different color and shape.
    Gems can be red, orange, yellow, green, blue, purple, and white.

    Original and Arranged modes will have some distinct differences in gem types and rules.

    ORIGINAL:
    - The game rules are akin to Bejeweled 2, where the player must match gems to score points the old-fashioned way.
    - Any three gems of the same type will clear, and the player will score points.
    - Any gem color in a straight line of five will clear, and the gem will turn into a Hyper Gem.
    - Any gem color of the same type of 4 or more (not in a square or five in a row) will clear, and the gem will turn into a Power Gem.
    - Hyper Gems can match with Hyper Gems, but it will not clear the board.

    ARRANGED:
    - The game rules are akin to Bejeweled 3 and Stars, where the player must match gems to score points the new-fashioned way.
    - Any three gems of the same type will clear, and the player will score points.
    - Any gem color in a straight line of five will clear, and the gem will turn into a Hyper Gem.
    - Any gem color of the same type of 4 in a line or a square will clear, and the gem will turn into a Power Gem.
    - Any gem color of the same type of more than 4 in any other speical formation will clear, and the gem will turn into a Lightning Gem.
    - Hyper Gems can match with Hyper Gems, and it will clear the board.

    Power Gems will explode in a 3x3 area around them when matched, clearing all gems in that area.
    Lightning Gems will clear all gems in a cross shape around them, clearing all gems in that area.
    Hyper Gems will clear all gems of the same type on the board, regardless of their position.


    ** Other Game Features **
    The game will have a progress bar that fills up as the player scores points.
    Each level will have a different progress score to reach, and the player will advance to the next level once the progress bar is full.

    If a player makes a move that does not result in a match, the game will automatically swap the gems back to their original positions.
    

    ** Animations and Effects **
    The game will have animations for when gems are matched, when the game board slides in, and when the menu bubbles and score counter slide in.
    For example, when gems are matched, they will animate and shrink down to nothing, with a particle effect of sparkles or stars.
    
    When a gem is in the zone of an active special gem, it will shake and explode in a burst of color and particles.
    Lightning and Hyper Gems will have a special animation when they are matched, with a burst of color and particles,
    along with lightning effects that may need to be implemented with care.

    When a gem is selected, it will have a glowing effect around it, indicating that it is selected.
    When a gem is hovered over, it will have a slight scaling effect to indicate that it is being hovered over.
    
    Special gems will have a glow to them that spreads outwards. Use a shader to achieve this effect.

    Let't not forget about the wormhole effect! 
    When a level is complete, the game background will have a wormhole effect that swirls around the screen,
    which then... Plays a sequence of the player advancing to the next level through the wormhole.
    I reckon we may need to implement a shader or a 3D model for this effect.

    Speaking of, we will have to implement a different wormhole effect for screen transitions.
    Image resources/image/nr_ringdude.png should be use for the wormhole effect.
    The wormhole effect will be a swirling effect that transitions between screens.
    We will just need to figure out how to implement this effect in Raylib, so that it masks the transition between screens.

    ** Game Screen Implementation  TO DO **
    1. Define the game screen class.
    2. Implement the game screen's initialization, update, draw, and unload methods.
    3. Define the gems and their types.
    4. Define the game board and its layout.
    5. Implement the game logic for matching gems and scoring points.
    6. Set up the needed textures for the game board, gems, and UI elements.
    7. Construct the game speed mechanic, where the game speed increases as the player advances levels.
    8. Use the game speed mechanic to let the game foresee the player's moves and adjust the next moves accordingly.
    9. Implement the matching logic for gems, including special gems and their effects.
    10. Implement the game board sliding in from the right side.
    11. Implement the menu bubbles and score counter sliding in from the left side.
    12. Implement the hint system that shows the player where to match gems.
    13. Implement the score system for tracking the player's score and progress.
    14. Implement the commentator system for providing "words of encouragement" to the player.
    15. Implement the game over screen that shows the player's score and progress.
    16. Implement the game screen level transition system that uses the 3D wormhole effect. (This is not the same as the wormhole effect for screen transitions)
    17. Implement the leaderboard system that tracks the player's score and progress across all game modes.
    18. Apply special rules for each game mode, such as Classic, Action, Endless, Puzzle, and others.
    19. Implement the level tracking system that tracks the player's progress through the game.
    20. Implement the ranking system!


    ** Textures and Resources **
    - The game board will have a texture that represents the game board background: resources/image/FRAME.png
    - The gems will have textures that represent each gem type: resources/image/gem0.png, resources/image/gem1.png, etc.
    - The menu bubbles will have textures that represent each menu bubble: resources/image/menu_bubble0.png, resources/image/Classicmode.png
    - The score counter will have a texture that represents the score counter background: resources/image/SCOREPOD.png
    - The score font will be a texture image displaying numbers from 0 - 9: resources/image/scorefont1.png
    - The progress bar will have a texture that represents the progress bar background: resources/image/BttomBar.png
    
*/

// ---- LOCAL VARIABLES ----
private GameScreen _instance;

// ---- GAME SCREEN CLASS ----
class GameScreen : IScreen {
    private static GameScreen _instance;
    
    // Game state
    private bool isInitialized = false;
    
    // Fonts will be filtered for quality
    private bool fontsFiltered = false;
    
    // Backdrop manager
    private BackdropManager backdropManager;
    
    // Game board
    private GameBoard gameBoard;
    
    // Static singleton access
    static GameScreen getInstance() {
        if (_instance is null) {
            _instance = new GameScreen();
        }
        return _instance;
    }
    
    private this() {
        // Private constructor for singleton
    }
    
    void initialize() {
        if (isInitialized) return;
        
        // Apply font filtering for consistent quality across all screens
        if (!fontsFiltered) {
            import app : fontFamily;
            foreach (font; fontFamily) {
                if (font.texture.id > 0) {
                    SetTextureFilter(font.texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
                }
            }
            fontsFiltered = true;
            writeln("GameScreen: Applied bilinear filtering to fonts");
        }
        
        // Initialize backdrop manager
        backdropManager = BackdropManager.getInstance();
        backdropManager.initialize();
        
        // Initialize game board
        gameBoard = GameBoard.getInstance();
        gameBoard.initialize();
        gameBoard.generatePlayableBoard(); // Generate board with no initial matches but valid moves
        
        isInitialized = true;
        writeln("GameScreen initialized");
    }
    
    void update(float deltaTime) {
        // Update backdrop manager
        if (backdropManager !is null) {
            backdropManager.update(deltaTime);
        }
        
        // Update game board
        if (gameBoard !is null) {
            gameBoard.update(deltaTime);
        }
        
        // Handle input to return to title screen for now
        if (IsKeyPressed(KeyboardKey.KEY_ESCAPE)) {
            import world.screen_manager;
            import world.transition_manager;
            auto screenManager = ScreenManager.getInstance();
            writeln("GameScreen: ESC pressed, transitioning back to title screen with wormhole effect");
            screenManager.transitionToState(ScreenState.TITLE, TransitionType.WORMHOLE, 1.5f);
        }
        
        // Handle backdrop change keys (for testing)
        if (IsKeyPressed(KeyboardKey.KEY_N) && backdropManager !is null) {
            backdropManager.nextBackdrop();
        }
        if (IsKeyPressed(KeyboardKey.KEY_P) && backdropManager !is null) {
            backdropManager.previousBackdrop();
        }
    }
    
    void draw() {
        import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, fontFamily;
        
        // Draw backdrop first
        if (backdropManager !is null) {
            backdropManager.draw();
        } else {
            // Fallback background color if backdrop manager fails
            ClearBackground(Color(20, 20, 40, 255));
        }
        
        // Draw game board
        if (gameBoard !is null) {
            gameBoard.draw();
        }
        
        // Draw game UI over the backdrop
        DrawTextEx(fontFamily[0], "GAME SCREEN".toStringz(), 
                  Vector2(VIRTUAL_SCREEN_WIDTH / 2 - 120, 100), 32, 1, Colors.WHITE);
        
        // Show which mode was selected
        import data;
        int selectedMode = data.getMostRecentGameMode();
        string modeText = "";
        switch (selectedMode) {
            case 0: modeText = "CLASSIC MODE"; break;
            case 1: modeText = "ACTION MODE"; break;
            case 2: modeText = "ENDLESS MODE"; break;
            case 3: modeText = "PUZZLE MODE"; break;
            default: modeText = "UNKNOWN MODE"; break;
        }
        
        DrawTextEx(fontFamily[1], modeText.toStringz(),
                  Vector2(VIRTUAL_SCREEN_WIDTH / 2 - MeasureTextEx(fontFamily[1], modeText.toStringz(), 28, 1).x / 2, 200), 
                  28, 1, Colors.YELLOW);
        
        // Instructions
        DrawTextEx(fontFamily[2], "Click gems to select them!".toStringz(),
                  Vector2(VIRTUAL_SCREEN_WIDTH / 2 - 200, 300), 20, 1, Colors.LIGHTGRAY);
        
        // Display score and level information
        if (gameBoard !is null) {
            string scoreText = "Score: " ~ gameBoard.getScore().to!string;
            DrawTextEx(fontFamily[1], scoreText.toStringz(),
                      Vector2(50, 100), 24, 1, Colors.WHITE);
            
            string levelText = "Level: " ~ gameBoard.getLevel().to!string;
            DrawTextEx(fontFamily[1], levelText.toStringz(),
                      Vector2(50, 140), 24, 1, Colors.WHITE);
            
            string targetText = "Target: " ~ gameBoard.getTargetScore().to!string;
            DrawTextEx(fontFamily[1], targetText.toStringz(),
                      Vector2(50, 180), 20, 1, Colors.YELLOW);
            
            // Progress bar
            float progress = gameBoard.getProgress();
            Rectangle progressBarBg = Rectangle(50, 220, 200, 20);
            Rectangle progressBarFill = Rectangle(50, 220, 200 * progress, 20);
            
            DrawRectangleRec(progressBarBg, Color(60, 60, 60, 255));
            DrawRectangleRec(progressBarFill, Color(100, 200, 100, 255));
            DrawRectangleLinesEx(progressBarBg, 2, Colors.WHITE);
            
            string progressText = (cast(int)(progress * 100)).to!string ~ "%";
            DrawTextEx(fontFamily[2], progressText.toStringz(),
                      Vector2(55, 245), 16, 1, Colors.WHITE);
        }
        
        // Show current backdrop info
        if (backdropManager !is null) {
            string backdropInfo = "Backdrop: " ~ backdropManager.getCurrentBackdropName() ~ 
                                  " (" ~ (backdropManager.getCurrentBackdropIndex() + 1).to!string ~ 
                                  "/" ~ backdropManager.getBackdropCount().to!string ~ ")";
            DrawTextEx(fontFamily[2], backdropInfo.toStringz(),
                      Vector2(VIRTUAL_SCREEN_WIDTH / 2 - MeasureTextEx(fontFamily[2], backdropInfo.toStringz(), 18, 1).x / 2, 500), 
                      18, 1, Colors.LIME);
        }
        
        // Show wormhole transition working message
        DrawTextEx(fontFamily[2], "Wormhole transition system is working!".toStringz(),
                  Vector2(VIRTUAL_SCREEN_WIDTH / 2 - 200, 550), 18, 1, Colors.LIME);
    }
    
    void unload() {
        if (backdropManager !is null) {
            backdropManager.unload();
        }
        if (gameBoard !is null) {
            gameBoard.unload();
        }
        isInitialized = false;
        fontsFiltered = false;
        writeln("GameScreen unloaded");
    }
}


