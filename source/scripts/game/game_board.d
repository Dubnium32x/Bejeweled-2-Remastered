module game.game_board;

import raylib;
import std.stdio;
import std.random;
import std.conv : to;
import std.math : abs, sqrt, sin, cos;
import std.string : toStringz;

import world.memory_manager;
import world.audio_manager;
import data;

/**
 * Gem types for the game board
 * gem0 = yellow, gem1 = white, gem2 = blue, gem3 = red, gem4 = purple, gem5 = orange, gem6 = green
 */
enum GemType {
    NONE = -1,
    YELLOW = 0,
    WHITE = 1,
    BLUE = 2,
    RED = 3,
    PURPLE = 4,
    ORANGE = 5,
    GREEN = 6
}

/**
 * Individual gem structure
 */
struct Gem {
    GemType type = GemType.NONE;
    bool isSelected = false;
    bool isMatched = false;
    float animationOffset = 0.0f;
    Vector2 position;
    
    // Animation properties for 20-frame gem animation
    int currentFrame = 0;
    float frameTimer = 0.0f;
    bool isAnimating = false; // Whether gem is actively animating
    bool wasClicked = false; // Track if gem was clicked to start animation
    
    // Match clearing animation
    bool isClearing = false; // Whether gem is in clearing animation
    float clearingTimer = 0.0f; // Timer for clearing animation
    float clearingScale = 1.0f; // Scale for shrinking animation
}

/**
 * GameBoard class manages the 8x8 grid of gems
 */
class GameBoard {
    private {
        static const int BOARD_SIZE = 8;
        
        // Game board data
        Gem[BOARD_SIZE][BOARD_SIZE] board;
        
        // Board positioning and sizing
        Vector2 boardPosition;
        float gemSize = 84.0f; // Original gem size - gems are 84x84 with built-in spacing
        float gemSpacing = 0.0f; // No extra spacing - gems already have built-in spacing
        
        // Game speed and animation
        float gameSpeed = 1.0f; // Default game speed multiplier (1.0 = normal speed)
        float fallSpeed; // Consistent pixels per second for all falling gems
        float fallAcceleration; // Acceleration due to gravity (pixels per second squared)
        float initialFallSpeed; // Starting speed for realistic acceleration
        
        // Falling animation tracking
        bool[BOARD_SIZE][BOARD_SIZE] isFalling;
        Vector2[BOARD_SIZE][BOARD_SIZE] targetPositions;
        Vector2[BOARD_SIZE][BOARD_SIZE] currentPositions;
        float[BOARD_SIZE][BOARD_SIZE] fallDelays; // Staggered timing for gradual falling
        float[BOARD_SIZE][BOARD_SIZE] fallVelocities; // Current falling velocity for each gem
        
        // Swap animation tracking
        bool isSwapping = false;
        Vector2 swapGem1Pos = Vector2(-1, -1);
        Vector2 swapGem2Pos = Vector2(-1, -1);
        Vector2 swapGem1Start, swapGem1Target;
        Vector2 swapGem2Start, swapGem2Target;
        float swapAnimationTimer = 0.0f;
        float swapAnimationDuration = 0.3f; // 300ms for swap animation
        bool swapWasValid = false; // Track if swap created matches
        bool needsSwapBack = false; // Track if we need to swap back
        
        // Store the original gem types for animation (before logical swap)
        GemType swapGem1OriginalType = GemType.NONE;
        GemType swapGem2OriginalType = GemType.NONE;
        
        // Textures0
        Texture2D puzzleFrameTexture;
        Texture2D[7] gemTextures; // One for each gem type (gem0.png - gem6.png)
        Texture2D[7] gemAlphaTextures; // Alpha masks for gems (gem0_.png - gem6_.png)
        Texture2D sparkTexture; // Spark effect texture (Spark2.png with alpha)
        
        // Animation constants
        static const int GEM_ANIMATION_FRAMES = 20;
        static const float GEM_FRAME_RATE = 0.025f; // 40 FPS (faster spinning)
        static const float CLEARING_ANIMATION_DURATION = 0.4f; // 400ms for clearing animation
        
        // Memory manager reference
        MemoryManager memoryManager;
        
        // Audio manager reference
        AudioManager audioManager;
        
        // Board state
        bool initialized = false;
        Vector2 selectedGem = Vector2(-1, -1); // Currently selected gem position
        
        // Game state
        int score = 0;
        int level = 1;
        int targetScore = 1000; // Score needed to advance to next level
        int cascadeMultiplier = 1; // Multiplier for cascade matches
        int numberOfSeparateMatches = 0; // Track how many separate match groups we have
        
        // Cascade visual effects
        bool showCascadeEffects = false; // Show special effects for cascade matches
        float cascadeEffectTimer = 0.0f; // Timer for cascade effect animation
        float cascadeEffectDuration = 1.5f; // How long cascade effects last
        float cascadeGlowIntensity = 0.0f; // Intensity of cascade glow effect
        bool[BOARD_SIZE][BOARD_SIZE] isInCurrentCascade; // Track which gems are part of current cascade
        
        // Cascade counter display
        int displayCascadeMultiplier = 1; // The cascade counter shown to player
        bool showCascadeCounter = false; // Whether to show the cascade counter
        float cascadeCounterTimer = 0.0f; // Timer for cascade counter fade out
        float cascadeCounterDuration = 2.5f; // How long counter stays on screen before fading
        
        // Screen shake effects
        bool showScreenShake = false; // Enable screen shake for big cascades
        float screenShakeTimer = 0.0f; // Timer for screen shake
        float screenShakeDuration = 0.8f; // How long screen shake lasts
        float screenShakeIntensity = 0.0f; // Current shake intensity
        Vector2 screenShakeOffset = Vector2(0, 0); // Current shake offset
        
        // Animation state
        bool isProcessingMatches = false; // Prevent input during match processing
        bool isPlayingClearingAnimation = false; // Track if we're playing clearing animations
        
        // Board entrance animation
        bool isPlayingEntranceAnimation = false; // Board sliding in from right
        float entranceAnimationTimer = 0.0f; // Timer for entrance animation
        float entranceAnimationDuration = 0.6f; // Reduced from 1.2f - twice as fast
        Vector2 finalBoardPosition = Vector2(0, 0); // Final position for board
        
        // Gem drop animation (after board entrance)
        bool isPlayingGemDropAnimation = false; // Gems falling from top
        float gemDropAnimationTimer = 0.0f; // Timer for gem drop
        float gemDropAnimationDuration = 1.5f; // How long gem drops take
        float[BOARD_SIZE][BOARD_SIZE] gemDropDelays; // Staggered drop timing
        bool hasPlayedGoAnnouncement = false; // Track if "GO!" has been announced
        
        // Mouse swipe detection
        bool isMouseDown = false;
        Vector2 mouseDownPos = Vector2(0, 0);
        Vector2 mouseCurrentPos = Vector2(0, 0);
        int swipeStartRow = -1;
        int swipeStartCol = -1;
        float minSwipeDistance = 25.0f; // Minimum pixels for a valid swipe
        bool showSwipeReadyCursor = false; // Show special cursor when ready to swipe
        
        // Singleton instance
        __gshared GameBoard _instance;
        
        // Font for cascade counter
        Font cascadeFont;
    }

    /**
     * Get singleton instance
     */
    static GameBoard getInstance() {
        if (_instance is null) {
            synchronized {
                if (_instance is null) {
                    _instance = new GameBoard();
                }
            }
        }
        return _instance;
    }

    /**
     * Initialize the game board
     */
    void initialize() {
        if (initialized) return;
        
        // Calculate speed-dependent values
        fallSpeed = 500.0f * gameSpeed;
        fallAcceleration = 2000.0f * gameSpeed;
        initialFallSpeed = 200.0f * gameSpeed;
        
        memoryManager = MemoryManager.instance();
        
        // Initialize audio manager
        audioManager = AudioManager.getInstance();
        
        // Load textures
        loadTextures();
        
        // Position the board to fit within the puzzle frame interior
        import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT;
        float boardWidth = (gemSize + gemSpacing) * BOARD_SIZE - gemSpacing;
        float boardHeight = (gemSize + gemSpacing) * BOARD_SIZE - gemSpacing;
        
        // Center the board within the puzzle frame
        // Puzzle frame is 750x762, so center the 8x8 board within it
        float frameWidth = 750.0f;
        float frameHeight = 762.0f;
        
        // Position frame more to the right as specified in design notes
        float frameX = VIRTUAL_SCREEN_WIDTH * 0.6f - frameWidth / 2;
        float frameY = VIRTUAL_SCREEN_HEIGHT / 2 - frameHeight / 2;
        
        // Center board within frame (accounting for frame border/padding)
        // With 84x84 gems and no spacing, the board is exactly 672x672 pixels
        // Adjusted padding to align with actual frame tile positions
        float framePaddingX = 43.0f; // Horizontal padding - moved right from 39.0
        float framePaddingY = 30.0f; // Vertical padding - moved up from 45.0
        
        // Store final position and start entrance animation
        finalBoardPosition.x = frameX + framePaddingX;
        finalBoardPosition.y = frameY + framePaddingY;
        
        // Start board off-screen to the right for entrance animation
        boardPosition.x = VIRTUAL_SCREEN_WIDTH + frameWidth; // Start completely off-screen
        boardPosition.y = finalBoardPosition.y; // Same Y position
        
        // Start entrance animation
        isPlayingEntranceAnimation = true;
        entranceAnimationTimer = 0.0f;
        
        // Initialize empty board but don't fill with gems yet
        clearBoard();
        
        // Setup gem drop delays for staggered animation
        import std.random : uniform;
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                // Stagger drops by column and add some randomness
                gemDropDelays[row][col] = col * 0.1f + uniform(0.0f, 0.05f);
            }
        }
        
        initialized = true;
        writeln("GameBoard entrance animation started. Final position: (", finalBoardPosition.x, ", ", finalBoardPosition.y, ")");
    }

    /**
     * Load all required textures
     */
    private void loadTextures() {
        // Load puzzle frame background (main texture)
        Texture2D tempPuzzleFrame = memoryManager.loadTexture("resources/image/FRAME.png");
        Texture2D tempPuzzleAlpha = memoryManager.loadTexture("resources/image/FRAME_.png");
        
        if (tempPuzzleFrame.id == 0) {
            writeln("ERROR: Failed to load FRAME.png");
        } else {
            writeln("GameBoard: Loaded FRAME.png (", tempPuzzleFrame.width, "x", tempPuzzleFrame.height, ")");
        }
        
        if (tempPuzzleAlpha.id == 0) {
            writeln("WARNING: Failed to load FRAME_.png alpha map");
        } else {
            writeln("GameBoard: Loaded FRAME_.png alpha map (", tempPuzzleAlpha.width, "x", tempPuzzleAlpha.height, ")");
        }
        
        // Apply alpha mask to puzzle frame
        if (tempPuzzleFrame.id > 0 && tempPuzzleAlpha.id > 0) {
            puzzleFrameTexture = applyAlphaMask(tempPuzzleFrame, tempPuzzleAlpha);
            writeln("GameBoard: Applied alpha mask to puzzle frame");
        } else {
            puzzleFrameTexture = tempPuzzleFrame; // Fallback to regular texture
        }
        
        // Load gem textures (gem0.png through gem6.png) - these should have 20 frames horizontally
        for (int i = 0; i < 7; i++) {
            string gemPath = "resources/image/gem" ~ i.to!string ~ ".png";
            string gemAlphaPath = "resources/image/gem" ~ i.to!string ~ "_.png";
            
            Texture2D tempGemTexture = memoryManager.loadTexture(gemPath);
            Texture2D tempGemAlpha = memoryManager.loadTexture(gemAlphaPath);
            
            if (tempGemTexture.id == 0) {
                writeln("ERROR: Failed to load ", gemPath);
            } else {
                writeln("GameBoard: Loaded ", gemPath, " (", tempGemTexture.width, "x", tempGemTexture.height, ")");
                writeln("  Expected frame size: ", tempGemTexture.width / GEM_ANIMATION_FRAMES, "x", tempGemTexture.height);
            }
            
            if (tempGemAlpha.id == 0) {
                writeln("WARNING: Failed to load ", gemAlphaPath, " alpha mask - using original texture");
                gemTextures[i] = tempGemTexture; // Fallback to original texture
            } else {
                writeln("GameBoard: Loaded ", gemAlphaPath, " alpha mask");
                // Apply alpha mask to gem texture
                gemTextures[i] = applyAlphaMask(tempGemTexture, tempGemAlpha);
                writeln("GameBoard: Applied alpha mask to gem", i);
            }
            
            // Store alpha textures for potential future use
            gemAlphaTextures[i] = tempGemAlpha;
        }
        
        // Load spark effect texture with alpha mask
        Texture2D tempSparkTexture = memoryManager.loadTexture("resources/image/Spark2.png");
        Texture2D tempSparkAlpha = memoryManager.loadTexture("resources/image/Spark2_.png");
        
        if (tempSparkTexture.id > 0 && tempSparkAlpha.id > 0) {
            sparkTexture = applyAlphaMask(tempSparkTexture, tempSparkAlpha);
            writeln("GameBoard: Loaded spark texture with alpha mask");
        } else {
            sparkTexture = tempSparkTexture; // Fallback without alpha
            writeln("GameBoard: Loaded spark texture without alpha mask");
        }
        
        // Load cascade counter font
        cascadeFont = LoadFont("resources/font/contb.ttf");
    }

    /**
     * Clear the board (set all gems to NONE)
     */
    void clearBoard() {
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                board[row][col].type = GemType.NONE;
                board[row][col].isSelected = false;
                board[row][col].isMatched = false;
                board[row][col].animationOffset = 0.0f;
                board[row][col].currentFrame = 0;
                board[row][col].frameTimer = 0.0f;
                board[row][col].isAnimating = false;
                board[row][col].wasClicked = false;
                
                // Clearing animation properties
                board[row][col].isClearing = false;
                board[row][col].clearingTimer = 0.0f;
                board[row][col].clearingScale = 1.0f;
                
                // Calculate target position
                Vector2 targetPos = Vector2(
                    boardPosition.x + col * (gemSize + gemSpacing),
                    boardPosition.y + row * (gemSize + gemSpacing)
                );
                board[row][col].position = targetPos;
                
                // Initialize falling animation arrays
                isFalling[row][col] = false;
                targetPositions[row][col] = targetPos;
                currentPositions[row][col] = targetPos;
                fallDelays[row][col] = 0.0f;
                fallVelocities[row][col] = 0.0f;
            }
        }
        selectedGem = Vector2(-1, -1);
        isProcessingMatches = false;
        isPlayingClearingAnimation = false;
        cascadeMultiplier = 1;
        
        // Reset swipe detection state
        isMouseDown = false;
        mouseDownPos = Vector2(0, 0);
        mouseCurrentPos = Vector2(0, 0);
        swipeStartRow = -1;
        swipeStartCol = -1;
        showSwipeReadyCursor = false;
        
        // Initialize swap animation state
        isSwapping = false;
        swapAnimationTimer = 0.0f;
        swapWasValid = false;
        needsSwapBack = false;
        
        writeln("GameBoard: Board cleared");
    }

    /**
     * Fill the board with random gems ensuring no initial matches
     */
    void fillBoardWithRandomGems() {
        auto rng = Random(unpredictableSeed);
        clearBoard(); // Start with clean board
        
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                // Generate a valid gem type that doesn't create matches
                GemType validGemType = generateValidGemType(row, col, rng);
                board[row][col].type = validGemType;
                
                // Set position
                board[row][col].position = Vector2(
                    boardPosition.x + col * (gemSize + gemSpacing),
                    boardPosition.y + row * (gemSize + gemSpacing)
                );
                
                // Initialize animation properties - gems start static
                board[row][col].currentFrame = 0; // All gems start at frame 0
                board[row][col].frameTimer = 0.0f;
                board[row][col].isAnimating = false; // Start static
                board[row][col].wasClicked = false;
            }
        }
        
        // Verify no matches exist and ensure valid moves are available
        int matchCount = countAllMatches();
        if (matchCount > 0) {
            writefln("WARNING: Generated board still has %d matches, regenerating...", matchCount);
            fillBoardWithRandomGems(); // Recursive retry
            return;
        }
        
        writeln("GameBoard: Filled board with random gems (no initial matches)");
    }

    /**
     * Generate a valid gem type for a position that won't create matches
     */
    private GemType generateValidGemType(int row, int col, ref Random rng) {
        GemType[] invalidTypes;
        
        // Check for potential horizontal matches (3+ in a row)
        if (col >= 2) {
            // Check if placing same type as previous 2 would create a match
            GemType prev1 = board[row][col-1].type;
            GemType prev2 = board[row][col-2].type;
            if (prev1 != GemType.NONE && prev1 == prev2) {
                invalidTypes ~= prev1;
            }
        }
        
        // Check for potential vertical matches (3+ in a column)
        if (row >= 2) {
            // Check if placing same type as previous 2 would create a match
            GemType prev1 = board[row-1][col].type;
            GemType prev2 = board[row-2][col].type;
            if (prev1 != GemType.NONE && prev1 == prev2) {
                invalidTypes ~= prev1;
            }
        }
        
        // Additional checks for complex patterns (T, L, +, square formations)
        // Check diagonal and nearby patterns that could form problematic shapes
        
        // T-shape prevention: check if this position would complete a T
        if (row >= 1 && col >= 1 && col < BOARD_SIZE - 1) {
            // Top T-shape check
            GemType above = board[row-1][col].type;
            GemType left = board[row][col-1].type;
            GemType right = (col < BOARD_SIZE - 1) ? board[row][col+1].type : GemType.NONE;
            
            if (above != GemType.NONE && above == left && left == right) {
                invalidTypes ~= above;
            }
        }
        
        // L-shape prevention: check corners
        if (row >= 1 && col >= 1) {
            GemType above = board[row-1][col].type;
            GemType left = board[row][col-1].type;
            GemType diagonal = board[row-1][col-1].type;
            
            if (above != GemType.NONE && above == left && left == diagonal) {
                invalidTypes ~= above;
            }
        }
        
        // Generate list of valid gem types (exclude invalid ones)
        GemType[] validTypes;
        for (int i = 0; i < 7; i++) {
            GemType candidate = cast(GemType)i;
            bool isValid = true;
            
            foreach (invalidType; invalidTypes) {
                if (candidate == invalidType) {
                    isValid = false;
                    break;
                }
            }
            
            if (isValid) {
                validTypes ~= candidate;
            }
        }
        
        // Fallback: if no valid types (shouldn't happen), use yellow
        if (validTypes.length == 0) {
            writefln("WARNING: No valid gem types for position (%d, %d), using YELLOW", row, col);
            return GemType.YELLOW;
        }
        
        // Select random valid type
        int randomIndex = uniform(0, cast(int)validTypes.length, rng);
        return validTypes[randomIndex];
    }

    /**
     * Count all matches on the board (for validation)
     */
    private int countAllMatches() {
        int matchCount = 0;
        
        // Check horizontal matches
        for (int row = 0; row < BOARD_SIZE; row++) {
            int consecutiveCount = 1;
            GemType currentType = board[row][0].type;
            
            for (int col = 1; col < BOARD_SIZE; col++) {
                if (board[row][col].type == currentType && currentType != GemType.NONE) {
                    consecutiveCount++;
                } else {
                    if (consecutiveCount >= 3) {
                        writefln("GameBoard: Found horizontal match of %d %s gems at row %d, cols %d-%d", 
                                consecutiveCount, currentType, row, col - consecutiveCount, col - 1);
                        matchCount++;
                    }
                    consecutiveCount = 1;
                    currentType = board[row][col].type;
                }
            }
            // Check final sequence
            if (consecutiveCount >= 3) {
                writefln("GameBoard: Found horizontal match of %d %s gems at row %d, cols %d-%d", 
                        consecutiveCount, currentType, row, BOARD_SIZE - consecutiveCount, BOARD_SIZE - 1);
                matchCount++;
            }
        }
        
        // Check vertical matches
        for (int col = 0; col < BOARD_SIZE; col++) {
            int consecutiveCount = 1;
            GemType currentType = board[0][col].type;
            
            for (int row = 1; row < BOARD_SIZE; row++) {
                if (board[row][col].type == currentType && currentType != GemType.NONE) {
                    consecutiveCount++;
                } else {
                    if (consecutiveCount >= 3) {
                        writefln("GameBoard: Found vertical match of %d %s gems at col %d, rows %d-%d", 
                                consecutiveCount, currentType, col, row - consecutiveCount, row - 1);
                        matchCount++;
                    }
                    consecutiveCount = 1;
                    currentType = board[row][col].type;
                }
            }
            // Check final sequence
            if (consecutiveCount >= 3) {
                writefln("GameBoard: Found vertical match of %d %s gems at col %d, rows %d-%d", 
                        consecutiveCount, currentType, col, BOARD_SIZE - consecutiveCount, BOARD_SIZE - 1);
                matchCount++;
            }
        }
        
        return matchCount;
    }

    /**
     * Get gem at specific board coordinates
     */
    Gem getGem(int row, int col) {
        if (row >= 0 && row < BOARD_SIZE && col >= 0 && col < BOARD_SIZE) {
            return board[row][col];
        }
        return Gem(); // Return empty gem if out of bounds
    }

    /**
     * Set gem at specific board coordinates
     */
    void setGem(int row, int col, GemType type) {
        if (row >= 0 && row < BOARD_SIZE && col >= 0 && col < BOARD_SIZE) {
            board[row][col].type = type;
            board[row][col].position = Vector2(
                boardPosition.x + col * (gemSize + gemSpacing),
                boardPosition.y + row * (gemSize + gemSpacing)
            );
            board[row][col].currentFrame = 0;
            board[row][col].frameTimer = 0.0f;
            board[row][col].isAnimating = false;
            board[row][col].wasClicked = false;
        }
    }

    /**
     * Handle mouse input for gem selection and swipe gestures
     */
    void handleInput() {
        // Debug logging to see what's blocking input
        if (isProcessingMatches) {
            writeln("Input blocked: processing matches");
            return;
        }
        if (isAnyGemFalling()) {
            writeln("Input blocked: gems falling");
            return;
        }
        if (isSwapping) {
            writeln("Input blocked: gems swapping");
            return;
        }
        if (isPlayingClearingAnimation) {
            writeln("Input blocked: clearing animation");
            return;
        }
        
        import app : GetMousePositionVirtual;
        Vector2 mousePos = GetMousePositionVirtual();
        
        // Check if mouse input is within board bounds
        float boardWidth = (gemSize + gemSpacing) * BOARD_SIZE - gemSpacing;
        float boardHeight = (gemSize + gemSpacing) * BOARD_SIZE - gemSpacing;
        bool withinBounds = (mousePos.x >= boardPosition.x && mousePos.x <= boardPosition.x + boardWidth &&
                            mousePos.y >= boardPosition.y && mousePos.y <= boardPosition.y + boardHeight);
        
        // Handle mouse down event
        if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT) && withinBounds) {
            isMouseDown = true;
            mouseDownPos = mousePos;
            mouseCurrentPos = mousePos;
            
            // Calculate which gem was pressed
            int col = cast(int)((mousePos.x - boardPosition.x) / (gemSize + gemSpacing));
            int row = cast(int)((mousePos.y - boardPosition.y) / (gemSize + gemSpacing));
            
            if (row >= 0 && row < BOARD_SIZE && col >= 0 && col < BOARD_SIZE) {
                swipeStartRow = row;
                swipeStartCol = col;
                showSwipeReadyCursor = true; // Show swipe ready indicator
                writefln("GameBoard: Mouse down on gem at (%d, %d) - showing swipe cursor", row, col);
            }
        }
        
        // Handle mouse drag (update current position and check for swipe)
        if (isMouseDown && IsMouseButtonDown(MouseButton.MOUSE_BUTTON_LEFT)) {
            mouseCurrentPos = mousePos;
            
            // Check for swipe while dragging
            if (swipeStartRow >= 0 && swipeStartCol >= 0) {
                float deltaX = mouseCurrentPos.x - mouseDownPos.x;
                float deltaY = mouseCurrentPos.y - mouseDownPos.y;
                float swipeDistance = sqrt(deltaX * deltaX + deltaY * deltaY);
                
                // Trigger swap immediately when swipe threshold is reached
                if (swipeDistance >= minSwipeDistance) {
                    writefln("GameBoard: Swipe threshold reached during drag (%.1f pixels)", swipeDistance);
                    handleSwipeGesture(swipeStartRow, swipeStartCol, deltaX, deltaY);
                    
                    // Reset mouse state after triggering swipe
                    isMouseDown = false;
                    swipeStartRow = -1;
                    swipeStartCol = -1;
                    showSwipeReadyCursor = false; // Hide swipe cursor
                }
            }
        }
        
        // Handle mouse up event
        if (IsMouseButtonReleased(MouseButton.MOUSE_BUTTON_LEFT) && isMouseDown) {
            isMouseDown = false;
            showSwipeReadyCursor = false; // Always hide swipe cursor on mouse up
            
            if (swipeStartRow >= 0 && swipeStartCol >= 0) {
                // Calculate swipe distance
                float deltaX = mouseCurrentPos.x - mouseDownPos.x;
                float deltaY = mouseCurrentPos.y - mouseDownPos.y;
                float swipeDistance = sqrt(deltaX * deltaX + deltaY * deltaY);
                
                // Only handle as click if swipe threshold wasn't reached
                if (swipeDistance < minSwipeDistance) {
                    writefln("GameBoard: Click detected on gem (%d,%d)", swipeStartRow, swipeStartCol);
                    handleGemSelection(swipeStartRow, swipeStartCol);
                } else {
                    writefln("GameBoard: Mouse released after swipe was already processed");
                }
            }
            
            // Reset swipe tracking
            swipeStartRow = -1;
            swipeStartCol = -1;
        }
        
        // Handle click outside bounds - deselect any selected gem
        if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT) && !withinBounds) {
            if (selectedGem.x >= 0 && selectedGem.y >= 0) {
                int row = cast(int)selectedGem.x;
                int col = cast(int)selectedGem.y;
                board[row][col].isSelected = false;
                board[row][col].wasClicked = false;
                selectedGem = Vector2(-1, -1);
                writefln("GameBoard: Clicked outside bounds, deselected gem");
            }
        }
        
        // Reset if mouse leaves the board area while dragging
        if (isMouseDown && !withinBounds) {
            // Don't deselect the gem - just reset the mouse drag state
            // The gem should remain selected so the user can try again
            isMouseDown = false;
            showSwipeReadyCursor = false; // Hide swipe cursor when leaving board
            swipeStartRow = -1;
            swipeStartCol = -1;
            writeln("GameBoard: Mouse left board area, keeping gem selected");
        }
    }

    /**
     * Handle swipe gesture for gem swapping
     */
    private void handleSwipeGesture(int startRow, int startCol, float deltaX, float deltaY) {
        // Determine swipe direction based on the largest delta
        int targetRow = startRow;
        int targetCol = startCol;
        
        if (abs(deltaX) > abs(deltaY)) {
            // Horizontal swipe
            if (deltaX > 0) {
                targetCol = startCol + 1; // Swipe right
            } else {
                targetCol = startCol - 1; // Swipe left
            }
        } else {
            // Vertical swipe
            if (deltaY > 0) {
                targetRow = startRow + 1; // Swipe down
            } else {
                targetRow = startRow - 1; // Swipe up
            }
        }
        
        // Check if target is within bounds
        if (targetRow >= 0 && targetRow < BOARD_SIZE && targetCol >= 0 && targetCol < BOARD_SIZE) {
            writefln("GameBoard: Swipe from (%d,%d) to (%d,%d) - delta=(%.1f, %.1f)", 
                    startRow, startCol, targetRow, targetCol, deltaX, deltaY);
            
            // Gem is already selected from mouse down, just perform the swap
            startSwapAnimation(startRow, startCol, targetRow, targetCol);
        } else {
            writefln("GameBoard: Swipe target (%d,%d) is out of bounds, keeping gem selected", targetRow, targetCol);
            // Keep the gem selected - don't deselect it just because swipe was invalid
            // The user can try swiping in a different direction or click elsewhere
        }
    }

    /**
     * Handle gem selection for classic click-to-select behavior
     */
    private void handleGemSelection(int row, int col) {
        writefln("GameBoard: handleGemSelection called for (%d,%d)", row, col);
        writefln("GameBoard: Current selectedGem = (%.0f, %.0f)", selectedGem.x, selectedGem.y);
        
        // Case 1: No gem currently selected - select this one
        if (selectedGem.x < 0 || selectedGem.y < 0) {
            selectedGem = Vector2(row, col);
            board[row][col].isSelected = true;
            board[row][col].wasClicked = true;
            board[row][col].isAnimating = true;
            board[row][col].currentFrame = 0;
            board[row][col].frameTimer = 0.0f;
            
            // Play gem selection sound
            audioManager.playSFX("resources/audio/sfx/select.ogg");
            
            writefln("GameBoard: Selected first gem at (%d, %d)", row, col);
            return;
        }
        
        // Case 2: Same gem clicked - deselect it
        if (selectedGem.x == row && selectedGem.y == col) {
            board[row][col].isSelected = false;
            board[row][col].wasClicked = false;
            selectedGem = Vector2(-1, -1);
            
            // Play gem deselection sound (softer click)
            audioManager.playSFX("resources/audio/sfx/click2.ogg");
            
            writefln("GameBoard: Deselected gem at (%d, %d)", row, col);
            return;
        }
        
        // Case 3: Different gem clicked - attempt swap
        int prevRow = cast(int)selectedGem.x;
        int prevCol = cast(int)selectedGem.y;
        
        writefln("GameBoard: Attempting swap between (%d,%d) and (%d,%d)", 
                prevRow, prevCol, row, col);
        
        // Clear the first gem's selection
        board[prevRow][prevCol].isSelected = false;
        board[prevRow][prevCol].wasClicked = false;
        selectedGem = Vector2(-1, -1);
        
        // Attempt the swap
        startSwapAnimation(prevRow, prevCol, row, col);
    }

    /**
     * Stop animation for currently animating gem (if any)
     */
    private void stopCurrentGemAnimation() {
        if (swipeStartRow >= 0 && swipeStartCol >= 0) {
            board[swipeStartRow][swipeStartCol].isSelected = false;
            board[swipeStartRow][swipeStartCol].wasClicked = false;
        }
        if (selectedGem.x >= 0 && selectedGem.y >= 0) {
            int row = cast(int)selectedGem.x;
            int col = cast(int)selectedGem.y;
            board[row][col].isSelected = false;
            board[row][col].wasClicked = false;
        }
    }

    /**
     * Select a gem at the given coordinates
     */
    private void selectGem(int row, int col) {
        // If this is the same gem that's already selected, deselect it
        if (selectedGem.x == row && selectedGem.y == col) {
            board[row][col].isSelected = false;
            board[row][col].wasClicked = false;
            // Don't stop animation abruptly - let it complete naturally to frame 0
            // board[row][col].isAnimating = false;  // Removed this line
            selectedGem = Vector2(-1, -1);
            writefln("GameBoard: Deselected gem at (%d, %d) - animation will complete naturally", row, col);
            return;
        }
        
        // If we already have a gem selected, try to swap
        if (selectedGem.x >= 0 && selectedGem.y >= 0) {
            int prevRow = cast(int)selectedGem.x;
            int prevCol = cast(int)selectedGem.y;
            
            // Attempt to swap the gems with animation
            startSwapAnimation(prevRow, prevCol, row, col);
            
            // Clear previous selection but let animation complete naturally
            board[prevRow][prevCol].isSelected = false;
            board[prevRow][prevCol].wasClicked = false;
            // board[prevRow][prevCol].isAnimating = false;  // Let animation complete
            selectedGem = Vector2(-1, -1);
        } else {
            // No gem previously selected, select this one
            selectedGem = Vector2(row, col);
            board[row][col].isSelected = true;
            board[row][col].wasClicked = true;
            board[row][col].isAnimating = true;
            board[row][col].currentFrame = 0;
            board[row][col].frameTimer = 0.0f;
            writefln("GameBoard: Selected gem at (%d, %d) - Type: %s, starting animation", row, col, board[row][col].type);
        }
    }

    /**
     * Clear current gem selection and stop all spinning
     */
    private void clearSelection() {
        if (selectedGem.x >= 0 && selectedGem.y >= 0) {
            int row = cast(int)selectedGem.x;
            int col = cast(int)selectedGem.y;
            board[row][col].isSelected = false;
            board[row][col].wasClicked = false;
            // Don't force stop animation - let it complete naturally
            // board[row][col].isAnimating = false;
            // board[row][col].currentFrame = 0;
        }
        selectedGem = Vector2(-1, -1);
        
        // Also reset swipe state
        isMouseDown = false;
        swipeStartRow = -1;
        swipeStartCol = -1;
    }

    /**
     * Update board animations and logic
     */
    void update(float deltaTime) {
        // Debug key to reset all animation states (R key)
        if (IsKeyPressed(KeyboardKey.KEY_R)) {
            resetAllAnimationStates();
        }
        
        // Debug key to manually trigger cascade check (C key)
        if (IsKeyPressed(KeyboardKey.KEY_C)) {
            writeln("GameBoard: Manual cascade check triggered");
            writefln("GameBoard: isProcessingMatches=%s, isPlayingClearingAnimation=%s, isAnyGemFalling=%s", 
                    isProcessingMatches, isPlayingClearingAnimation, isAnyGemFalling());
            
            int matches = countAllMatches();
            writefln("GameBoard: Found %d matches on manual check", matches);
            
            if (matches > 0 && !isProcessingMatches && !isPlayingClearingAnimation) {
                writeln("GameBoard: Manually starting match processing");
                processMatches();
            }
        }
        
        // Debug key to print board state (B key)
        if (IsKeyPressed(KeyboardKey.KEY_B)) {
            writeln("GameBoard: Current board state:");
            for (int row = 0; row < BOARD_SIZE; row++) {
                string rowStr = "";
                for (int col = 0; col < BOARD_SIZE; col++) {
                    string gemChar = "?";
                    switch (board[row][col].type) {
                        case GemType.YELLOW: gemChar = "Y"; break;
                        case GemType.WHITE: gemChar = "W"; break;
                        case GemType.BLUE: gemChar = "B"; break;
                        case GemType.RED: gemChar = "R"; break;
                        case GemType.PURPLE: gemChar = "P"; break;
                        case GemType.ORANGE: gemChar = "O"; break;
                        case GemType.GREEN: gemChar = "G"; break;
                        case GemType.NONE: gemChar = "."; break;
                        default: gemChar = "?"; break;
                    }
                    rowStr ~= gemChar ~ " ";
                }
                writefln("Row %d: %s", row, rowStr);
            }
        }
        
        // Update entrance animations first (highest priority)
        updateEntranceAnimations(deltaTime);
        
        // Update gem drop animations
        updateGemDropAnimations(deltaTime);
        
        // Only process normal game logic if entrance animations are complete
        if (!isPlayingEntranceAnimation && !isPlayingGemDropAnimation) {
            // Handle input (only if not processing matches or animating)
            handleInput();
            
            // Update swap animations
            updateSwapAnimations(deltaTime);
            
            // Update clearing animations
            updateClearingAnimations(deltaTime);
            
            // Update cascade effects
            updateCascadeEffects(deltaTime);
        }
        
        // Always update falling animations (needed for gem drop animation)
        updateFallingAnimations(deltaTime);
        
        // Always update gem frame animations regardless of game state
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                if (board[row][col].type != GemType.NONE) {
                    // Only animate if the gem is supposed to be animating
                    if (board[row][col].isAnimating) {
                        // Update frame timer
                        board[row][col].frameTimer += deltaTime;
                        
                        // Advance frame if enough time has passed (40 FPS = 0.025s per frame)
                        if (board[row][col].frameTimer >= GEM_FRAME_RATE) {
                            board[row][col].frameTimer -= GEM_FRAME_RATE;
                            board[row][col].currentFrame++;
                            
                            // Handle animation completion
                            if (board[row][col].currentFrame >= GEM_ANIMATION_FRAMES) {
                                // If gem was clicked and is still selected, continue animation
                                if (board[row][col].wasClicked && board[row][col].isSelected) {
                                    board[row][col].currentFrame = 0; // Loop back to start
                                } else {
                                    // Animation cycle complete and gem was deselected, stop animating
                                    board[row][col].isAnimating = false;
                                    board[row][col].currentFrame = 0; // Return to frame 0 (static state)
                                    board[row][col].wasClicked = false;
                                }
                            }
                        }
                    } else {
                        // Gem is static, ensure it stays at frame 0
                        board[row][col].currentFrame = 0;
                        board[row][col].frameTimer = 0.0f;
                    }
                }
            }
        }
        
        // Update clearing animations
        updateClearingAnimations(deltaTime);
    }

    /**
     * Draw the game board and all gems
     */
    void draw() {
        if (!initialized) return;
        
        // Apply screen shake offset if active
        if (showScreenShake) {
            rlPushMatrix();
            rlTranslatef(screenShakeOffset.x, screenShakeOffset.y, 0.0f);
        }
        
        // Draw puzzle frame background with proper alpha blending
        if (puzzleFrameTexture.id > 0) {
            // Calculate frame position based on current board position (for entrance animation)
            float framePaddingX = 43.0f;
            float framePaddingY = 30.0f;
            float frameX = boardPosition.x - framePaddingX;
            float frameY = boardPosition.y - framePaddingY;
            
            // Draw with alpha blending enabled to show background through transparent areas
            DrawTexture(puzzleFrameTexture, cast(int)frameX, cast(int)frameY, Colors.WHITE);
        }
        
        // Draw all gems
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                drawGem(row, col);
            }
        }
        
        // Draw selection highlight
        if (selectedGem.x >= 0 && selectedGem.y >= 0) {
            drawSelectionHighlight(cast(int)selectedGem.x, cast(int)selectedGem.y);
        }
        
        // Draw swipe ready cursor (when mouse is pressed down on a gem)
        if (showSwipeReadyCursor && swipeStartRow >= 0 && swipeStartCol >= 0) {
            drawSwipeReadyCursor(swipeStartRow, swipeStartCol);
        }
        
        // Draw cascade counter
        if (showCascadeCounter && displayCascadeMultiplier > 1) {
            drawCascadeCounter();
        }
        
        // Restore matrix if screen shake was applied
        if (showScreenShake) {
            rlPopMatrix();
        }
    }

    /**
     * Draw a single gem
     */
    private void drawGem(int row, int col) {
        Gem gem = board[row][col];
        
        if (gem.type == GemType.NONE) return;
        
        // Get the gem texture
        int gemIndex = cast(int)gem.type;
        if (gemIndex >= 0 && gemIndex < 7) {
            Texture2D gemTexture = gemTextures[gemIndex];
            
            if (gemTexture.id > 0) {
                // Use the current position (which may be animated for falling or swapping)
                Vector2 pos = gem.position;
                pos.y += gem.animationOffset; // Add any additional animation offset
                
                // Calculate frame dimensions for sprite sheet
                int frameWidth = gemTexture.width / GEM_ANIMATION_FRAMES;
                int frameHeight = gemTexture.height;
                
                // Source rectangle for current animation frame
                Rectangle sourceRect = Rectangle(
                    gem.currentFrame * frameWidth,
                    0,
                    frameWidth,
                    frameHeight
                );
                
                // Calculate scale for clearing animation
                float scale = gem.clearingScale;
                float scaledGemSize = gemSize * scale;
                
                // Center the scaled gem
                float offsetX = (gemSize - scaledGemSize) * 0.5f;
                float offsetY = (gemSize - scaledGemSize) * 0.5f;
                
                // Destination rectangle (scale to gem size with clearing scale)
                Rectangle destRect = Rectangle(
                    pos.x + offsetX,
                    pos.y + offsetY,
                    scaledGemSize,
                    scaledGemSize
                );
                
                // Apply transparency during clearing
                Color tint = Colors.WHITE;
                if (gem.isClearing) {
                    tint.a = cast(ubyte)(255 * scale); // Fade out as it shrinks
                }
                
                // Draw gem with proper alpha blending and scaling
                DrawTexturePro(gemTexture, sourceRect, destRect, Vector2(0, 0), 0.0f, tint);
                
                // Draw cascade spark effect if this gem is part of current cascade
                if (showCascadeEffects && isInCurrentCascade[row][col] && sparkTexture.id > 0) {
                    drawCascadeSpark(pos, scaledGemSize, row, col);
                }
            }
        }
    }

    /**
     * Draw selection highlight around selected gem
     */
    private void drawSelectionHighlight(int row, int col) {
        Vector2 pos = board[row][col].position;
        
        // Draw a glowing border around the selected gem
        Rectangle gemRect = Rectangle(pos.x - 2, pos.y - 2, gemSize + 4, gemSize + 4);
        DrawRectangleLinesEx(gemRect, 3, Colors.YELLOW);
        
        // Add a subtle glow effect
        DrawRectangleLinesEx(Rectangle(pos.x - 4, pos.y - 4, gemSize + 8, gemSize + 8), 1, Color(255, 255, 0, 128));
    }

    /**
     * Draw swipe ready cursor around gem when mouse is pressed down
     */
    private void drawSwipeReadyCursor(int row, int col) {
        Vector2 pos = board[row][col].position;
        
        // Draw a pulsing bright border to indicate ready for swiping
        Rectangle gemRect = Rectangle(pos.x - 3, pos.y - 3, gemSize + 6, gemSize + 6);
        DrawRectangleLinesEx(gemRect, 4, Colors.WHITE);
        
        // Add a brighter glow effect for swipe ready state
        DrawRectangleLinesEx(Rectangle(pos.x - 6, pos.y - 6, gemSize + 12, gemSize + 12), 2, Color(255, 255, 255, 180));
        
        // Add inner highlight for extra visibility
        DrawRectangleLinesEx(Rectangle(pos.x - 1, pos.y - 1, gemSize + 2, gemSize + 2), 1, Color(255, 255, 255, 200));
    }

    /**
     * Draw cascade spark effect around a gem
     */
    private void drawCascadeSpark(Vector2 pos, float gemSize, int row, int col) {
        if (cascadeGlowIntensity <= 0.0f) return;
        
        // Calculate spark color based on cascade multiplier
        Color sparkColor;
        if (cascadeMultiplier >= 5) {
            sparkColor = Color(255, 0, 255, cast(ubyte)(255 * cascadeGlowIntensity)); // Purple for huge cascades
        } else if (cascadeMultiplier >= 4) {
            sparkColor = Color(255, 165, 0, cast(ubyte)(255 * cascadeGlowIntensity)); // Orange for big cascades  
        } else if (cascadeMultiplier >= 3) {
            sparkColor = Color(255, 0, 0, cast(ubyte)(255 * cascadeGlowIntensity)); // Red for medium cascades
        } else {
            sparkColor = Color(0, 255, 255, cast(ubyte)(255 * cascadeGlowIntensity)); // Cyan for small cascades
        }
        
        // Calculate spark size and position
        float sparkSize = gemSize * 1.5f; // Make spark bigger than gem
        Vector2 sparkPos = Vector2(
            pos.x - (sparkSize - gemSize) * 0.5f,
            pos.y - (sparkSize - gemSize) * 0.5f
        );
        
        // Add some animation offset based on time and position for variety
        float timeOffset = cascadeEffectTimer * 3.0f + row * 0.3f + col * 0.5f;
        sparkPos.x += sin(timeOffset) * 3.0f;
        sparkPos.y += cos(timeOffset * 1.2f) * 3.0f;
        
        // Draw the spark texture with color tint
        Rectangle sparkSource = Rectangle(0, 0, sparkTexture.width, sparkTexture.height);
        Rectangle sparkDest = Rectangle(sparkPos.x, sparkPos.y, sparkSize, sparkSize);
        
        DrawTexturePro(sparkTexture, sparkSource, sparkDest, Vector2(0, 0), 0.0f, sparkColor);
    }

    /**
     * Draw cascade counter display
     */
    private void drawCascadeCounter() {
        import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT;
        
        // Position counter on the left side of screen, vertically centered
        float counterX = 50;
        float counterY = VIRTUAL_SCREEN_HEIGHT * 0.4f;
        
        // Calculate fade alpha based on timer
        float fadeProgress = cascadeCounterTimer / cascadeCounterDuration;
        float alpha = 1.0f;
        
        // Start fading in the last 0.8 seconds
        if (fadeProgress > 0.7f) {
            float fadeStart = 0.7f;
            alpha = 1.0f - ((fadeProgress - fadeStart) / (1.0f - fadeStart));
            alpha = alpha * alpha; // Ease out
        }
        
        // Determine color based on cascade multiplier
        Color textColor;
        if (displayCascadeMultiplier >= 5) {
            textColor = Color(255, 0, 255, cast(ubyte)(255 * alpha)); // Purple
        } else if (displayCascadeMultiplier >= 4) {
            textColor = Color(255, 165, 0, cast(ubyte)(255 * alpha)); // Orange
        } else if (displayCascadeMultiplier >= 3) {
            textColor = Color(255, 0, 0, cast(ubyte)(255 * alpha)); // Red
        } else {
            textColor = Color(0, 255, 255, cast(ubyte)(255 * alpha)); // Cyan
        }
        
        // Declare text variables before use
        string cascadeText = "CASCADE";
        int fontSize = 36;
        string multiplierText = "x" ~ to!string(displayCascadeMultiplier);
        int multiplierSize = 48;
        
        // Draw large "CASCADE" text
        DrawTextEx(cascadeFont, cascadeText.toStringz, Vector2(counterX, counterY), fontSize, 0, textColor);
        // Draw even larger multiplier text below
        DrawTextEx(cascadeFont, multiplierText.toStringz, Vector2(counterX + 20, counterY + 40), multiplierSize, 0, textColor);
        
        // Add a subtle glow effect for extra impact
        Color glowColor = Color(textColor.r, textColor.g, textColor.b, cast(ubyte)(128 * alpha));
        DrawTextEx(cascadeFont, cascadeText.toStringz, Vector2(counterX - 1, counterY - 1), fontSize, 0, glowColor);
        DrawTextEx(cascadeFont, cascadeText.toStringz, Vector2(counterX + 1, counterY + 1), fontSize, 0, glowColor);
        DrawTextEx(cascadeFont, multiplierText.toStringz, Vector2(counterX + 19, counterY + 39), multiplierSize, 0, glowColor);
        DrawTextEx(cascadeFont, multiplierText.toStringz, Vector2(counterX + 21, counterY + 41), multiplierSize, 0, glowColor);
    }

    /**
     * Apply alpha mask to a color texture
     */
    private Texture2D applyAlphaMask(Texture2D colorTexture, Texture2D alphaMask) {
        // Get image data from both textures
        Image colorImage = LoadImageFromTexture(colorTexture);
        Image alphaImage = LoadImageFromTexture(alphaMask);
        
        // Ensure both images are the same size
        if (colorImage.width != alphaImage.width || colorImage.height != alphaImage.height) {
            writeln("WARNING: Color texture and alpha mask have different dimensions");
            ImageResize(&alphaImage, colorImage.width, colorImage.height);
        }
        
        // Convert images to RGBA format
        ImageFormat(&colorImage, PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
        ImageFormat(&alphaImage, PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
        
        // Apply alpha mask
        Color* colorPixels = cast(Color*)colorImage.data;
        Color* alphaPixels = cast(Color*)alphaImage.data;
        
        int pixelCount = colorImage.width * colorImage.height;
        for (int i = 0; i < pixelCount; i++) {
            // Use the red channel of the alpha mask as the alpha value
            colorPixels[i].a = alphaPixels[i].r;
        }
        
        // Create new texture from the modified image
        Texture2D result = LoadTextureFromImage(colorImage);
        
        // Clean up
        UnloadImage(colorImage);
        UnloadImage(alphaImage);
        
        return result;
    }

    /**
     * Get board size
     */
    int getBoardSize() {
        return BOARD_SIZE;
    }

    /**
     * Get gem size
     */
    float getGemSize() {
        return gemSize;
    }

    /**
     * Get board position
     */
    Vector2 getBoardPosition() {
        return boardPosition;
    }

    /**
     * Get current score
     */
    int getScore() {
        return score;
    }

    /**
     * Get current level
     */
    int getLevel() {
        return level;
    }

    /**
     * Get target score for current level
     */
    int getTargetScore() {
        return targetScore;
    }

    /**
     * Get progress percentage (0.0 to 1.0)
     */
    float getProgress() {
        return cast(float)score / cast(float)targetScore;
    }

    /**
     * Set game speed multiplier
     */
    void setGameSpeed(float speed) {
        gameSpeed = speed;
        writefln("GameBoard: Game speed set to %.2f", speed);
    }

    /**
     * Advance to next level
     */
    void advanceLevel() {
        if (score >= targetScore) {
            level++;
            targetScore = level * 1000 + (level - 1) * 500; // Increasing difficulty
            writefln("GameBoard: Advanced to level %d (target: %d)", level, targetScore);
        }
    }

    /**
     * Unload all resources
     */
    void unload() {
        // Memory manager will handle texture cleanup
        initialized = false;
        writeln("GameBoard unloaded");
    }

    /**
     * Check if the board has any valid moves available
     */
    bool hasValidMoves() {
        // Check all possible swaps between adjacent gems
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                // Check right neighbor
                if (col < BOARD_SIZE - 1) {
                    if (wouldCreateMatch(row, col, row, col + 1)) {
                        return true;
                    }
                }
                
                // Check bottom neighbor
                if (row < BOARD_SIZE - 1) {
                    if (wouldCreateMatch(row, col, row + 1, col)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
     * Check if swapping two gems would create a match
     */
    private bool wouldCreateMatch(int row1, int col1, int row2, int col2) {
        // Temporarily swap the gems
        GemType temp = board[row1][col1].type;
        board[row1][col1].type = board[row2][col2].type;
        board[row2][col2].type = temp;
        
        // Check if either position now creates a match
        bool hasMatch = (checkMatchAtPosition(row1, col1) || checkMatchAtPosition(row2, col2));
        
        // Swap back
        temp = board[row1][col1].type;
        board[row1][col1].type = board[row2][col2].type;
        board[row2][col2].type = temp;
        
        return hasMatch;
    }

    /**
     * Check if a specific position creates a match
     */
    private bool checkMatchAtPosition(int row, int col) {
        GemType gemType = board[row][col].type;
        if (gemType == GemType.NONE) return false;
        
        // Check horizontal match
        int horizontalCount = 1;
        
        // Count left
        for (int c = col - 1; c >= 0 && board[row][c].type == gemType; c--) {
            horizontalCount++;
        }
        
        // Count right
        for (int c = col + 1; c < BOARD_SIZE && board[row][c].type == gemType; c++) {
            horizontalCount++;
        }
        
        if (horizontalCount >= 3) return true;
        
        // Check vertical match
        int verticalCount = 1;
        
        // Count up
        for (int r = row - 1; r >= 0 && board[r][col].type == gemType; r--) {
            verticalCount++;
        }
        
        // Count down
        for (int r = row + 1; r < BOARD_SIZE && board[r][col].type == gemType; r++) {
            verticalCount++;
        }
        
        if (verticalCount >= 3) return true;
        
        // In arranged mode, also check for 2x2 square matches
        if (currentGameMode == GameMode.ARRANGED) {
            // Check all possible 2x2 squares that this gem could be part of
            for (int topRow = row - 1; topRow <= row; topRow++) {
                for (int leftCol = col - 1; leftCol <= col; leftCol++) {
                    // Make sure the 2x2 square is within bounds
                    if (topRow >= 0 && leftCol >= 0 && 
                        topRow + 1 < BOARD_SIZE && leftCol + 1 < BOARD_SIZE) {
                        
                        // Check if all 4 gems in this 2x2 are the same
                        if (board[topRow][leftCol].type == gemType &&
                            board[topRow][leftCol + 1].type == gemType &&
                            board[topRow + 1][leftCol].type == gemType &&
                            board[topRow + 1][leftCol + 1].type == gemType) {
                            return true;
                        }
                    }
                }
            }
        }
        
        return false;
    }

    /**
     * Generate a board with guaranteed valid moves
     */
    void generatePlayableBoard() {
        int attempts = 0;
        const int maxAttempts = 50;
        
        do {
            fillBoardWithRandomGems();
            attempts++;
            
            if (attempts >= maxAttempts) {
                writeln("WARNING: Could not generate board with valid moves after 50 attempts");
                break;
            }
        } while (!hasValidMoves());
        
        writefln("GameBoard: Generated playable board with valid moves (attempt %d)", attempts);
    }

    /**
     * Start a swap animation between two gems
     */
    private void startSwapAnimation(int row1, int col1, int row2, int col2) {
        // Check if gems are adjacent
        if (!areAdjacent(row1, col1, row2, col2)) {
            writefln("GameBoard: Gems at (%d,%d) and (%d,%d) are not adjacent", row1, col1, row2, col2);
            return;
        }
        
        // Store original gem types BEFORE any swapping
        swapGem1OriginalType = board[row1][col1].type;
        swapGem2OriginalType = board[row2][col2].type;
        
        // Test if swap would create matches (temporarily swap to test)
        swapGems(row1, col1, row2, col2);
        bool createsMatch = (checkMatchAtPosition(row1, col1) || checkMatchAtPosition(row2, col2));
        
        // Always swap back for now - we'll handle the logical state later
        swapGems(row1, col1, row2, col2); // Swap back to original state
        
        // Set up swap animation
        isSwapping = true;
        swapGem1Pos = Vector2(row1, col1);
        swapGem2Pos = Vector2(row2, col2);
        swapWasValid = createsMatch;
        needsSwapBack = !createsMatch;
        swapAnimationTimer = 0.0f;
        
        // Store starting positions (current positions)
        swapGem1Start = Vector2(
            boardPosition.x + col1 * (gemSize + gemSpacing),
            boardPosition.y + row1 * (gemSize + gemSpacing)
        );
        swapGem2Start = Vector2(
            boardPosition.x + col2 * (gemSize + gemSpacing),
            boardPosition.y + row2 * (gemSize + gemSpacing)
        );
        
        // Store target positions (where each gem should end up)
        swapGem1Target = Vector2(
            boardPosition.x + col2 * (gemSize + gemSpacing),
            boardPosition.y + row2 * (gemSize + gemSpacing)
        );
        swapGem2Target = Vector2(
            boardPosition.x + col1 * (gemSize + gemSpacing),
            boardPosition.y + row1 * (gemSize + gemSpacing)
        );
        
        // Play appropriate sound effect for the swap
        if (createsMatch) {
            // Valid swap sound - use a softer swap sound
            audioManager.playSFX("resources/audio/sfx/click2.ogg");
        } else {
            // Invalid swap sound - softer error sound
            audioManager.playSFX("resources/audio/sfx/bad2.ogg");
        }
        
        writefln("GameBoard: Started swap animation between (%d,%d) and (%d,%d) - Valid: %s", 
                row1, col1, row2, col2, createsMatch);
    }

    /**
     * Update swap animations
     */
    private void updateSwapAnimations(float deltaTime) {
        if (!isSwapping) return;
        
        swapAnimationTimer += deltaTime;
        float progress = swapAnimationTimer / swapAnimationDuration;
        
        // Debug output
        if (needsSwapBack) {
            //writefln("Invalid swap animation: timer=%.3f, progress=%.3f, needsSwapBack=%s", swapAnimationTimer, progress, needsSwapBack);
        }
        
        if (progress >= 1.0f) {
            // First animation phase complete
            if (needsSwapBack) {
                // Invalid swap, need to animate back to original positions
                float backProgress = (swapAnimationTimer - swapAnimationDuration) / swapAnimationDuration;                    if (backProgress >= 1.0f) {
                        // Swap back animation complete - gems are already in correct positions
                        int row1 = cast(int)swapGem1Pos.x;
                        int col1 = cast(int)swapGem1Pos.y;
                        int row2 = cast(int)swapGem2Pos.x;
                        int col2 = cast(int)swapGem2Pos.y;
                        
                        // Reset visual positions to original grid positions
                        board[row1][col1].position = Vector2(
                            boardPosition.x + col1 * (gemSize + gemSpacing),
                            boardPosition.y + row1 * (gemSize + gemSpacing)
                        );
                        board[row2][col2].position = Vector2(
                            boardPosition.x + col2 * (gemSize + gemSpacing),
                            boardPosition.y + row2 * (gemSize + gemSpacing)
                        );
                        
                        // Ensure gems are not in any special states
                        board[row1][col1].isSelected = false;
                        board[row1][col1].isAnimating = false;
                        board[row1][col1].wasClicked = false;
                        board[row2][col2].isSelected = false;
                        board[row2][col2].isAnimating = false;
                        board[row2][col2].wasClicked = false;
                        
                        // Reset animation state completely
                        isSwapping = false;
                        needsSwapBack = false;
                        swapAnimationTimer = 0.0f;
                        swapGem1Pos = Vector2(-1, -1);
                        swapGem2Pos = Vector2(-1, -1);
                        swapGem1OriginalType = GemType.NONE;
                        swapGem2OriginalType = GemType.NONE;
                        
                        writeln("GameBoard: Invalid swap animation complete - all state reset, input should work now");
                    } else {
                    // Interpolate back to original positions
                    int row1 = cast(int)swapGem1Pos.x;
                    int col1 = cast(int)swapGem1Pos.y;
                    int row2 = cast(int)swapGem2Pos.x;
                    int col2 = cast(int)swapGem2Pos.y;
                    
                    // Smooth easing for back animation
                    float easedProgress = easeInOutQuad(backProgress);
                    
                    board[row1][col1].position = Vector2(
                        swapGem1Target.x + (swapGem1Start.x - swapGem1Target.x) * easedProgress,
                        swapGem1Target.y + (swapGem1Start.y - swapGem1Target.y) * easedProgress
                    );
                    board[row2][col2].position = Vector2(
                        swapGem2Target.x + (swapGem2Start.x - swapGem2Target.x) * easedProgress,
                        swapGem2Target.y + (swapGem2Start.y - swapGem2Target.y) * easedProgress
                    );
                }
            } else {
                // Valid swap completed - now perform the logical swap
                int row1 = cast(int)swapGem1Pos.x;
                int col1 = cast(int)swapGem1Pos.y;
                int row2 = cast(int)swapGem2Pos.x;
                int col2 = cast(int)swapGem2Pos.y;
                
                // Perform the logical swap now that animation is complete
                swapGems(row1, col1, row2, col2);
                
                // Set final visual positions to match the grid
                board[row1][col1].position = Vector2(
                    boardPosition.x + col1 * (gemSize + gemSpacing),
                    boardPosition.y + row1 * (gemSize + gemSpacing)
                );
                board[row2][col2].position = Vector2(
                    boardPosition.x + col2 * (gemSize + gemSpacing),
                    boardPosition.y + row2 * (gemSize + gemSpacing)
                );
                
                // Ensure gems are not in any special states
                board[row1][col1].isSelected = false;
                board[row1][col1].isAnimating = false;
                board[row1][col1].wasClicked = false;
                board[row2][col2].isSelected = false;
                board[row2][col2].isAnimating = false;
                board[row2][col2].wasClicked = false;
                
                // Reset animation state completely BEFORE processing matches
                isSwapping = false;
                swapAnimationTimer = 0.0f;
                swapGem1Pos = Vector2(-1, -1);
                swapGem2Pos = Vector2(-1, -1);
                swapGem1OriginalType = GemType.NONE;
                swapGem2OriginalType = GemType.NONE;
                
                writeln("GameBoard: Valid swap animation completed, processing matches");
                processMatches();
            }
        } else {
            // Animation in progress
            int row1 = cast(int)swapGem1Pos.x;
            int col1 = cast(int)swapGem1Pos.y;
            int row2 = cast(int)swapGem2Pos.x;
            int col2 = cast(int)swapGem2Pos.y;
            
            // Smooth easing
            float easedProgress = easeInOutQuad(progress);
            
            // Animate the gems to their target positions
            // Gem 1 moves from start to target
            Vector2 gem1CurrentPos = Vector2(
                swapGem1Start.x + (swapGem1Target.x - swapGem1Start.x) * easedProgress,
                swapGem1Start.y + (swapGem1Target.y - swapGem1Start.y) * easedProgress
            );
            
            // Gem 2 moves from start to target  
            Vector2 gem2CurrentPos = Vector2(
                swapGem2Start.x + (swapGem2Target.x - swapGem2Start.x) * easedProgress,
                swapGem2Start.y + (swapGem2Target.y - swapGem2Start.y) * easedProgress
            );
            
            // Update positions - the gem that was originally at pos1 gets pos1's animated position
            board[row1][col1].position = gem1CurrentPos;
            board[row2][col2].position = gem2CurrentPos;
        }
    }

    /**
     * Easing function for smooth animation
     */
    private float easeInOutQuad(float t) {
        return t < 0.5f ? 2.0f * t * t : 1.0f - 2.0f * (1.0f - t) * (1.0f - t);
    }

    /**
     * Check if two positions are adjacent (horizontally or vertically)
     */
    private bool areAdjacent(int row1, int col1, int row2, int col2) {
        int rowDiff = abs(row1 - row2);
        int colDiff = abs(col1 - col2);
        
        // Adjacent means exactly one position difference in either row or column, but not both
        return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
    }

    /**
     * Swap two gems
     */
    private void swapGems(int row1, int col1, int row2, int col2) {
        GemType temp = board[row1][col1].type;
        board[row1][col1].type = board[row2][col2].type;
        board[row2][col2].type = temp;
        
        writefln("GameBoard: Swapped gems at (%d,%d) and (%d,%d)", row1, col1, row2, col2);
    }

    /**
     * Process all matches on the board
     */
    private void processMatches() {
        // Prevent multiple simultaneous processing
        if (isProcessingMatches && isPlayingClearingAnimation) {
            writeln("GameBoard: Already processing matches AND clearing, ignoring duplicate call");
            return;
        }
        
        if (!isProcessingMatches) {
            writeln("GameBoard: Starting new match processing sequence");
        }
        
        isProcessingMatches = true;
        
        // Clear any current selection to stop spinning gems
        clearSelection();
        
        // Mark all matching gems
        int matchedGemCount = markMatches();
        
        if (matchedGemCount > 0) {
            writefln("GameBoard: Found %d matched gems, starting clearing animation", matchedGemCount);
            // Start clearing animation instead of immediately removing gems
            startClearingAnimation();
        } else {
            // No matches, reset cascade multiplier and allow input
            cascadeMultiplier = 1;
            isProcessingMatches = false;
            writeln("GameBoard: No matches found, resetting processing state");
        }
    }

    /**
     * Calculate score for matched gems
     */
    private int calculateMatchScore(int gemCount) {
        // Base score increases by 5 points per level
        // Level 1: 10pts base, Level 2: 15pts base, etc.
        int baseScore = 5 + (level * 5);
        
        // Match size multiplier: 3 gems = 1x, 4 gems = 2x, 5+ gems = 4x, etc.
        int sizeMultiplier = 1;
        if (gemCount == 4) sizeMultiplier = 2;
        else if (gemCount == 5) sizeMultiplier = 4;
        else if (gemCount >= 6) sizeMultiplier = 4 + (gemCount - 5) * 2; // 6, 8, 10, etc.
        
        int finalScore = baseScore * sizeMultiplier * cascadeMultiplier;
        
        writefln("GameBoard: %d gems, Level %d (base: %d), size mult: %dx, cascade mult: %dx = %d points", 
                gemCount, level, baseScore, sizeMultiplier, cascadeMultiplier, finalScore);
        
        return finalScore;
    }

    /**
     * Mark all gems that are part of matches
     */
    private int markMatches() {
        int totalMatched = 0;
        numberOfSeparateMatches = 0; // Reset counter
        
        // Reset match flags
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                board[row][col].isMatched = false;
            }
        }
        
        if (currentGameMode == GameMode.ARRANGED) {
            // In Arranged mode, look for BOTH traditional matches AND 2x2 square matches
            totalMatched = markTraditionalMatches();  // First mark traditional 3+ matches
            totalMatched += mark2x2Squares();         // Then add 2x2 square matches
        } else {
            // In Original mode, look for traditional 3+ gem matches only
            totalMatched = markTraditionalMatches();
        }
        
        writefln("GameBoard: Found %d separate matches totaling %d matched gems (mode: %s)", 
                numberOfSeparateMatches, totalMatched, currentGameMode);
        return totalMatched;
    }
    
    /**
     * Mark 2x2 square matches for Arranged mode
     */
    private int mark2x2Squares() {
        int totalMatched = 0;
        
        // Check all possible 2x2 squares
        for (int row = 0; row < BOARD_SIZE - 1; row++) {
            for (int col = 0; col < BOARD_SIZE - 1; col++) {
                GemType topLeft = board[row][col].type;
                GemType topRight = board[row][col + 1].type;
                GemType bottomLeft = board[row + 1][col].type;
                GemType bottomRight = board[row + 1][col + 1].type;
                
                // Check if all 4 gems are the same type and not empty
                if (topLeft != GemType.NONE && 
                    topLeft == topRight && 
                    topLeft == bottomLeft && 
                    topLeft == bottomRight) {
                    
                    numberOfSeparateMatches++; // Count this as a separate match
                    
                    // Mark all 4 gems in this square if not already matched
                    if (!board[row][col].isMatched) {
                        board[row][col].isMatched = true;
                        totalMatched++;
                    }
                    if (!board[row][col + 1].isMatched) {
                        board[row][col + 1].isMatched = true;
                        totalMatched++;
                    }
                    if (!board[row + 1][col].isMatched) {
                        board[row + 1][col].isMatched = true;
                        totalMatched++;
                    }
                    if (!board[row + 1][col + 1].isMatched) {
                        board[row +  1][col + 1].isMatched = true;
                        totalMatched++;
                    }
                    
                   
                    
                    writefln("GameBoard: Marked 2x2 square match of %s gems at (%d,%d)", 
                            topLeft, row, col);
                }
            }
        }
        
        return totalMatched;
    }
    
    /**
     * Mark traditional 3+ gem line matches for Original mode
     */
    /**
     * Mark traditional 3+ gem line matches for Original mode
     */
    private int markTraditionalMatches() {
        int totalMatched = 0;
        
        // Mark horizontal matches
        for (int row = 0; row < BOARD_SIZE; row++) {
            int consecutiveCount = 1;
            GemType currentType = board[row][0].type;
            int startCol = 0;
            
            for (int col = 1; col <= BOARD_SIZE; col++) {
                GemType nextType = (col < BOARD_SIZE) ? board[row][col].type : GemType.NONE;
                
                if (nextType == currentType && currentType != GemType.NONE) {
                    consecutiveCount++;
                } else {
                    // End of sequence, check if it's a match
                    if (consecutiveCount >= 3 && currentType != GemType.NONE) {
                        numberOfSeparateMatches++; // Count this match
                        // Mark all gems in this match
                        for (int c = startCol; c < startCol + consecutiveCount; c++) {
                            if (!board[row][c].isMatched) {
                                board[row][c].isMatched = true;
                                totalMatched++;
                            }
                        }
                        writefln("GameBoard: Marked horizontal match of %d %s gems at row %d, cols %d-%d", 
                                consecutiveCount, currentType, row, startCol, startCol + consecutiveCount - 1);
                    }
                    
                    // Start new sequence
                    consecutiveCount = 1;
                    currentType = nextType;
                    startCol = col;
                }
            }
        }
        
        // Mark vertical matches
        for (int col = 0; col < BOARD_SIZE; col++) {
            int consecutiveCount = 1;
            GemType currentType = board[0][col].type;
            int startRow = 0;
            
            for (int row = 1; row <= BOARD_SIZE; row++) {
                GemType nextType = (row < BOARD_SIZE) ? board[row][col].type : GemType.NONE;
                
                if (nextType == currentType && currentType != GemType.NONE) {
                    consecutiveCount++;
                } else {
                    // End of sequence, check if it's a match
                    if (consecutiveCount >= 3 && currentType != GemType.NONE) {
                        numberOfSeparateMatches++; // Count this match
                        // Mark all gems in this match
                        for (int r = startRow; r < startRow + consecutiveCount; r++) {
                            if (!board[r][col].isMatched) {
                                board[r][col].isMatched = true;
                                totalMatched++;
                            }
                        }
                        writefln("GameBoard: Marked vertical match of %d %s gems at col %d, rows %d-%d", 
                                consecutiveCount, currentType, col, startRow, startRow + consecutiveCount - 1);
                    }
                    
                    // Start new sequence
                    consecutiveCount = 1;
                    currentType = nextType;
                    startRow = row;
                }
            }
        }
        
        return totalMatched;
    }

    /**
     * Remove all gems marked for matching
     */
    private void removeMarkedGems() {
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                if (board[row][col].isMatched) {
                    board[row][col].type = GemType.NONE;
                    board[row][col].isMatched = false;
                    board[row][col].isSelected = false;
                    board[row][col].isAnimating = false;
                    board[row][col].wasClicked = false;
                    board[row][col].currentFrame = 0;
                }
            }
        }
        writeln("GameBoard: Removed matched gems");
    }

    /**
     * Start falling animation for gems after matches are removed
     */
    private void startFallingAnimation() {
        // First apply gravity to determine final positions
        applyGravityWithAnimation();
        
        // Fill empty spaces from the top
        fillEmptySpacesFromTop();
    }

    /**
     * Apply gravity with proper physics to prevent gem overlap
     */
    private void applyGravityWithAnimation() {
        for (int col = 0; col < BOARD_SIZE; col++) {
            // Process each column from bottom to top
            int writePos = BOARD_SIZE - 1;
            
            // First pass: move existing gems down
            for (int readPos = BOARD_SIZE - 1; readPos >= 0; readPos--) {
                if (board[readPos][col].type != GemType.NONE && !board[readPos][col].isMatched) {
                    if (writePos != readPos) {
                        // Move gem down
                        board[writePos][col] = board[readPos][col];
                        board[readPos][col].type = GemType.NONE;
                        
                        // Set up falling animation with stacked physics
                        Vector2 startPos = Vector2(
                            boardPosition.x + col * (gemSize + gemSpacing),
                            boardPosition.y + readPos * (gemSize + gemSpacing)
                        );
                        Vector2 endPos = Vector2(
                            boardPosition.x + col * (gemSize + gemSpacing),
                            boardPosition.y + writePos * (gemSize + gemSpacing)
                        );
                        
                        currentPositions[writePos][col] = startPos;
                        targetPositions[writePos][col] = endPos;
                        board[writePos][col].position = startPos;
                        isFalling[writePos][col] = true;
                        fallDelays[writePos][col] = 0.0f; // No delay for existing gems
                        fallVelocities[writePos][col] = initialFallSpeed; // Start with slow speed
                        
                        // Clear old position
                        isFalling[readPos][col] = false;
                        fallDelays[readPos][col] = 0.0f;
                        fallVelocities[readPos][col] = 0.0f;
                    } else {
                        // Gem staying in place, ensure positions are correct
                        Vector2 correctPos = Vector2(
                            boardPosition.x + col * (gemSize + gemSpacing),
                            boardPosition.y + writePos * (gemSize + gemSpacing)
                        );
                        currentPositions[writePos][col] = correctPos;
                        targetPositions[writePos][col] = correctPos;
                        board[writePos][col].position = correctPos;
                        isFalling[writePos][col] = false;
                        fallDelays[writePos][col] = 0.0f;
                        fallVelocities[writePos][col] = 0.0f;
                    }
                    writePos--;
                }
            }
        }
        writeln("GameBoard: Applied gravity with realistic acceleration physics");
    }

    /**
     * Fill empty spaces from the top with new gems
     */
    private void fillEmptySpacesFromTop() {
        auto rng = Random(unpredictableSeed);
        int totalNewGems = 0; // Track how many gems we're adding
        
        for (int col = 0; col < BOARD_SIZE; col++) {
            // Count how many empty spaces we have in this column
            int emptySpaces = 0;
            for (int row = 0; row < BOARD_SIZE; row++) {
                if (board[row][col].type == GemType.NONE) {
                    emptySpaces++;
                }
            }
            
            totalNewGems += emptySpaces; // Add to total
            
            // Fill empty spaces from top to bottom
            int gemIndex = 0;
            for (int row = 0; row < BOARD_SIZE; row++) {
                if (board[row][col].type == GemType.NONE) {
                    // Generate random gem type
                    int gemType = uniform(0, 7, rng);
                    board[row][col].type = cast(GemType)gemType;
                    
                    // Start gem above the board, properly stacked
                    // All new gems start from above the visible area
                    Vector2 startPos = Vector2(
                        boardPosition.x + col * (gemSize + gemSpacing),
                        boardPosition.y - (emptySpaces - gemIndex) * (gemSize + gemSpacing) // Stack from top down
                    );
                    Vector2 endPos = Vector2(
                        boardPosition.x + col * (gemSize + gemSpacing),
                        boardPosition.y + row * (gemSize + gemSpacing)
                    );
                    
                    currentPositions[row][col] = startPos;
                    targetPositions[row][col] = endPos;
                    board[row][col].position = startPos;
                    isFalling[row][col] = true;
                    fallDelays[row][col] = gemIndex * 0.05f; // Small stagger delay
                    fallVelocities[row][col] = initialFallSpeed; // Start with slow speed
                    
                    // Reset animation properties
                    board[row][col].currentFrame = 0;
                    board[row][col].frameTimer = 0.0f;
                    board[row][col].isAnimating = false;
                    board[row][col].wasClicked = false;
                    board[row][col].isSelected = false;
                    board[row][col].isMatched = false;
                    
                    gemIndex++;
                }
            }
        }
        
        // Play falling gems sound if any gems were added
        if (totalNewGems > 0) {
            // unused
        }
        
        writeln("GameBoard: Filled empty spaces with consistently spawned gems");
    }

    /**
     * Check if any gems are currently falling
     */
    private bool isAnyGemFalling() {
        int fallingCount = 0;
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                if (isFalling[row][col]) {
                    fallingCount++;
                }
            }
        }
        if (fallingCount > 0) {
            //writefln("GameBoard: %d gems still falling", fallingCount);
        }
        return fallingCount > 0;
    }

    /**
     * Update falling animations with realistic acceleration physics
     */
    private void updateFallingAnimations(float deltaTime) {
        bool anyStillFalling = false;
        float adjustedAcceleration = fallAcceleration * gameSpeed;
        
        // Process each column separately to handle stacking
        for (int col = 0; col < BOARD_SIZE; col++) {
            // Process from bottom to top so lower gems act as barriers
            for (int row = BOARD_SIZE - 1; row >= 0; row--) {
                if (isFalling[row][col]) {
                    // Check if delay has passed
                    if (fallDelays[row][col] > 0.0f) {
                        fallDelays[row][col] -= deltaTime;
                        anyStillFalling = true;
                        continue; // Skip animation until delay is over
                    }
                    
                    Vector2 current = currentPositions[row][col];
                    Vector2 target = targetPositions[row][col];
                    
                    // Apply acceleration to velocity (realistic physics)
                    fallVelocities[row][col] += adjustedAcceleration * deltaTime;
                    
                    // Calculate how far we can fall this frame based on current velocity
                    float fallDistance = fallVelocities[row][col] * deltaTime;
                    float desiredY = current.y + fallDistance;
                    
                    // Check for collision with gem below (if any) - CRITICAL: No overtaking rule
                    float actualY = desiredY;
                    bool hitObstacle = false;
                    
                    if (row < BOARD_SIZE - 1) {
                        // Check if there's a gem below us (falling or stationary)
                        if (board[row + 1][col].type != GemType.NONE) {
                            Vector2 belowPos = currentPositions[row + 1][col];
                            float belowTopY = belowPos.y;
                            float minAllowedY = belowTopY - (gemSize + gemSpacing);
                            
                            if (actualY > minAllowedY) {
                                actualY = minAllowedY;
                                hitObstacle = true;
                                
                                // IMPORTANT: If we hit a falling gem below us, limit our velocity
                                // to match the gem below to prevent future overtaking
                                if (isFalling[row + 1][col]) {
                                    fallVelocities[row][col] = fallVelocities[row + 1][col];
                                    writefln("GameBoard: Gem at (%d,%d) velocity limited to match gem below", row, col);
                                }
                            }
                        }
                    }
                    
                    // Don't fall past our target
                    if (actualY >= target.y) {
                        actualY = target.y;
                        hitObstacle = true;
                    }
                    
                    if (hitObstacle && actualY >= target.y) {
                        // Gem has reached its final destination - stop falling and reset velocity
                        isFalling[row][col] = false;
                        fallVelocities[row][col] = 0.0f;
                        current.y = actualY;
                        currentPositions[row][col] = current;
                        board[row][col].position = current;
                        
                        // Play gem landing sound
                        audioManager.playSFX("resources/audio/sfx/gemongem2.ogg", 0.8f);
                        
                        writefln("GameBoard: Gem at (%d,%d) finished falling to y=%.1f", row, col, current.y);
                    } else {
                        anyStillFalling = true;
                        // Update position
                        current.y = actualY;
                        currentPositions[row][col] = current;
                        board[row][col].position = current;
                    }
                }
            }
        }
        
        // If all gems have finished falling, check for new matches AFTER a small delay
        if (!anyStillFalling && isProcessingMatches) {
            writefln("GameBoard: All gems finished falling. States: isProcessingMatches=%s, isPlayingClearingAnimation=%s", 
                    isProcessingMatches, isPlayingClearingAnimation);
            // Force all gems to exact grid positions first
            ensureAllGemsOnGrid();
            // Then check for cascades immediately
            checkForCascadeMatches();
        } else if (!anyStillFalling && !isProcessingMatches) {
            writeln("GameBoard: All gems finished falling but isProcessingMatches=false - cascade check will not run automatically");
        }
    }

    /**
     * Check for cascade matches after falling is complete
     */
    private void checkForCascadeMatches() {
        // Only skip if we're actively clearing - falling is finished so we can check for cascades
        if (isPlayingClearingAnimation) {
            writeln("GameBoard: Skipping cascade check - clearing animation in progress");
            return;
        }
        
        // Force a complete state check
        writeln("GameBoard: Performing comprehensive cascade check");
        int matchCount = countAllMatches();
        writefln("GameBoard: Cascade check found %d matches", matchCount);
        
        if (matchCount > 0) {
            cascadeMultiplier++;
            
            // Trigger cascade visual effects for multiplier 2+
            if (cascadeMultiplier >= 2) {
                showCascadeEffects = true;
                cascadeEffectTimer = 0.0f;
                cascadeGlowIntensity = 1.0f;
                displayCascadeMultiplier = cascadeMultiplier;
                showCascadeCounter = true;
                cascadeCounterTimer = 0.0f; // Reset timer for new cascade
                
                // Mark all currently matched gems as part of this cascade
                markCascadingGems();
                
                // Trigger screen shake for bigger cascades
                if (cascadeMultiplier >= 3) {
                    showScreenShake = true;
                    screenShakeTimer = 0.0f;
                    screenShakeIntensity = (cascadeMultiplier - 2) * 2.0f; // Stronger shake for higher multipliers
                    writefln("GameBoard: Screen shake triggered for x%d cascade!", cascadeMultiplier);
                }
                
                writefln("GameBoard: Cascade effects triggered for x%d multiplier!", cascadeMultiplier);
            }
            
            writefln("GameBoard: Processing cascade matches (x%d multiplier)", cascadeMultiplier);
            // Don't reset isProcessingMatches - keep it true through cascades
            processMatches(); // Process new matches immediately
        } else {
            // No more matches, completely reset state
            cascadeMultiplier = 1;
            showCascadeEffects = false; // Reset cascade effects
            // Don't immediately hide cascade counter - let it fade out naturally
            showScreenShake = false; // Reset screen shake
            cascadeEffectTimer = 0.0f;
            screenShakeTimer = 0.0f;
            screenShakeOffset = Vector2(0, 0);
            
            // Clear cascade gem markers
            for (int row = 0; row < BOARD_SIZE; row++) {
                for (int col = 0; col < BOARD_SIZE; col++) {
                    isInCurrentCascade[row][col] = false;
                }
            }
            
            isProcessingMatches = false;
            writeln("GameBoard: No more cascades - match processing complete, input now available");
        }
    }

    /**
     * Forcibly reset all animation states (for debugging)
     */
    void resetAllAnimationStates() {
        isSwapping = false;
        needsSwapBack = false;
        swapAnimationTimer = 0.0f;
        swapGem1Pos = Vector2(-1, -1);
        swapGem2Pos = Vector2(-1, -1);
        isProcessingMatches = false;
        isPlayingClearingAnimation = false;
        
        // Reset all gem states
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                board[row][col].isSelected = false;
                board[row][col].isAnimating = false;
                board[row][col].wasClicked = false;
                board[row][col].isClearing = false;
                board[row][col].clearingTimer = 0.0f;
                board[row][col].clearingScale = 1.0f;
                isFalling[row][col] = false;
                fallDelays[row][col] = 0.0f;
                fallVelocities[row][col] = 0.0f;
                
                // Reset position to grid position
                Vector2 correctPos = Vector2(
                    boardPosition.x + col * (gemSize + gemSpacing),
                    boardPosition.y + row * (gemSize + gemSpacing)
                );
                board[row][col].position = correctPos;
                currentPositions[row][col] = correctPos;
                targetPositions[row][col] = correctPos;
            }
        }
        
        selectedGem = Vector2(-1, -1);
        writeln("GameBoard: All animation states forcibly reset");
    }

    /**
     * Start clearing animation for matched gems
     */
    private void startClearingAnimation() {
        // Prevent multiple clearing animations
        if (isPlayingClearingAnimation) {
            writeln("GameBoard: Clearing animation already in progress, ignoring duplicate call");
            return;
        }
        
        isPlayingClearingAnimation = true;
        
        // Count matched gems for scoring
        int matchedGemCount = 0;
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                if (board[row][col].isMatched) {
                    board[row][col].isClearing = true;
                    board[row][col].clearingTimer = 0.0f;
                    board[row][col].clearingScale = 1.0f;
                    matchedGemCount++;
                }
            }
        }
        
        // Calculate and add score ONLY ONCE
        if (matchedGemCount > 0) {
            int matchScore = calculateMatchScore(matchedGemCount);
            score += matchScore;
            
            writefln("GameBoard: Sound selection - matchedGemCount=%d, cascadeMultiplier=%d, numberOfSeparateMatches=%d", 
                    matchedGemCount, cascadeMultiplier, numberOfSeparateMatches);
            
            // Play match clearing sound based on match size and cascade multiplier
            if (cascadeMultiplier >= 5) {
                // Huge cascade combo
                writeln("Playing modern_combo62 (cascade 5+)");
                audioManager.playSFX("resources/audio/sfx/modern_combo62.ogg");
            } else if (cascadeMultiplier >= 4) {
                // Big cascade combo
                writeln("Playing modern_combo52 (cascade 4+)");
                audioManager.playSFX("resources/audio/sfx/modern_combo52.ogg");
            } else if (cascadeMultiplier >= 3) {
                // Medium cascade combo
                writeln("Playing modern_combo42 (cascade 3+)");
                audioManager.playSFX("resources/audio/sfx/modern_combo42.ogg");
            } else if (cascadeMultiplier >= 2) {
                // Small cascade combo (chain reaction)
                writeln("Playing modern_combo32 (cascade 2+)");
                audioManager.playSFX("resources/audio/sfx/modern_combo32.ogg");
            } else if (numberOfSeparateMatches >= 2) {
                // Multiple separate matches (L, T, +, or two 3-gem matches)
                writeln("Playing gotsetbig2 (multiple separate matches)");
                audioManager.playSFX("resources/audio/sfx/gotsetbig2.ogg");
            } else if (matchedGemCount >= 6) {
                // Very large single match
                writeln("Playing modern_combo32 (6+ gem single match)");
                audioManager.playSFX("resources/audio/sfx/modern_combo32.ogg");
            } else if (matchedGemCount >= 5) {
                // Large single match
                writeln("Playing modern_combo22 (5 gem single match)");
                audioManager.playSFX("resources/audio/sfx/modern_combo22.ogg");
            } else if (matchedGemCount >= 4) {
                // 4-gem match
                writeln("Playing gotsetbig2 (4 gem match)");
                audioManager.playSFX("resources/audio/sfx/gotsetbig2.ogg");
            } else {
                // Standard single 3-gem match
                writeln("Playing gotset2 (3 gem match)");
                audioManager.playSFX("resources/audio/sfx/gotset2.ogg");
            }
            
            writefln("GameBoard: Started clearing animation for %d gems, scored %d points (x%d multiplier)", 
                    matchedGemCount, matchScore, cascadeMultiplier);
        }
    }

    /**
     * Mark gems that are part of the current cascade for spark effects
     */
    private void markCascadingGems() {
        // Clear previous cascade markers
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                isInCurrentCascade[row][col] = false;
            }
        }
        
        // Mark all gems that are currently matched as part of this cascade
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                if (board[row][col].isMatched) {
                    isInCurrentCascade[row][col] = true;
                }
            }
        }
        
        writeln("GameBoard: Marked cascading gems for spark effects");
    }

    /**
     * Update clearing animations
     */
    private void updateClearingAnimations(float deltaTime) {
        if (!isPlayingClearingAnimation) return;
        
        bool anyStillClearing = false;
        
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                if (board[row][col].isClearing) {
                    board[row][col].clearingTimer += deltaTime;
                    float progress = board[row][col].clearingTimer / CLEARING_ANIMATION_DURATION;
                    
                    if (progress >= 1.0f) {
                        // Animation complete, remove gem
                        board[row][col].type = GemType.NONE;
                        board[row][col].isMatched = false;
                        board[row][col].isClearing = false;
                        board[row][col].clearingScale = 1.0f;
                        board[row][col].isSelected = false;
                        board[row][col].isAnimating = false;
                        board[row][col].wasClicked = false;
                        board[row][col].currentFrame = 0;
                    } else {
                        // Update shrinking scale with easing
                        float easedProgress = easeInOutQuad(progress);
                        board[row][col].clearingScale = 1.0f - easedProgress;
                        anyStillClearing = true;
                    }
                }
            }
        }
        
        // If all clearing animations are done, start falling
        if (!anyStillClearing) {
            isPlayingClearingAnimation = false;
            writeln("GameBoard: Clearing animation complete, starting falling animation");
            writefln("GameBoard: Before falling - isProcessingMatches=%s", isProcessingMatches);
            startFallingAnimation();
        }
    }

    /**
     * Update board entrance animation
     */
    private void updateEntranceAnimations(float deltaTime) {
        if (!isPlayingEntranceAnimation) return;
        
        entranceAnimationTimer += deltaTime;
        float progress = entranceAnimationTimer / entranceAnimationDuration;
        
        if (progress >= 1.0f) {
            // Animation complete
            progress = 1.0f;
            isPlayingEntranceAnimation = false;
            
            // Start gem drop animation using the existing falling system
            isPlayingGemDropAnimation = true;
            gemDropAnimationTimer = 0.0f;
            
            // Clear the board first
            clearBoard();
            
            // Set up gems to fall from above using existing falling system
            setupInitialGemDrop();
            
            writeln("GameBoard: Entrance animation complete, starting gem drops");
        }
        
        // Smooth ease-out animation
        float easeProgress = 1.0f - (1.0f - progress) * (1.0f - progress) * (1.0f - progress);
        
        // Interpolate board position from right side to final position
        import app : VIRTUAL_SCREEN_WIDTH;
        float startX = VIRTUAL_SCREEN_WIDTH + 750.0f; // Start off-screen
        boardPosition.x = startX + (finalBoardPosition.x - startX) * easeProgress;
        boardPosition.y = finalBoardPosition.y; // Y stays constant
    }
    
    /**
     * Update gem drop animation - simplified to use existing falling system
     */
    private void updateGemDropAnimations(float deltaTime) {
        if (!isPlayingGemDropAnimation) return;
        
        gemDropAnimationTimer += deltaTime;
        
        // Check if all gems have finished falling using existing falling system
        bool allGemsFallingComplete = !isAnyGemFalling();
        
        // Check if we should play "GO!" announcement
        if (gemDropAnimationTimer > 1.0f && !hasPlayedGoAnnouncement) {
            hasPlayedGoAnnouncement = true;
            // Play "GO!" sound effect
            if (audioManager) {
                audioManager.playSound("go_announcement", AudioType.VOX); // Use VOX for announcements
            }
            writeln("GameBoard: Playing GO! announcement");
        }
        
        // Animation complete when all gems have stopped falling
        if (allGemsFallingComplete && gemDropAnimationTimer > 0.5f) {
            isPlayingGemDropAnimation = false;
            writeln("GameBoard: Gem drop animation complete - game ready!");
        }
    }
    
    /**
     * Setup initial gem drop using existing falling system
     */
    private void setupInitialGemDrop() {
        auto rng = Random(unpredictableSeed);
        
        // Fill each column from bottom to top with staggered timing
        for (int col = 0; col < BOARD_SIZE; col++) {
            float columnDelay = col * 0.1f; // Stagger columns slightly
            
            for (int row = BOARD_SIZE - 1; row >= 0; row--) {
                // Generate a valid gem type that doesn't create matches (same as fillBoardWithRandomGems)
                GemType gemType = generateValidGemType(row, col, rng);
                board[row][col].type = gemType;
                board[row][col].isMatched = false;
                board[row][col].isSelected = false;
                board[row][col].isClearing = false;
                board[row][col].currentFrame = 0;
                board[row][col].frameTimer = 0.0f;
                board[row][col].isAnimating = false;
                board[row][col].wasClicked = false;
                
                // Set up falling animation using existing system
                isFalling[row][col] = true;
                
                // Start gems above the screen
                float startY = boardPosition.y - (BOARD_SIZE - row) * (gemSize + gemSpacing) - 100.0f;
                currentPositions[row][col] = Vector2(
                    boardPosition.x + col * (gemSize + gemSpacing),
                    startY
                );
                
                // Target position is normal grid position
                targetPositions[row][col] = Vector2(
                    boardPosition.x + col * (gemSize + gemSpacing),
                    boardPosition.y + row * (gemSize + gemSpacing)
                );
                
                // Set fall delay and initial velocity
                fallDelays[row][col] = columnDelay;
                fallVelocities[row][col] = initialFallSpeed;
                
                // Set gem position to current falling position
                board[row][col].position = currentPositions[row][col];
            }
        }
        
        // Verify no matches will exist when gems land (same verification as fillBoardWithRandomGems)
        // Note: We check this after setting up all gems but before they start falling
        int matchCount = countAllMatches();
        if (matchCount > 0) {
            writefln("WARNING: Generated drop board has %d matches, regenerating...", matchCount);
            // Clear and try again
            clearBoard();
            setupInitialGemDrop();
            return;
        }
        
        writeln("GameBoard: Set up clean gem drop with no initial matches");
    }
    
    /**
     * Update all gem positions based on current board position
     */
    private void updateAllGemPositions() {
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                if (board[row][col].type != GemType.NONE) {
                    board[row][col].position.x = boardPosition.x + col * (gemSize + gemSpacing);
                    board[row][col].position.y = boardPosition.y + row * (gemSize + gemSpacing);
                }
            }
        }
    }

    /**
     * Update cascade visual effects
     */
    private void updateCascadeEffects(float deltaTime) {
        // Update cascade glow effects
        if (showCascadeEffects) {
            cascadeEffectTimer += deltaTime;
            
            // Create pulsing glow effect
            float progress = cascadeEffectTimer / cascadeEffectDuration;
            if (progress < 1.0f) {
                // Pulsing sine wave effect that gets more intense with higher multipliers
                float pulse = (sin(cascadeEffectTimer * 8.0f) + 1.0f) * 0.5f; // 0.0 to 1.0
                cascadeGlowIntensity = pulse * (0.3f + cascadeMultiplier * 0.2f); // Base + multiplier bonus
            } else {
                // Effect finished
                showCascadeEffects = false;
                cascadeEffectTimer = 0.0f;
                cascadeGlowIntensity = 0.0f;
            }
        }
        
        // Update screen shake effects
        if (showScreenShake) {
            screenShakeTimer += deltaTime;
            
            float progress = screenShakeTimer / screenShakeDuration;
            if (progress < 1.0f) {
                // Decaying shake intensity over time
                float currentIntensity = screenShakeIntensity * (1.0f - progress);
                
                // Random shake offset
                import std.random : uniform;
                screenShakeOffset = Vector2(
                    uniform(-currentIntensity, currentIntensity),
                    uniform(-currentIntensity, currentIntensity)
                );
            } else {
                // Shake finished
                showScreenShake = false;
                screenShakeTimer = 0.0f;
                screenShakeIntensity = 0.0f;
                screenShakeOffset = Vector2(0, 0);
            }
        }
        
        // Update cascade counter fade out
        if (showCascadeCounter) {
            cascadeCounterTimer += deltaTime;
            if (cascadeCounterTimer >= cascadeCounterDuration) {
                showCascadeCounter = false;
                cascadeCounterTimer = 0.0f;
            }
        }
    }

    /**
     * Ensure all gems are positioned exactly on the grid (fix any floating point errors)
     */
    private void ensureAllGemsOnGrid() {
        for (int row = 0; row < BOARD_SIZE; row++) {
            for (int col = 0; col < BOARD_SIZE; col++) {
                if (board[row][col].type != GemType.NONE) {
                    Vector2 correctPos = Vector2(
                        boardPosition.x + col * (gemSize + gemSpacing),
                        boardPosition.y + row * (gemSize + gemSpacing)
                    );
                    board[row][col].position = correctPos;
                    currentPositions[row][col] = correctPos;
                    targetPositions[row][col] = correctPos;
                    isFalling[row][col] = false;
                    fallDelays[row][col] = 0.0f;
                }
            }
        }
        writeln("GameBoard: All gems snapped to exact grid positions");
    }
}
