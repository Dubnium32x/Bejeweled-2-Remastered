module screens.title_screen;

import raylib;
import std.random;

import std.stdio;
import std.file;
import std.json;
import std.path;
import std.process;
import std.algorithm;
import std.conv : to;
import std.math;
import std.string : toStringz;
import core.stdc.stdint; // For uint8_t

import data;
import screens.popups.name_entry;
import world.screen_manager;
import world.memory_manager;
import world.audio_manager;
import world.screen_states;
import app; // Import the app module directly
import app : VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT; // Specifically import the constants

// No need to redeclare fontFamily, it\'s already imported from app module

// ---- LOCAL VARIABLES ----
Texture backgroundTexture;
Texture logoTexture;
Texture logoAlpha;
Texture logo2Texture;
Texture logo2Alpha;
Texture buttonTexture;
Texture buttonHoveredTexture;
Texture buttonAlpha;
Texture sparkleTexture; // Texture is used for sparkle animation (and its own alpha texture)
Texture planetTexture;
Texture planetAlpha;
Texture whitenedLogo2Texture;

Texture orbHoverTexture;
Texture subtitleTexture;

// New: Main Menu Button Textures
Texture mainMenuButtonTexture;
Texture mainMenuButtonHighlightTexture;
Texture mainMenuButtonHighlightAlphaTexture;

Texture mistBackgroundTexture;
Texture mistForegroundTexture;

// Mist scroll offsets
float mistBackgroundOffsetX = 0.0f;
float mistForegroundOffsetX = 0.0f;
// Mist scroll speeds (pixels per second)
float mistBackgroundScrollSpeed = 20.0f; // left
float mistForegroundScrollSpeed = 30.0f; // right

// Menu button textures
Texture classicTexture;
Texture classicAlpha;
Texture actionTexture;
Texture actionAlpha;
Texture endlessTexture;
Texture endlessAlpha;
Texture puzzleTexture;
Texture puzzleAlpha;

Sound welcomeSound;
Sound welcomeBackSound;
Sound menuClickSound;
Sound menuClick2Sound;
Sound mainMenuMouseOverSound;
Sound mainMenuMouseClickSound;
Sound mainMenuMouseOffSound;
Sound click2Sound;
Sound mainMenuGameStartSound;

Image[] sparkleImages;
Texture2D[] sparkleFrameTextures;

float logoFadeAlpha = 0.0f;
bool isMusicPlaying = false;
bool playerReady = false;
float screenFadeAlpha = 1.0f;
bool fadeInComplete = false;
Vector2 buttonScale;

// Declare global positions for logo, logo2, button, and planet
Vector2 logoPosition;
Vector2 logo2Position;
Vector2 buttonPosition;
Vector2 planetPosition;

// Define the scale for all textures (for resolution independence)
float textureScale = 1.0f;

// Add variables for logo animation
float logoTargetY = 0.0f;  // Target Y position for the logo
float logoStartY = 0.0f;   // Starting Y position (below screen)
bool logoAnimationStarted = false;

// Add variables for whitened logo2 debugging
float whitenedLogo2Alpha = 0.0f;
bool whitenedLogo2Drawn = false;
float whitenedLogo2Timer = 0.0f;

// Add variables for button delay after logo2
float buttonAppearDelayTimer = 0.0f;
bool buttonAppearDelayStarted = false;

// Add variables for sparkle animation
int currentSparkleFrame = 0;
int sparkleStarIndex = -1;
float sparkleFrameTimer = 0.0f;
float sparkleStarTimer = 0.0f;
bool sparkleActive = false;

// ---- STAR STRUCT ----
struct Star {
    float x;
    float y;
    float speed;
    Color color;
    
    // ---- STAR FIELD ----
    void update(float deltaTime) {
        y -= speed * deltaTime;
        if (y > VIRTUAL_SCREEN_HEIGHT) { // Changed from GetScreenHeight()
            y = 0.0f;
            x = uniform(0, VIRTUAL_SCREEN_WIDTH); // Changed from GetScreenWidth()
        }
    }
}

// ---- CLASS ----
class TitleScreen : IScreen {
    // Singleton instance
    private __gshared TitleScreen instance;
    private MemoryManager memoryManager;
    private AudioManager audioManager;
    private NameEntry nameEntryDialog; // Changed: Declare without initializing

    // Current state of the screen
    TitleState state;

    // Timer for animations
    private float sparkleTimer = 0.0f;

    // New: Textures and positions for menu gadgets
    private Texture menuGadgetsTexture;
    private Texture menuGadgetsAlpha;
    private Vector2 menuGadgetsPosition;
    private float menuGadgetsTargetY;
    private float menuGadgetsStartY;

    // Menu buttons state
    private Vector2 classicButtonPosition;
    private Vector2 actionButtonPosition;
    private Vector2 endlessButtonPosition;
    private Vector2 puzzleButtonPosition;
    private bool classicButtonHovered = false;
    private bool actionButtonHovered = false;
    private bool endlessButtonHovered = false;
    private bool puzzleButtonHovered = false;
    private bool toggleModesButtonHovered = false;
    private bool returnToMenuButtonHovered = false;
    private float menuButtonScale = 1.0f;
    private int lastHoveredButton = 0; // 0=none, 1=classic, 2=action, 3=endless, 4=puzzle, 5=toggle, 6=return
    
    // Define centerX as class member
    private float centerX;
    private float centerY;

    // New: Flags and speeds for transition animations
    private bool titleElementsMovingOff = false;
    private bool menuGadgetsMovingOn = false;
    private float offScreenAnimationSpeed = 600.0f; // Reduced from 1200.0f to 600.0f for slower logo rise
    private float menuGadgetsAnimationSpeed = 1000.0f; // Pixels per second
    private float menuGadgetsScale = 1.0f; // Adjusted scale for better fit with original game
    private float menuGadgetsEasingFactor = 4.0f; // New: Easing for menu gadgets movement

    // Check whether the title elements have moved off screen
    bool titleElementsOffScreen() {
        return !titleElementsMovingOff && logoPosition.y <= -logoTexture.height && 
               logo2Position.y <= -logo2Texture.height && 
               buttonPosition.y <= -buttonTexture.height * buttonScale.y;
    }

    // Check whether the menu gadgets have moved on screen
    bool menuGadgetsOnScreen() {
        return !menuGadgetsMovingOn && abs(menuGadgetsPosition.y - menuGadgetsTargetY) < 1.0f;
    }

    // Resources to preload
    private string[] texturesToPreload;
    private string[] soundsToPreload;
    private string[] musicToPreload;

    private Star[] stars; // Array of stars for star field effect

    // Button click state and fade-out animation
    private bool buttonClickedOnce = false;
    private float buttonFadeOutAlpha = 1.0f;

    // Small logo (top-left) animation variables
    private Vector2 smallLogoBasePosition;       // Target X for "Bejeweled", and general Y reference when SHOWN
    private Vector2 smallLogo2RelativePosition;  // Offset of "2" relative to "Bejeweled"
    private float smallLogoCurrentY;             // Current Y position for animation
    private float smallLogoTargetY;              // On-screen Y position
    private float smallLogoStartY;               // Off-screen Y position (above screen)
    private float smallLogoScale;
    private bool smallLogoAnimatingIn;
    private bool smallLogoAnimatingOut;
    private bool smallLogoIsShown;              // Controls visibility and if it *should* be on screen or animating
    private float smallLogoAnimationTimer;
    private float smallLogoAnimationDuration;

    // Main Menu Buttons
    private string[] mainMenuButtonLabels;
    private Rectangle[] mainMenuButtonRects;
    private bool[] mainMenuButtonHoverStates;
    private float mainMenuButtonTargetX;
    private float mainMenuButtonStartX;
    private float mainMenuButtonCurrentX;
    private float mainMenuButtonTopY;
    private float mainMenuButtonSpacingY;
    private float mainMenuButtonFontSize;
    private bool mainMenuButtonsAnimatingIn;
    private bool mainMenuButtonsAnimatingOut;
    private bool mainMenuButtonsAreShown;
    private float mainMenuButtonsAnimationTimer;
    private float mainMenuButtonsAnimationDuration;
    private int mainMenuLastHoveredButtonIndex = -1; // -1 for none
    private float mainMenuButtonVerticalGap; // NEW CLASS MEMBER

    private Sound mainMenuMouseOverSound;
    private Sound mainMenuMouseClickSound;
    private Sound mainMenuGameStartSound;

    private string copyrightText; // For copyright notice

    // Orb hover texture
    private Texture2D orbHoverTexture;

    // Subtitle texture and sparkle effect
    private Texture2D subtitleTexture;
    private Texture2D sparkleTexture;
    private bool subtitleEffectActive = false;      // Tracks if the wipe effect is currently running
    private bool subtitleEffectPlayedOnce = false;  // Tracks if the initial wipe effect has completed
    private float subtitleWipeProgress = 0.0f;      // 0.0 to 1.0 for wipe animation
    private float subtitleEffectTimer = 0.0f;       // Timer for the subtitle effect
    private float subtitleEffectDuration = 1.0f;    // Duration of the subtitle wipe effect in seconds
    private bool logoStableForSubtitleEffect = false; // True when main logo is in final position

    // Small logo subtitle properties
    private float subtitleYOffset;              // Y offset for the small logo's subtitle from the bottom of the small logo
    private float subtitleXOffset;              // X offset for the small logo's subtitle from the center of the small logo
    private float smallLogoSubtitleScale;       // Scale of the subtitle texture when shown with the small logo

    // New: Variables for main logo's subtitle positioning and scale
    private float mainLogoSubtitleScale = 0.55f; // Adjusted from 0.6f
    private float mainLogoSubtitleYOffset = 5.0f; // Adjusted from 15.0f
    private float mainLogoSubtitleXOffset = 0.0f;  // Pixels to shift L/R from center of "2"

    private TitleState previousTitleState; // To detect state changes for small logo animation

    // New: Flags for secret modes
    private bool secretModesEnabled = false; // Flag to track if secret modes are enabled

    // Menu UI text elements
    private string selectGameModeText = "Select a game mode.";
    private string welcomeText; // Will be set in constructor or initialize
    private string originalGameText; // Will be populated conditionally
    private string classicLevelText;  // Will be populated conditionally
    private string actionLevelText;   // Will be populated conditionally
    private string puzzlePercentText; // Changed to 0% as requested
    private string endlessLevelText; // Keep showing Level 1 for Endless
    private string toggleModesText = "Toggle Secret Modes";
    private string returnToMenuText = "Return to the Main Menu";
    
    // Add flags to track saved game existence
    private bool hasClassicSavedGame = false; // Set this based on save file detection
    private bool hasActionSavedGame = false;  // Set this based on save file detection

    this() {
        // Initialize singleton instance
        if (instance is null) {
            instance = this;
        }

        memoryManager = MemoryManager.instance();
        audioManager = AudioManager.getInstance();

        // Initialize welcomeText with the current saveNameText
        welcomeText = ("Welcome, " ~ data.playerSavedName ~ "!");

        texturesToPreload = [
            // Textures for the title screen
            "resources/image/backdrops/backdrop_title_A.png",
            "resources/image/title_logo.png",
            "resources/image/title_logo_.png",
            "resources/image/title_logo2.png",
            "resources/image/title_logo2_.png",
            "resources/image/title_loaderbar_clickhere.png",
            "resources/image/title_loaderbar_clickhere_over.png",
            "resources/image/title_loaderbarlit_.png",
            "resources/image/sparkle.png",
            "resources/image/planet1.png",
            "resources/image/planet1_.png",
            // PATCH: Add mist textures
            "resources/image/mist_background.png",
            "resources/image/mist.png",
            // Textures for the main menu
            "resources/image/Menu-Gadgets.png",
            "resources/image/Menu-Gadgets_.png", // alpha
            // Menu button textures
            "resources/image/Classic.png", 
            "resources/image/Classic_.png", // alpha
            "resources/image/Action.png",
            "resources/image/Action_.png", // alpha
            "resources/image/Endless.png",
            "resources/image/Endless_.png", // alpha
            "resources/image/Puzzle.png",
            "resources/image/Puzzle_.png", // alpha
            // New Main Menu Button Textures
            "resources/image/menu_button.png",
            "resources/image/GMBHIghlite.png",
            "resources/image/GMBHIghlite_.png",
            // Add orb texture
            // "resources/image/MMSGamerollover_.png" // This texture is not used in the title screen, so it can be omitted here
            "resources/image/MMSGamerollover_.png",
            // Add subtitle texture
            "resources/image/subtitle.png"
        ];

         soundsToPreload = [
            // Sounds for the title screen
            "resources/audio/sfx/menuclick.ogg",
            "resources/audio/sfx/menuclick2.ogg",
            "resources/audio/vox/welcome.ogg",
            "resources/audio/vox/welcome_back.ogg",
            // Sounds for the main menu
            "resources/audio/sfx/mainmenu_mouseover.ogg",
            "resources/audio/sfx/mainmenu_mouseclick.ogg",
            "resources/audio/sfx/mainmenu_mouseoff.ogg",
            "resources/audio/sfx/click2.ogg",
            "resources/audio/sfx/mainmenu_gamestart.ogg"
         ];

        musicToPreload = [
            // Music for the title screen (if any)
            "resources/audio/music/arranged/Autonomous.ogg",
            "resources/audio/music/arranged/Main Theme - Bejeweled 2.ogg"
        ];}

    static TitleScreen getInstance() {
        if (instance is null) {
            synchronized {
                if (instance is null) {
                    instance = new TitleScreen();
                }
            }
        }
        return instance;
    }

    void initialize() {
        memoryManager = MemoryManager.instance();
        audioManager = AudioManager.getInstance();
        nameEntryDialog = new NameEntry(); // Added: Initialize here

        // Load textures
        backgroundTexture = LoadTexture("resources/image/backdrops/backdrop_title_A.png");
        SetTextureFilter(backgroundTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        logoTexture = LoadTexture("resources/image/title_logo.png");
        SetTextureFilter(logoTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        logoAlpha = LoadTexture("resources/image/title_logo_.png");
        SetTextureFilter(logoAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        logo2Texture = LoadTexture("resources/image/title_logo2.png");
        SetTextureFilter(logo2Texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        logo2Alpha = LoadTexture("resources/image/title_logo2_.png");
        SetTextureFilter(logo2Alpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        buttonTexture = LoadTexture("resources/image/title_loaderbar_clickhere.png");
        SetTextureFilter(buttonTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        buttonHoveredTexture = LoadTexture("resources/image/title_loaderbar_clickhere_over.png");
        SetTextureFilter(buttonHoveredTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        buttonAlpha = LoadTexture("resources/image/title_loaderbarlit_.png");
        SetTextureFilter(buttonAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        sparkleTexture = LoadTexture("resources/image/sparkle.png");
        SetTextureFilter(sparkleTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        planetTexture = LoadTexture("resources/image/planet1.png");
        SetTextureFilter(planetTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        planetAlpha = LoadTexture("resources/image/planet1_.png");
        SetTextureFilter(planetAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        menuGadgetsTexture = LoadTexture("resources/image/Menu-Gadgets.png");
        SetTextureFilter(menuGadgetsTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        menuGadgetsAlpha = LoadTexture("resources/image/Menu-Gadgets_.png");
        SetTextureFilter(menuGadgetsAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        subtitleTexture = LoadTexture("resources/image/subtitle.png");
        SetTextureFilter(subtitleTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);

        // PATCH: Load mist textures
        mistBackgroundTexture = LoadTexture("resources/image/mist_background.png");
        SetTextureFilter(mistBackgroundTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        mistForegroundTexture = LoadTexture("resources/image/mist.png");
        SetTextureFilter(mistForegroundTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        
        // Load menu button textures
        classicTexture = LoadTexture("resources/image/Classic.png");
        SetTextureFilter(classicTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        classicAlpha = LoadTexture("resources/image/Classic_.png");
        SetTextureFilter(classicAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        actionTexture = LoadTexture("resources/image/Action.png");
        SetTextureFilter(actionTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        actionAlpha = LoadTexture("resources/image/Action_.png");
        SetTextureFilter(actionAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        endlessTexture = LoadTexture("resources/image/Endless.png");
        SetTextureFilter(endlessTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        endlessAlpha = LoadTexture("resources/image/Endless_.png");
        SetTextureFilter(endlessAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        puzzleTexture = LoadTexture("resources/image/Puzzle.png");
        SetTextureFilter(puzzleTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        puzzleAlpha = LoadTexture("resources/image/Puzzle_.png");
        SetTextureFilter(puzzleAlpha, TextureFilter.TEXTURE_FILTER_BILINEAR);
        orbHoverTexture = LoadTexture("resources/image/MMSGamerollover_.png");
        SetTextureFilter(orbHoverTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);

        // New: Load Main Menu Button Textures
        mainMenuButtonTexture = LoadTexture("resources/image/menu_button.png");
        SetTextureFilter(mainMenuButtonTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        mainMenuButtonHighlightTexture = LoadTexture("resources/image/GMBHIghlite.png");
        SetTextureFilter(mainMenuButtonHighlightTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        mainMenuButtonHighlightAlphaTexture = LoadTexture("resources/image/GMBHIghlite_.png");
        SetTextureFilter(mainMenuButtonHighlightAlphaTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);

        // Initialize state
        state = TitleState.LOGO;

        // Initialize audio
        audioManager.initialize();

        // Load sounds
        welcomeSound = LoadSound("resources/audio/vox/welcome.ogg");
        welcomeBackSound = LoadSound("resources/audio/vox/welcome_back.ogg");
        menuClickSound = LoadSound("resources/audio/sfx/menuclick.ogg");
        menuClick2Sound = LoadSound("resources/audio/sfx/menuclick2.ogg");
        mainMenuMouseOverSound = LoadSound("resources/audio/sfx/mainmenu_mouseover.ogg");
        mainMenuMouseClickSound = LoadSound("resources/audio/sfx/mainmenu_mouseclick.ogg");
        mainMenuMouseOffSound = LoadSound("resources/audio/sfx/mainmenu_mouseoff.ogg");
        click2Sound = LoadSound("resources/audio/sfx/click2.ogg");
        mainMenuGameStartSound = LoadSound("resources/audio/sfx/secret.ogg");

        // Initialize copyright text
        copyrightText = "BEJEWELED 2 - 2004 POPCAP GAMES, INC. ALL RIGHTS RESERVED.";

        // Initialize subtitle effect variables
        subtitleEffectActive = false;

        // Set initial state
        state = TitleState.LOGO;
        
        // Check for saved game files (for demo, these are set to false)
        // TODO: Add actual save file detection
        hasClassicSavedGame = false;
        hasActionSavedGame = false;
        
        // Set up level text based on saved game state
        classicLevelText = "LEVEL " ~ to!string(playerSavedClassicLevel);
        actionLevelText = "LEVEL " ~ to!string(playerSavedActionLevel);

        if (currentGameMode == GameMode.ORIGINAL) {
            puzzlePercentText = to!string(percentPuzzleCompletionOriginal) ~ "%"; // Use the original game mode's completion percentage
        }
        else if (currentGameMode == GameMode.ARRANGED) {
            puzzlePercentText = to!string(percentPuzzleCompletionArranged) ~ "%"; // Use the arranged game mode's completion percentage
        } else {
            puzzlePercentText = "N/A"; // Default for other modes
        }

        endlessLevelText = "LEVEL " ~ to!string(playerSavedEndlessLevel);

        // if (!playerHasSavedClassicGame) {
        //     classicLevelText = "";
        // }
        // if (!playerHasSavedActionGame) {
        //     actionLevelText = "";
        // }
        // if (!playerHasSavedPuzzleGame) {
        //     puzzlePercentText = "";
        // }
        // if (!playerHasSavedEndlessGame) {
        //     endlessLevelText = "";
        // }

        alphaMapTextures();
        sliceSparkleTextures();

        // Initialize positions
        logoTargetY = (VIRTUAL_SCREEN_HEIGHT - logoTexture.height) / 8; // Changed
        logoStartY = VIRTUAL_SCREEN_HEIGHT + 50.0f; // Start below screen // Changed
        logoPosition = Vector2((VIRTUAL_SCREEN_WIDTH - logoTexture.width) / 2.0f + (16 * textureScale), VIRTUAL_SCREEN_HEIGHT); // Start below screen // Changed
        logo2Position = Vector2((VIRTUAL_SCREEN_WIDTH - logo2Texture.width) / 2.0f, (VIRTUAL_SCREEN_HEIGHT - logo2Texture.height) / 3.5f); // Changed
        buttonPosition = Vector2((VIRTUAL_SCREEN_WIDTH - buttonTexture.width) / 2.0f, VIRTUAL_SCREEN_HEIGHT - buttonTexture.height - 50.0f); // Changed
        planetPosition = Vector2(VIRTUAL_SCREEN_WIDTH - (planetTexture.width * (3.0/2.0)), VIRTUAL_SCREEN_HEIGHT - planetTexture.height); // Changed
        buttonScale = Vector2(0, 0);

        // Initialize menu gadgets positions
        menuGadgetsTargetY = (VIRTUAL_SCREEN_HEIGHT - (menuGadgetsTexture.height * menuGadgetsScale)) / 2.0f; // Adjusted for scale // Changed
        menuGadgetsStartY = VIRTUAL_SCREEN_HEIGHT; // Start below screen // Changed
        menuGadgetsPosition = Vector2((VIRTUAL_SCREEN_WIDTH - (menuGadgetsTexture.width * menuGadgetsScale)) / 2.0f, menuGadgetsStartY); // Adjusted for scale // Changed
        
        // Initialize menu button positions centered within menu gadgets texture
        // Calculate the center point of the menu gadgets
        centerX = VIRTUAL_SCREEN_WIDTH / 2.0f; // Changed
        centerY = menuGadgetsTargetY + (menuGadgetsTexture.height * menuGadgetsScale) / 2.0f;
        
        // Position buttons precisely to match the reference image
        // Set position values to match the desired menu layout
        float topRowY = menuGadgetsTargetY + menuGadgetsTexture.height * menuGadgetsScale * 0.22f; // Keep top row at this good position
        float bottomRowY = menuGadgetsTargetY + menuGadgetsTexture.height * menuGadgetsScale * 0.67f; // Adjusted to align with purple orbs
        
        // Position buttons horizontally to align with the circles - closer to center than before
        float halfWidth = (menuGadgetsTexture.width * menuGadgetsScale) / 2.0f;
        float leftX = centerX - halfWidth * 0.49f;  // 49% from center to the left (for better alignment)
        float rightX = centerX + halfWidth * 0.49f; // 49% from center to the right (for better alignment)

        classicButtonPosition = Vector2(leftX, topRowY);
        actionButtonPosition = Vector2(rightX, topRowY);
        // Swap Endless and Puzzle positions based on the screenshot
        puzzleButtonPosition = Vector2(leftX, bottomRowY);
        endlessButtonPosition = Vector2(rightX, bottomRowY);

        this.previousTitleState = TitleState.LOGO; // Initialize previous state

        smallLogoScale = 0.35f; 
        smallLogoTargetY = 15.0f; 
        smallLogoStartY = -(logoTexture.height * smallLogoScale) - 10.0f;
        smallLogoCurrentY = smallLogoStartY; 

        smallLogoBasePosition = Vector2(15.0f, smallLogoTargetY); 

        // New calculation for smallLogo2RelativePosition:
        float actualScaledBejeweledWidth = logoTexture.width * smallLogoScale; // Width of "BEJEWELED" part
        float actualScaledBejeweledHeight = logoTexture.height * smallLogoScale; // Height of "BEJEWELED" part
        float actualScaled2Width = logo2Texture.width * smallLogoScale; // Width of "2" part

        // X: Center the "2" logo relative to the "BEJEWELED" logo
        float relativeX = (actualScaledBejeweledWidth - actualScaled2Width) / 2.0f;
        
        // Y: Position the top of the "2" logo at 60% of the "BEJEWELED" logo's height, 
        //    measured downwards from the top of the "BEJEWELED" logo.
        float relativeY = actualScaledBejeweledHeight * 0.60f;

        smallLogo2RelativePosition = Vector2(relativeX - (16.0f * smallLogoScale), relativeY);

        smallLogoAnimatingIn = false;
        smallLogoAnimatingOut = false;
        smallLogoIsShown = false;
        smallLogoAnimationTimer = 0.0f;
        smallLogoAnimationDuration = 0.6f;

        // Main Menu Buttons Initialization
        mainMenuButtonLabels = [
            "PLAY GAME", 
            "OPTIONS", 
            "LEADERBOARDS", 
            "HELP", 
            "QUIT GAME"
        ];
        mainMenuButtonRects = new Rectangle[mainMenuButtonLabels.length];
        mainMenuButtonHoverStates = new bool[mainMenuButtonLabels.length];
        mainMenuButtonVerticalGap = 10.0f; // Initialize the new member

        mainMenuButtonFontSize = 34.0f; // Reduced font size for better fit

        // Assuming mainMenuButtonTexture is loaded and valid
        if (mainMenuButtonTexture.id != 0) {
            mainMenuButtonTargetX = VIRTUAL_SCREEN_WIDTH - mainMenuButtonTexture.width - 50.0f; // 50px padding from right
            mainMenuButtonStartX = VIRTUAL_SCREEN_WIDTH + mainMenuButtonTexture.width;  // Start fully off-screen to the right

            // Calculate TopY to vertically center the block of buttons
            float totalButtonBlockHeight = (mainMenuButtonLabels.length * mainMenuButtonTexture.height) + 
                                         ((mainMenuButtonLabels.length > 0 ? mainMenuButtonLabels.length - 1 : 0) * mainMenuButtonVerticalGap);
            mainMenuButtonTopY = (VIRTUAL_SCREEN_HEIGHT - totalButtonBlockHeight) / 2.0f;

            for (size_t i = 0; i < mainMenuButtonLabels.length; i++) {
                float currentButtonY = mainMenuButtonTopY + i * (mainMenuButtonTexture.height + mainMenuButtonVerticalGap);
                mainMenuButtonRects[i] = Rectangle(
                    mainMenuButtonStartX, // Initial X is off-screen
                    currentButtonY,
                    mainMenuButtonTexture.width,
                    mainMenuButtonTexture.height
                );
                mainMenuButtonHoverStates[i] = false;
            }
        } else {
            // Fallback if texture isn't loaded (should not happen with preloading)
            debugLog("Error: mainMenuButtonTexture not loaded, button layout may be incorrect. Using text-based fallback.");
            mainMenuButtonTargetX = VIRTUAL_SCREEN_WIDTH - 280.0f; 
            mainMenuButtonStartX = VIRTUAL_SCREEN_WIDTH + 20.0f;
            // mainMenuButtonSpacingY was used for text-based layout, calculate equivalent for rect init
            float textBasedSpacingY = mainMenuButtonFontSize + 18.0f; 
            float totalButtonBlockHeight = mainMenuButtonLabels.length * textBasedSpacingY - (textBasedSpacingY - mainMenuButtonFontSize); 
            mainMenuButtonTopY = (VIRTUAL_SCREEN_HEIGHT - totalButtonBlockHeight) / 2.0f;
            for (size_t i = 0; i < mainMenuButtonLabels.length; i++) {
                 Vector2 textSize = MeasureTextEx(app.fontFamily[0], mainMenuButtonLabels[i].toStringz(), mainMenuButtonFontSize, 1.0f);
                 mainMenuButtonRects[i] = Rectangle(
                     mainMenuButtonStartX, 
                     mainMenuButtonTopY + i * textBasedSpacingY, 
                     textSize.x, 
                     mainMenuButtonFontSize
                 );
                 mainMenuButtonHoverStates[i] = false;
            }
        }
        mainMenuButtonCurrentX = mainMenuButtonStartX; // Ensure currentX starts off-screen

        mainMenuButtonsAnimatingIn = false;
        mainMenuButtonsAnimatingOut = false;
        mainMenuButtonsAreShown = false;
        mainMenuButtonsAnimationTimer = 0.0f;
        mainMenuButtonsAnimationDuration = 0.5f; // Animation duration for buttons
    
        // Play autonomous music if not already playing
        audioManager.playSound("resources/audio/music/arranged/Autonomous.ogg", AudioType.MUSIC, 1.0f, true);
    }

    static void debugLog(string msg) {
        // Conditional debug logging - can be enabled or disabled globally
        bool debugEnabled = true; // Set to false to disable debug logs
        if (debugEnabled) {
            writeln(msg);
        }
    }

    void alphaMapTextures() {
        Image logoImage = LoadImageFromTexture(logoTexture);
        Image logoAlphaImage = LoadImageFromTexture(logoAlpha);        
        Image logo2Image = LoadImageFromTexture(logo2Texture);
        Image logo2AlphaImage = LoadImageFromTexture(logo2Alpha);
        Image buttonImage = LoadImageFromTexture(buttonTexture);
        Image buttonAlphaImage = LoadImageFromTexture(buttonAlpha);
        Image planetImage = LoadImageFromTexture(planetTexture);
        Image planetAlphaImage = LoadImageFromTexture(planetAlpha);
        Image menuGadgetsImage = LoadImageFromTexture(menuGadgetsTexture);
        Image menuGadgetsAlphaImage = LoadImageFromTexture(menuGadgetsAlpha);

        // New: Main Menu Button Highlight Texture Alpha Mapping
        Image mainMenuButtonHighlightImage = LoadImageFromTexture(mainMenuButtonHighlightTexture);
        Image mainMenuButtonHighlightAlphaImage = LoadImageFromTexture(mainMenuButtonHighlightAlphaTexture);
        ImageAlphaMask(&mainMenuButtonHighlightImage, mainMenuButtonHighlightAlphaImage);
        mainMenuButtonHighlightTexture = LoadTextureFromImage(mainMenuButtonHighlightImage);
        SetTextureFilter(mainMenuButtonHighlightTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        UnloadImage(mainMenuButtonHighlightImage);
        UnloadImage(mainMenuButtonHighlightAlphaImage);
        
        // Apply alpha mapping to logo textures
        ImageAlphaMask(&logoImage, logoAlphaImage);
        logoTexture = LoadTextureFromImage(logoImage);
        SetTextureFilter(logoTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        // UnloadImage(logoAlphaImage); // Commented out to avoid double free
        // Apply alpha mapping to logo2 textures
        ImageAlphaMask(&logo2Image, logo2AlphaImage);
        logo2Texture = LoadTextureFromImage(logo2Image);
        SetTextureFilter(logo2Texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        // UnloadImage(logo2AlphaImage); // Commented out to avoid double free
        // Apply alpha mapping to button textures
        ImageAlphaMask(&buttonImage, buttonAlphaImage);
        buttonTexture = LoadTextureFromImage(buttonImage);
        SetTextureFilter(buttonTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        // UnloadImage(buttonAlphaImage); // Commented out to avoid double free
        
        // Apply alpha mapping to button hovered texture
        Image buttonHoveredImage = LoadImageFromTexture(buttonHoveredTexture);
        ImageAlphaMask(&buttonHoveredImage, buttonAlphaImage);
        buttonHoveredTexture = LoadTextureFromImage(buttonHoveredImage);
        SetTextureFilter(buttonHoveredTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        UnloadImage(buttonHoveredImage);
        // Apply alpha mapping to planet textures
        ImageAlphaMask(&planetImage, planetAlphaImage);
        planetTexture = LoadTextureFromImage(planetImage);
        SetTextureFilter(planetTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        // UnloadImage(planetAlphaImage); // Commented out to avoid double free
        // Apply alpha mapping to sparkle textures
        Image sparkleImage = LoadImageFromTexture(sparkleTexture);
        Image sparkleAlphaImage = LoadImageFromTexture(sparkleTexture);
        ImageAlphaMask(&sparkleImage, sparkleAlphaImage);
        sparkleTexture = LoadTextureFromImage(sparkleImage);
        SetTextureFilter(sparkleTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        // UnloadImage(sparkleAlphaImage); // Commented out to avoid double free
        // Apply alpha mapping to whitened logo2 texture
        Image whitenedLogo2Image = LoadImageFromTexture(logo2Alpha);
        ImageAlphaMask(&whitenedLogo2Image, whitenedLogo2Image);
        whitenedLogo2Texture = LoadTextureFromImage(whitenedLogo2Image);
        SetTextureFilter(whitenedLogo2Texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        // UnloadImage(whitenedLogo2Image); // Commented out to avoid double free
        // Apply alpha mapping to menu gadgets texture
        ImageAlphaMask(&menuGadgetsImage, menuGadgetsAlphaImage);
        menuGadgetsTexture = LoadTextureFromImage(menuGadgetsImage);
        SetTextureFilter(menuGadgetsTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        UnloadImage(menuGadgetsImage); // Unload original image
        UnloadImage(menuGadgetsAlphaImage); // Unload alpha image
        
        // Apply alpha mapping to menu button textures
        Image classicImage = LoadImageFromTexture(classicTexture);
        Image classicAlphaImage = LoadImageFromTexture(classicAlpha);
        ImageAlphaMask(&classicImage, classicAlphaImage);
        classicTexture = LoadTextureFromImage(classicImage);
        SetTextureFilter(classicTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        UnloadImage(classicImage);
        UnloadImage(classicAlphaImage);
        
        Image actionImage = LoadImageFromTexture(actionTexture);
        Image actionAlphaImage = LoadImageFromTexture(actionAlpha);
        ImageAlphaMask(&actionImage, actionAlphaImage);
        actionTexture = LoadTextureFromImage(actionImage);
        SetTextureFilter(actionTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        UnloadImage(actionImage);
        UnloadImage(actionAlphaImage);
        
        Image endlessImage = LoadImageFromTexture(endlessTexture);
        Image endlessAlphaImage = LoadImageFromTexture(endlessAlpha);
        ImageAlphaMask(&endlessImage, endlessAlphaImage);
        endlessTexture = LoadTextureFromImage(endlessImage);
        SetTextureFilter(endlessTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        UnloadImage(endlessImage);
        UnloadImage(endlessAlphaImage);
        
        Image puzzleImage = LoadImageFromTexture(puzzleTexture);
        Image puzzleAlphaImage = LoadImageFromTexture(puzzleAlpha);
        ImageAlphaMask(&puzzleImage, puzzleAlphaImage);
        puzzleTexture = LoadTextureFromImage(puzzleImage);
        SetTextureFilter(puzzleTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        UnloadImage(puzzleImage);
        UnloadImage(puzzleAlphaImage);

        // Apply alpha mapping to orb hover texture
        Image orbHoverImage = LoadImageFromTexture(orbHoverTexture);
        Image orbHoverAlphaImage = LoadImageFromTexture(orbHoverTexture);
        ImageAlphaMask(&orbHoverImage, orbHoverAlphaImage);
        orbHoverTexture = LoadTextureFromImage(orbHoverImage);
        SetTextureFilter(orbHoverTexture, TextureFilter.TEXTURE_FILTER_BILINEAR);
    }

    void sliceSparkleTextures() {
        // the image is 14 sprites, 40x40 each
        int spriteWidth = 40;
        int spriteHeight = 40;
        int spriteCount = 14;
        sparkleImages = new Image[spriteCount];
        sparkleFrameTextures = new Texture2D[spriteCount];
        
        // Load the correct sparkle image for both texture and alpha
        Image sparkleImage = LoadImage("resources/image/sparkle.png");
        
        for (int i = 0; i < spriteCount; i++) {
            int x = (i % 14) * spriteWidth;
            int y = (i / 14) * spriteHeight;
            
            // Crop the frame from the sprite sheet
            Image croppedImage = ImageFromImage(sparkleImage, Rectangle(x, y, spriteWidth, spriteHeight));
            
            // Also crop the same image to use as alphamap (sparkle is its own alpha)
            Image croppedAlpha = ImageFromImage(sparkleImage, Rectangle(x, y, spriteWidth, spriteHeight));
            
            // Apply alpha mask - use the image as its own alpha
            ImageAlphaMask(&croppedImage, croppedAlpha);
            
            // Store the alpha-mapped image
            sparkleImages[i] = croppedImage;
            
            // Create texture from the alpha-mapped image
            sparkleFrameTextures[i] = LoadTextureFromImage(croppedImage);
            SetTextureFilter(sparkleFrameTextures[i], TextureFilter.TEXTURE_FILTER_BILINEAR);
            
            // We can unload the alpha image since we're done with it
            UnloadImage(croppedAlpha);
        }
        
        // Unload the original image after slicing
        UnloadImage(sparkleImage);
    }

    void update(float dt) {
        // Update the texture scale based on the screen size
        // This should be done in the initialize method

        bool justEnteredMainMenu = (state == TitleState.MAINMENU && this.previousTitleState != TitleState.MAINMENU);
        bool justExitedMainMenu = (state != TitleState.MAINMENU && this.previousTitleState == TitleState.MAINMENU);

        if (justEnteredMainMenu) {
            if (!smallLogoIsShown && !smallLogoAnimatingIn) {
                smallLogoAnimatingIn = true;
                smallLogoAnimatingOut = false;
                smallLogoIsShown = true;
                smallLogoAnimationTimer = 0.0f;
                smallLogoCurrentY = smallLogoStartY; 
            }
            if (!mainMenuButtonsAreShown && !mainMenuButtonsAnimatingIn) {
                mainMenuButtonsAnimatingIn = true;
                mainMenuButtonsAnimatingOut = false;
                mainMenuButtonsAreShown = true;
                mainMenuButtonsAnimationTimer = 0.0f;
                mainMenuButtonCurrentX = mainMenuButtonStartX;
            }
            if (!playerHasSavedName && state == TitleState.MAINMENU && !smallLogoAnimatingIn && !smallLogoAnimatingOut) {
                // Create a name entry dialog if the player has no saved name
                state = TitleState.OPTIONS;
                nameEntryDialog.create();
                if (nameEntryDialog.hasNameEntry) {
                    nameEntryDialog.update(dt);
                }
            }
        } else if (justExitedMainMenu) {
            if (smallLogoIsShown && !smallLogoAnimatingOut) {
                smallLogoAnimatingOut = true;
                smallLogoAnimatingIn = false;
                smallLogoAnimationTimer = 0.0f;
            }
            if (mainMenuButtonsAreShown && !mainMenuButtonsAnimatingOut) {
                mainMenuButtonsAnimatingOut = true;
                mainMenuButtonsAnimatingIn = false;
                mainMenuButtonsAnimationTimer = 0.0f;
            }
        }

        // --- Small Logo Animation Control & Execution ---
        if ((state == TitleState.MAINMENU || state == TitleState.OPTIONS) && !smallLogoIsShown && !smallLogoAnimatingIn && !smallLogoAnimatingOut) {
            smallLogoAnimatingIn = true;
            smallLogoAnimatingOut = false; // Ensure out is false
            smallLogoAnimationTimer = 0.0f;
            smallLogoCurrentY = smallLogoStartY; // Start from off-screen
        } else if ((state != TitleState.MAINMENU && state != TitleState.OPTIONS) && (smallLogoIsShown || smallLogoAnimatingIn) && !smallLogoAnimatingOut) { // MODIFIED condition
            smallLogoAnimatingOut = true;
            if (smallLogoAnimatingIn) {
                smallLogoAnimatingIn = false; // Stop "in" animation if it was active
            }
            smallLogoAnimationTimer = 0.0f; // Reset timer for "out" animation
        }

        if (smallLogoAnimatingIn) {
            smallLogoAnimationTimer += dt;
            float progress = Clamp(smallLogoAnimationTimer / smallLogoAnimationDuration, 0.0f, 1.0f);
            float easedProgress = 1.0f - pow(1.0f - progress, 3.0f); // EaseOutCubic
            smallLogoCurrentY = smallLogoStartY + (smallLogoTargetY - smallLogoStartY) * easedProgress;

            if (progress >= 1.0f) {
                smallLogoAnimatingIn = false;
                smallLogoCurrentY = smallLogoTargetY; 
            }
        } else if (smallLogoAnimatingOut) {
            smallLogoAnimationTimer += dt;
            float progress = Clamp(smallLogoAnimationTimer / smallLogoAnimationDuration, 0.0f, 1.0f);
            float easedProgress = 1.0f - pow(1.0f - progress, 3.0f); // EaseOutCubic
            smallLogoCurrentY = smallLogoTargetY + (smallLogoStartY - smallLogoTargetY) * easedProgress;

            if (progress >= 1.0f) {
                smallLogoAnimatingOut = false;
                smallLogoIsShown = false; 
                smallLogoCurrentY = smallLogoStartY; 
            }
        }

        // --- Main Menu Buttons Animation Control & Execution ---
        if ((state == TitleState.MAINMENU || state == TitleState.OPTIONS) && !mainMenuButtonsAreShown && !mainMenuButtonsAnimatingIn && !mainMenuButtonsAnimatingOut) {
            mainMenuButtonsAnimatingIn = true;
            mainMenuButtonsAnimatingOut = false; // Ensure out is false
            mainMenuButtonsAnimationTimer = 0.0f;
            mainMenuButtonCurrentX = mainMenuButtonStartX; // Start from off-screen
        } else if ((state != TitleState.MAINMENU && state != TitleState.OPTIONS) && (mainMenuButtonsAreShown || mainMenuButtonsAnimatingIn) && !mainMenuButtonsAnimatingOut) { // MODIFIED condition
            mainMenuButtonsAnimatingOut = true;
            if (mainMenuButtonsAnimatingIn) {
                mainMenuButtonsAnimatingIn = false; // Stop "in" animation if it was active
            }
            mainMenuButtonsAnimationTimer = 0.0f; // Reset timer for "out" animation
        }

        if (mainMenuButtonsAnimatingIn) {
            mainMenuButtonsAnimationTimer += dt;
            float progress = mainMenuButtonsAnimationTimer / mainMenuButtonsAnimationDuration;
            if (progress >= 1.0f) {
                progress = 1.0f;
                mainMenuButtonsAnimatingIn = false;
                mainMenuButtonsAreShown = true; // Fully shown
            }
            mainMenuButtonCurrentX = mainMenuButtonStartX + (mainMenuButtonTargetX - mainMenuButtonStartX) * (1.0f - (1.0f - progress) * (1.0f - progress)); // Ease out quad
            // Update rect X positions
            for (size_t i = 0; i < mainMenuButtonLabels.length; i++) {
                mainMenuButtonRects[i].x = mainMenuButtonCurrentX;
            }
        } else if (mainMenuButtonsAnimatingOut) {
            mainMenuButtonsAnimationTimer += dt;
            float progress = mainMenuButtonsAnimationTimer / mainMenuButtonsAnimationDuration;
            if (progress >= 1.0f) {
                progress = 1.0f;
                mainMenuButtonsAnimatingOut = false;
                mainMenuButtonsAreShown = false; // Fully hidden
                mainMenuButtonCurrentX = mainMenuButtonStartX; // Ensure it's fully off-screen
            } else {
                 mainMenuButtonCurrentX = mainMenuButtonTargetX + (mainMenuButtonStartX - mainMenuButtonTargetX) * (progress * progress); // Ease in quad
            }
            // Update rect X positions
            for (size_t i = 0; i < mainMenuButtonLabels.length; i++) {
                mainMenuButtonRects[i].x = mainMenuButtonCurrentX;
            }
        } else if (mainMenuButtonsAreShown) {
            // Ensure rects are at the target X if not animating but shown
             if (mainMenuButtonCurrentX != mainMenuButtonTargetX) { // If it somehow drifted
                mainMenuButtonCurrentX = mainMenuButtonTargetX;
             }
            for (size_t i = 0; i < mainMenuButtonLabels.length; i++) {
                mainMenuButtonRects[i].x = mainMenuButtonCurrentX; 
            }
        }


        // Handle title elements moving off screen
        if (titleElementsMovingOff) {
            bool logoOffScreen = false;
            bool logo2OffScreen = false;
            bool buttonOffScreen = false;

            // Animate logo
            if (logoPosition.y > -logoTexture.height) {
                logoPosition.y -= offScreenAnimationSpeed * dt;
            } else {
                logoOffScreen = true;
            }

            // Animate logo2
            if (logo2Position.y > -logo2Texture.height) {
                logo2Position.y -= offScreenAnimationSpeed * dt;
            } else {
                logo2OffScreen = true;
            }

            // Animate button
            // if (buttonPosition.y > -buttonTexture.height * buttonScale.y) { // Consider scale
            //    buttonPosition.y -= offScreenAnimationSpeed * deltaTime;
            // } else {
            //    buttonOffScreen = true;
            // }

            // Animate button: scale up and fade out
            if (buttonClickedOnce && buttonFadeOutAlpha > 0.0f) {
                buttonFadeOutAlpha -= 1.5f * dt; // Adjust fade speed as needed
                buttonScale.x += 0.75f * dt;      // Adjust scale speed as needed
                buttonScale.y += 0.75f * dt;
                
                // Adjust button position to keep it centered as it scales up
                // This assumes buttonPosition was its top-left for the initial pulse.
                // For scaling from center, a different approach for position and draw origin would be needed.
                // However, for simplicity, we'll let it expand from its last known top-left.
                // To keep it more centered, we might need to adjust buttonPosition here based on scale change.
                // Example:
                // float scaleDelta = 0.75f * deltaTime;
                // buttonPosition.x -= (buttonTexture.width * scaleDelta) / 2.0f;
                // buttonPosition.y -= (buttonTexture.height * scaleDelta) / 2.0f;


                if (buttonFadeOutAlpha < 0.0f) {
                    buttonFadeOutAlpha = 0.0f;
                }
            }
            
            if (buttonFadeOutAlpha <= 0.0f) {
                buttonOffScreen = true;
            }

            if (logoOffScreen && logo2OffScreen && buttonOffScreen) {
                titleElementsMovingOff = false;
                // menuGadgetsMovingOn = true; // DEFERRED: This will be set when state becomes GAMEMENU
                // Ensure gadgets start from their off-screen position, adjusted for scale
                menuGadgetsPosition = Vector2((VIRTUAL_SCREEN_WIDTH - (menuGadgetsTexture.width * menuGadgetsScale)) / 2.0f, menuGadgetsStartY); // Changed
                state = TitleState.MAINMENU; // Transition to main menu state
            }
        }

        // Handle menu gadgets moving on screen with easing
        if (menuGadgetsMovingOn) { // This block will now only execute if menuGadgetsMovingOn is explicitly set true elsewhere
            // Define all positioning variables for use in both branches
            float offsetFromTarget = menuGadgetsPosition.y - menuGadgetsTargetY;
            float centerX = VIRTUAL_SCREEN_WIDTH / 2.0f; // Changed
            float centerY;
            float topRowY;
            float bottomRowY;
            float halfWidth;
            float leftX;
            float rightX;
            
            if (abs(menuGadgetsPosition.y - menuGadgetsTargetY) > 0.5f) { // Check if not close enough to target
                menuGadgetsPosition.y += (menuGadgetsTargetY - menuGadgetsPosition.y) * menuGadgetsEasingFactor * dt;
                
                // Position buttons with same relative positions but adjusted for current gadget position
                centerY = menuGadgetsPosition.y + (menuGadgetsTexture.height * menuGadgetsScale) / 2.0f;
                topRowY = menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale * 0.22f; // Top row position
                bottomRowY = menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale * 0.67f; // Aligned with purple orbs
                halfWidth = (menuGadgetsTexture.width * menuGadgetsScale) / 2.0f;
                leftX = centerX - halfWidth * 0.49f;  // 48% from center to the left for better alignment
                rightX = centerX + halfWidth * 0.49f; // 48% from center to the right for better alignment

                classicButtonPosition = Vector2(leftX, topRowY);
                actionButtonPosition = Vector2(rightX, topRowY);
                puzzleButtonPosition = Vector2(leftX, bottomRowY);
                endlessButtonPosition = Vector2(rightX, bottomRowY);
                
                if (abs(menuGadgetsPosition.y - menuGadgetsTargetY) <= 0.5f) { // Snap if very close after easing
                    menuGadgetsPosition.y = menuGadgetsTargetY;
                    menuGadgetsMovingOn = false; // Animation complete
                    
                    // Final update to ensure buttons are in their final positions
                    centerY = menuGadgetsTargetY + (menuGadgetsTexture.height * menuGadgetsScale) / 2.0f;
                    topRowY = menuGadgetsTargetY + menuGadgetsTexture.height * menuGadgetsScale * 0.22f; // Top row position
                    bottomRowY = menuGadgetsTargetY + menuGadgetsTexture.height * menuGadgetsScale * 0.67f; // Aligned with purple orbs
                    halfWidth = (menuGadgetsTexture.width * menuGadgetsScale) / 2.0f;
                    leftX = centerX - halfWidth * 0.49f; // 48% from center for better alignment
                    rightX = centerX + halfWidth * 0.49f; // 48% from center for better alignment
                    
                    classicButtonPosition = Vector2(leftX, topRowY);
                    actionButtonPosition = Vector2(rightX, topRowY);
                    puzzleButtonPosition = Vector2(leftX, bottomRowY);
                    endlessButtonPosition = Vector2(rightX, bottomRowY);
                }
            } else {
                menuGadgetsPosition.y = menuGadgetsTargetY; // Ensure it's at target
                menuGadgetsMovingOn = false; // Animation complete
                
                // Final update for menu button positions
                centerY = menuGadgetsTargetY + (menuGadgetsTexture.height * menuGadgetsScale) / 2.0f;
                topRowY = menuGadgetsTargetY + menuGadgetsTexture.height * menuGadgetsScale * 0.22f; // Top row position
                bottomRowY = menuGadgetsTargetY + menuGadgetsTexture.height * menuGadgetsScale * 0.67f; // Aligned with purple orbs
                halfWidth = (menuGadgetsTexture.width * menuGadgetsScale) / 2.0f;
                leftX = centerX - halfWidth * 0.49f; // 48% from center for better alignment
                rightX = centerX + halfWidth * 0.49f; // 48% from center for better alignment
                
                classicButtonPosition = Vector2(leftX, topRowY);
                actionButtonPosition = Vector2(rightX, topRowY);
                puzzleButtonPosition = Vector2(leftX, bottomRowY);
                endlessButtonPosition = Vector2(rightX, bottomRowY);
            }
        }

        // Handle fade from black effect
        if (screenFadeAlpha > 0.0f) { // No change here, initial fade is fine
            screenFadeAlpha -= dt * 2.0f; 
            if (screenFadeAlpha < 0.0f) {
                screenFadeAlpha = 0.0f;
                logoAnimationStarted = true;
            }
        }

        // Handle logo rising animation with easing (only if not moving off AND button not clicked)
        if (logoAnimationStarted && !titleElementsMovingOff && !buttonClickedOnce) { // MODIFIED: Added !buttonClickedOnce
            float easingFactor = 4.0f; 
            
            static float logoPosTimer = 0.0f;
            logoPosTimer += dt;
            if (logoPosTimer >= 1.0f) {
                logoPosTimer = 0.0f;
                writeln("Logo position debug - current Y: ", logoPosition.y, " target Y: ", logoTargetY);
                writeln("Logo started: ", logoAnimationStarted);
            }
            
            if (logoPosition.y > logoTargetY) {
                logoPosition.y = logoPosition.y + (logoTargetY - logoPosition.y) * easingFactor * dt;
                if (logoPosition.y < logoTargetY) {
                    logoPosition.y = logoTargetY; // Snap to target position
                }
            }

            if (logoPosition.y <= logoTargetY) {
                logoPosition.y = logoTargetY; // Snap to target position
            }
            
            // Force logo to reach target after 3 seconds to avoid potential animation glitches
            static float logoForceTimer = 0.0f;
            logoForceTimer += dt;
            if (logoForceTimer > 3.0f && logoAnimationStarted) {
                logoPosition.y = logoTargetY;
            }
        }

        // Update position of planet
        planetPosition.y -= 1.75f * dt; // Move planet downwards
        if (planetPosition.y > VIRTUAL_SCREEN_HEIGHT) { // Changed
            planetPosition.y = -planetTexture.height; // Reset position when it goes off screen
        }
        
        // Optimize sparkle animation - don't do heavy image manipulation every frame
        // Instead update the animation less frequently
        static float sparkleUpdateTime = 0.0f;
        sparkleTimer += dt;
        sparkleUpdateTime += dt;
        
        // Only update sparkle animation every 100ms (10 times per second) instead of every frame
        if (sparkleUpdateTime >= 0.1f) {
            sparkleUpdateTime = 0.0f;
            
            for (int i = 0; i < sparkleImages.length; i++) {
                // Safely reinterpret void* as ubyte[]
                ubyte[] imageData = cast(ubyte[])sparkleImages[i].data[0 .. sparkleImages[i].width * sparkleImages[i].height * 4];
                if (imageData.length > i) {
                    imageData[i] = cast(ubyte)clamp(255.0f * sin(sparkleTimer + cast(float)i * 0.1f), 0.0f, 255.0f);
                }
            }
        }

        // Update sparkle animation
        sparkleFrameTimer += dt;
        sparkleStarTimer += dt;
        
        // Choose a new star to sparkle every few seconds
        if (!sparkleActive || sparkleStarTimer > 3.0f) {
            sparkleStarTimer = 0.0f;
            
            // Only create sparkle if we have stars
            if (stars !is null && stars.length > 0) {
                // Pick a random star to sparkle on
                sparkleStarIndex = uniform(0, cast(int)stars.length);
                sparkleActive = true;
                currentSparkleFrame = 0; // Start animation from beginning
            }
        }
        
        // Advance sparkle animation frames
        if (sparkleActive && sparkleFrameTimer > 0.05f) { // ~20 FPS for sparkle animation
            sparkleFrameTimer = 0.0f;
            currentSparkleFrame++;
            
            // If we reached the end of the animation, stop the sparkle
            if (currentSparkleFrame >= sparkleImages.length) {
                sparkleActive = false;
                currentSparkleFrame = 0;
            }
        }

        // Handle state transitions and button click
        switch (state) {
            case TitleState.LOGO:
                // Modified to only depend on fadeInComplete, not on logo position
                if (fadeInComplete) {
                    if (!buttonAppearDelayStarted) {
                        buttonAppearDelayStarted = true;
                        buttonAppearDelayTimer = 0.0f;
                    }
                    if (buttonAppearDelayTimer < 2.0f) {
                        buttonAppearDelayTimer += dt;
                    } else {
                        // Improved animation with smoother transition from scale-in to pulsing
                        static float buttonAnimTime = 0.0f;
                        buttonAnimTime += dt;
                        
                        // Combined smooth scale-in and pulse effect
                        float baseScale = 0.0f;
                        float pulseScale = 0.0f;
                        
                        // Scale-in phase (0.5 seconds)
                        if (buttonAnimTime < 0.5f) {
                            // Ease-out curve for smoother approach to 1.0
                            float t = buttonAnimTime / 0.5f;
                            baseScale = 1.0f - (1.0f - t) * (1.0f - t); // Quadratic ease-out
                            pulseScale = 0.0f; // No pulse during scale-in
                        } else {
                            baseScale = 1.0f; // Fully scaled in
                            // Gentle sine pulse (period of 2 seconds, small amplitude)
                            pulseScale = 0.05f * sin((buttonAnimTime - 0.5f) * 3.14159f); // Slower, gentler pulse
                        }
                        
                        // Apply combined scale
                        float finalScale = baseScale + pulseScale;
                        buttonScale = Vector2(finalScale, finalScale);
                        
                        // Center button position based on scale
                        buttonPosition.x = (VIRTUAL_SCREEN_WIDTH - buttonTexture.width * finalScale) / 2.0f; // Changed
                        buttonPosition.y = VIRTUAL_SCREEN_HEIGHT - buttonTexture.height * finalScale - 50.0f; // Changed
                        
                        // Button click logic
                        if (buttonScale.x >= 0.9f && IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
                            Vector2 mousePos = GetMousePositionVirtual(); // Changed
                            Rectangle buttonRect = Rectangle(
                                buttonPosition.x,
                                buttonPosition.y,
                                buttonTexture.width * buttonScale.x,
                                buttonTexture.height * buttonScale.y
                            );
                            if (CheckCollisionPointRec(mousePos, buttonRect)) {
                                if (!buttonClickedOnce) { // Only process click if not already clicked
                                    buttonClickedOnce = true; // Set flag
                                    PlaySound(welcomeSound);
                                    titleElementsMovingOff = true; // Start animation for logos and button fade
                                    buttonFadeOutAlpha = 1.0f;   // Reset alpha for fade-out animation
                                                                    // buttonScale is already pulsing, it will continue from current scale

                                    if (!isMusicPlaying) {
                                        audioManager.playMusic("resources/audio/music/arranged/Main Theme - Bejeweled 2.ogg");
                                        isMusicPlaying = true; // Make sure this is set
                                    }
                                }
                           }
                        }
                    }
                }
                break;

            case TitleState.MAINMENU:
                // If title elements are still moving off, or intro animations for this state are running, wait.
                if (titleElementsMovingOff || smallLogoAnimatingIn || mainMenuButtonsAnimatingIn) {
                    // Waiting for animations to complete
                } 
                // Interact only if buttons are shown and not currently animating in or out.
                else if (mainMenuButtonsAreShown && !mainMenuButtonsAnimatingIn && !mainMenuButtonsAnimatingOut) {
                    Vector2 mousePosition = GetMousePositionVirtual();
                    int currentHoveredButton = -1;

                    for (size_t i = 0; i < mainMenuButtonLabels.length; i++) {
                        // Use the existing mainMenuButtonRects[i] which should be correctly positioned and sized
                        // by the animation logic or the initialization if static.
                        // Ensure the Y position in the rect is also correct based on layout.
                        mainMenuButtonRects[i].x = mainMenuButtonCurrentX; // X is animated
                        mainMenuButtonRects[i].y = mainMenuButtonTopY + i * (mainMenuButtonTexture.height + mainMenuButtonVerticalGap); // Y is static based on layout
                        mainMenuButtonRects[i].width = mainMenuButtonTexture.width; // Static width from texture
                        mainMenuButtonRects[i].height = mainMenuButtonTexture.height; // Static height from texture

                        if (CheckCollisionPointRec(mousePosition, mainMenuButtonRects[i])) {
                            mainMenuButtonHoverStates[i] = true;
                            currentHoveredButton = cast(int)i;
                            if (mainMenuLastHoveredButtonIndex != currentHoveredButton) {
                                if (mainMenuMouseOverSound.frameCount > 0) PlaySound(mainMenuMouseOverSound); 
                            }
                        } else {
                            mainMenuButtonHoverStates[i] = false;
                        }
                    }
                    
                    if (currentHoveredButton == -1 && mainMenuLastHoveredButtonIndex != -1) {
                        // Optional: Play mouse off sound if needed, though Bejeweled usually doesn't
                        StopSound(mainMenuMouseOverSound); // Stop sound if no button is hovered
                        PlaySound(mainMenuMouseOffSound);
                    }
                    mainMenuLastHoveredButtonIndex = currentHoveredButton;

                    if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
                        if (currentHoveredButton != -1) { // A button is hovered
                            if (menuClickSound.frameCount > 0) PlaySound(menuClickSound);

                            switch (currentHoveredButton) {
                                case 0: // PLAY GAME
                                    if (menuClickSound.frameCount > 0) PlaySound(menuClickSound);
                                    state = TitleState.GAMEMENU;
                                    menuGadgetsMovingOn = true; 
                                    writeln("PLAY GAME clicked, transitioning to GAMEMENU");
                                    break;
                                case 1: // OPTIONS
                                    writeln("OPTIONS clicked");
                                    break;
                                case 2: // LEADERBOARDS
                                    writeln("LEADERBOARDS clicked");
                                    break;
                                case 3: // HELP
                                    writeln("HELP clicked");
                                    break;
                                case 4: // QUIT GAME
                                    writeln("QUIT GAME clicked");
                                    // Example: screenManager.requestClose = true; // If you have such a mechanism
                                    break;
                                default:
                                    break;
                            }
                        }
                    }
                }
                break;

            case TitleState.GAMEMENU: // This was formerly the logic in MAINMENU
                // If menu gadgets are still moving on screen, wait.
                if (menuGadgetsMovingOn) {
                    // Waiting for menu gadgets animation to complete
                } else {
                    // Menu gadgets (Classic, Action, etc.) interaction logic:
                    Vector2 mousePosition = GetMousePositionVirtual(); // Changed
                    
                    // Reset hover states
                    classicButtonHovered = false;
                    actionButtonHovered = false;
                    endlessButtonHovered = false;
                    puzzleButtonHovered = false;
                    toggleModesButtonHovered = false;
                    returnToMenuButtonHovered = false;
                    
                    // Calculate button collision rectangles
                    float buttonWidth = classicTexture.width * menuButtonScale;
                    float buttonHeight = classicTexture.height * menuButtonScale;
                    
                    // Create hitboxes for the four main game mode buttons
                    Rectangle classicRect = Rectangle(
                        classicButtonPosition.x - buttonWidth / 2.0f, 
                        classicButtonPosition.y - buttonHeight / 2.0f,
                        buttonWidth, buttonHeight
                    );
                    Rectangle actionRect = Rectangle(
                        actionButtonPosition.x - buttonWidth / 2.0f, 
                        actionButtonPosition.y - buttonHeight / 2.0f,
                        buttonWidth, buttonHeight
                    );
                    Rectangle endlessRect = Rectangle(
                        endlessButtonPosition.x - buttonWidth / 2.0f, 
                        endlessButtonPosition.y - buttonHeight / 2.0f,
                        buttonWidth, buttonHeight
                    );
                    Rectangle puzzleRect = Rectangle(
                        puzzleButtonPosition.x - buttonWidth / 2.0f, 
                        puzzleButtonPosition.y - buttonHeight / 2.0f,
                        buttonWidth, buttonHeight
                    );
                    
                    // Create hitboxes for the bottom menu buttons
                    float menuWidth = menuGadgetsTexture.width * menuGadgetsScale;
                    float menuHeight = 628 * menuGadgetsScale;
                    float buttonY = menuGadgetsPosition.y + menuHeight + 50.0f; // 30px below menu gadgets
                    
                    float leftButtonX = menuGadgetsPosition.x + menuWidth * 0.25f; // 25% from left
                    float rightButtonX = menuGadgetsPosition.x + menuWidth * 0.75f;

                    // Make the hitboxes larger for easier clicking (e.g., 1.5x the button image size)
                    float hitboxScale = 1.5f;
                    Rectangle toggleModesRect = Rectangle(
                        leftButtonX - (buttonWidth * hitboxScale / 2.0f), 
                        buttonY - (buttonHeight * hitboxScale / 2.0f), // Center vertically
                        buttonWidth * hitboxScale, buttonHeight * hitboxScale
                    );

                    Rectangle returnToMenuRect = Rectangle(
                        rightButtonX - (buttonWidth * hitboxScale / 2.0f),
                        buttonY - (buttonHeight * hitboxScale / 2.0f),
                        buttonWidth * hitboxScale, buttonHeight * hitboxScale
                    );

                    // Check for hover states
                    int currentHoveredButton = 0; // Track which button is currently hovered
                    
                    if (CheckCollisionPointRec(mousePosition, classicRect)) {
                        classicButtonHovered = true;
                        currentHoveredButton = 1;
                        if (lastHoveredButton != 1) {
                            // Play sound when moving to a different button
                            StopSound(mainMenuMouseOverSound);
                            PlaySound(mainMenuMouseOverSound);
                        }
                    }
                    else if (CheckCollisionPointRec(mousePosition, actionRect)) {
                        actionButtonHovered = true;
                        currentHoveredButton = 2;
                        if (lastHoveredButton != 2) {
                            // Play sound when moving to a different button
                            StopSound(mainMenuMouseOverSound);
                            PlaySound(mainMenuMouseOverSound);
                        }
                    }
                    else if (CheckCollisionPointRec(mousePosition, endlessRect)) {
                        endlessButtonHovered = true;
                        currentHoveredButton = 3;
                        if (lastHoveredButton != 3) {
                            // Play sound when moving to a different button
                            StopSound(mainMenuMouseOverSound);
                            PlaySound(mainMenuMouseOverSound);
                        }
                    }
                    else if (CheckCollisionPointRec(mousePosition, puzzleRect)) {
                        puzzleButtonHovered = true;
                        currentHoveredButton = 4;
                        if (lastHoveredButton != 4) {
                            // Play sound when moving to a different button
                            StopSound(mainMenuMouseOverSound);
                            PlaySound(mainMenuMouseOverSound);
                        }
                    }
                    
                    // Check for hover states for the bottom menu buttons
                    if (CheckCollisionPointRec(mousePosition, toggleModesRect)) {
                        toggleModesButtonHovered = true;
                        currentHoveredButton = 5;
                        if (lastHoveredButton != 5) {
                            // Play sound when moving to a different button
                            StopSound(mainMenuMouseOverSound);
                            PlaySound(mainMenuMouseOverSound);
                        }
                    }
                    else if (CheckCollisionPointRec(mousePosition, returnToMenuRect)) {
                        returnToMenuButtonHovered = true;
                        currentHoveredButton = 6;
                        if (lastHoveredButton != 6) {
                            // Play sound when moving to a different button
                            StopSound(mainMenuMouseOverSound);
                            PlaySound(mainMenuMouseOverSound);
                        }
                    }
                    
                    // Update the last hovered button
                    lastHoveredButton = currentHoveredButton;
                    
                    // Handle button clicks
                    if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
                        if (classicButtonHovered) {
                            // Play click sound when button is clicked
                            PlaySound(mainMenuGameStartSound);
                            // Start Classic game mode
                            // state = TitleState.CLASSIC_GAME; // Will need to be implemented 
                            writeln("Classic mode selected");
                        }
                        else if (actionButtonHovered) {
                            PlaySound(mainMenuGameStartSound);
                            // Start Action game mode
                            // state = TitleState.ACTION_GAME; // Will need to be implemented
                            writeln("Action mode selected");
                        }
                        else if (endlessButtonHovered) {
                            PlaySound(mainMenuGameStartSound);
                            // Start Endless game mode
                            // state = TitleState.ENDLESS_GAME; // Will need to be implemented
                            writeln("Endless mode selected");
                        }
                        else if (puzzleButtonHovered) {
                            PlaySound(mainMenuGameStartSound);
                            // Start Puzzle game mode
                            // state = TitleState.PUZZLE_GAME; // Will need to be implemented
                            writeln("Puzzle mode selected");
                        }
                        else if (toggleModesButtonHovered) {
                            PlaySound(mainMenuMouseClickSound);
                            // Toggle secret modes
                            writeln("Toggle Secret Modes selected");
                        }
                        else if (returnToMenuButtonHovered) {
                            PlaySound(mainMenuMouseClickSound);
                            state = TitleState.MAINMENU;
                            writeln("Return to Main Menu selected");
                        }
                        else {
                            // Generic click for other areas
                            audioManager.playSound("resources/audio/sfx/menuclick.ogg", AudioType.SFX, 1.0f, false);
                        }
                    }
                }
                break;

            default:
                break;
        }

        // Update star field effect
        if (stars is null) {
            // Initialize stars only once - limit to 200 stars for better performance
            int starCount = 400; // Reduced from 400 to 200 
            stars = new Star[starCount];
            for (int i = 0; i < starCount; i++) {
                stars[i] = Star(
                    x: uniform(0, VIRTUAL_SCREEN_WIDTH), // Changed
                    y: uniform(0, VIRTUAL_SCREEN_HEIGHT), // Changed
                    speed: uniform(1.0f, 5.0f),
                    color: Color(
                        r: cast(uint8_t)uniform(200, 255),
                        g: cast(uint8_t)uniform(200, 255),
                        b: cast(uint8_t)uniform(200, 255),
                        a: 255
                    )
                );
            }
        }
        else {
            // Update all stars at once
            for (int i = 0; i < stars.length; i++) {
                stars[i].update(dt);
            }
        }

        // Update logo2 fade-in effect after 2 seconds (only if not moving off AND button not clicked)
        if (!titleElementsMovingOff && !buttonClickedOnce) { // MODIFIED: Added !buttonClickedOnce
            static float logo2FadeInTimer = 0.0f;
            logo2FadeInTimer += dt;

            if (!fadeInComplete && logo2FadeInTimer >= 2.0f && whitenedLogo2Alpha < 1.0f) {
                whitenedLogo2Alpha += dt * 3.0f; 
                if (whitenedLogo2Alpha >= 1.0f) {
                    whitenedLogo2Alpha = 1.0f; 
                    fadeInComplete = true;
                }
            }
            else if (fadeInComplete && logo2FadeInTimer >= 2.4f) { 
                whitenedLogo2Alpha -= dt * 3.0f; 
                if (whitenedLogo2Alpha <= 0.0f) {
                    whitenedLogo2Alpha = 0.0f; 
                }
            }
        }

        // --- MIST SCROLLING ---
        // Scroll background mist left
        mistBackgroundOffsetX -= mistBackgroundScrollSpeed * dt;
        if (mistBackgroundOffsetX <= -mistBackgroundTexture.width) {
            mistBackgroundOffsetX += mistBackgroundTexture.width;
        }
        // Scroll foreground mist right
        mistForegroundOffsetX += mistForegroundScrollSpeed * dt;
        if (mistForegroundOffsetX >= mistForegroundTexture.width) {
            mistForegroundOffsetX -= mistForegroundTexture.width;
        }
    }

    void draw() {
        // Draw sparkle on top of a random star
        if (sparkleActive && sparkleStarIndex >= 0 && sparkleStarIndex < stars.length && sparkleFrameTextures.length > 0) {
            // Get the selected star position
            float sparkleX = stars[sparkleStarIndex].x - 20; // Center sparkle (40x40 pixels)
            float sparkleY = stars[sparkleStarIndex].y - 20;
            
            // Draw the current frame of sparkle animation
            if (currentSparkleFrame < sparkleFrameTextures.length) {
                // Get the correct sparkle frame texture
                DrawTextureEx(
                    sparkleFrameTextures[currentSparkleFrame], 
                    Vector2(sparkleX, sparkleY),
                    0.0f,  // Rotation
                    1.0f,  // Scale
                    Colors.WHITE
                );
            }
        }

        // make background 
        ClearBackground(Colors(70, 94, 150, 255));
        
        // Draw star field effect - avoid updating stars here
        if (stars !is null) {
            for (int i = 0; i < stars.length; i++) {
                // Don't call update here, it's already done in the update method
                DrawCircle(cast(int)stars[i].x, cast(int)stars[i].y, 1.0, stars[i].color);
            }
        }

        // Draw planet
        float planetScale = 1.5f; // Example scale factor
        Rectangle planetDestRec = Rectangle(planetPosition.x, planetPosition.y, planetTexture.width * planetScale, planetTexture.height * planetScale);
        DrawTexturePro(planetTexture, Rectangle(0, 0, planetTexture.width, planetTexture.height), planetDestRec, Vector2(0,0), 0.0f, Colors.WHITE);

        // Draw mist background (scrolling left, behind backdrop, in front of planet)
        if (mistBackgroundTexture.id != 0) {
            float mistY = 0;
            float mistW = mistBackgroundTexture.width;
            float mistH = mistBackgroundTexture.height;
            // Draw enough to cover the screen (repeat horizontally)
            for (float x = mistBackgroundOffsetX; x < VIRTUAL_SCREEN_WIDTH; x += mistW) { // Changed
                DrawTexturePro(
                    mistBackgroundTexture,
                    Rectangle(0, 0, mistW, mistH),
                    Rectangle(x, mistY, mistW, mistH),
                    Vector2(0, VIRTUAL_SCREEN_HEIGHT / -2.0f), // Changed 
                    0.0f,
                    Colors.WHITE
                );
            }
        }

        // Draw logo (only if not moving off or if still on screen)
        if (logoAnimationStarted && logoPosition.y < VIRTUAL_SCREEN_HEIGHT) { // Changed
            DrawTexturePro(logoTexture, Rectangle(0, 0, logoTexture.width, logoTexture.height - 1), 
                Rectangle(logoPosition.x, logoPosition.y, logoTexture.width, logoTexture.height), Vector2(0, 0), 0.0f, Colors.WHITE);
        }
        
        // Draw background
        DrawTexturePro(backgroundTexture, Rectangle(0, 0, backgroundTexture.width, backgroundTexture.height), 
            Rectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT), Vector2(0, 0), 0.0f, Colors.WHITE); // Changed

        // Draw mist foreground (scrolling right, in front of backdrop)
        if (mistForegroundTexture.id != 0) {
            float mistY = 0;
            float mistW = mistForegroundTexture.width;
            float mistH = mistForegroundTexture.height;
            for (float x = mistForegroundOffsetX - mistW; x < VIRTUAL_SCREEN_WIDTH; x += mistW) { // Changed
                DrawTexturePro(
                    mistForegroundTexture,
                    Rectangle(0, 0, mistW, mistH),
                    Rectangle(x, mistY, mistW, mistH),
                    Vector2(0, VIRTUAL_SCREEN_HEIGHT / -2.0f), // Changed
                    0.0f,
                    Colors.WHITE
                );
            }
        }

        // Draw click button with scale-in effect
        if (buttonScale.x > 0.0f) {
            float currentButtonAlpha = 1.0f;
            if (buttonClickedOnce) {
                currentButtonAlpha = buttonFadeOutAlpha;
            }

            if (currentButtonAlpha > 0.0f) { // Only draw if alpha is positive
                Texture2D textureToDraw = buttonTexture;
                Rectangle buttonRect = Rectangle( // Define buttonRect for hover check
                    buttonPosition.x,
                    buttonPosition.y,
                    buttonTexture.width * buttonScale.x,
                    buttonTexture.height * buttonScale.y
                );

                if (!buttonClickedOnce && CheckCollisionPointRec(GetMousePositionVirtual(), buttonRect)) { // Changed
                   
                    textureToDraw = buttonHoveredTexture;
                }

                DrawTexturePro(
                    textureToDraw,
                    Rectangle(0, 0, textureToDraw.width, textureToDraw.height),
                    Rectangle(
                        buttonPosition.x,
                        buttonPosition.y,
                        textureToDraw.width * buttonScale.x,
                        textureToDraw.height * buttonScale.y
                    ),
                    Vector2(0, 0), // Origin top-left
                    0.0f,
                    Fade(Colors.WHITE, currentButtonAlpha) // Use currentButtonAlpha
                );
            }
            
            // DEBUG: Print button position and scale info once per second
            static float debugTimer = 0.0f;
            debugTimer += GetFrameTime();
            if (debugTimer >= 1.0f) {
                debugTimer = 0.0f;
                writeln("Button DEBUG - Scale: ", buttonScale, " Position: ", buttonPosition);
                writeln("Button Texture - Width: ", buttonTexture.width, " Height: ", buttonTexture.height);
                writeln("Logo position: ", logoPosition, " Target: ", logoTargetY, " FadeComplete: ", fadeInComplete);
                writeln("Button delay timer: ", buttonAppearDelayTimer);
            }
        }
        else {
            // DEBUG: Print why button is not being drawn
            static float noButtonTimer = 0.0f;
            noButtonTimer += GetFrameTime();
            if (noButtonTimer >= 2.0f) {
                noButtonTimer = 0.0f;
                writeln("Button not drawn. Scale: ", buttonScale);
                writeln("Logo reached target: ", (logoPosition.y <= logoTargetY));
                writeln("Fade complete: ", fadeInComplete);
                writeln("Button delay: ", buttonAppearDelayTimer);
            }
        }

        // Draw the actual logo2 texture if the fade is complete and it's on screen
        if (fadeInComplete && logo2Position.y < VIRTUAL_SCREEN_HEIGHT && logo2Position.y > -logo2Texture.height) { // Changed
            DrawTexturePro(logo2Texture, Rectangle(0, 0, logo2Texture.width, logo2Texture.height), 
                Rectangle(logo2Position.x, logo2Position.y, logo2Texture.width, logo2Texture.height), Vector2(0, 0), 0.0f, Colors.WHITE);
        }

        // Draw the whitened logo2 texture (if on screen)
        if (whitenedLogo2Alpha > 0.0f && logo2Position.y < VIRTUAL_SCREEN_HEIGHT && logo2Position.y > -logo2Texture.height) { // Changed
            DrawTextureEx(whitenedLogo2Texture, 
                logo2Position, 
                0.0f, 1.0f, 
                Color(255, 255, 255, cast(uint8_t)(255 * whitenedLogo2Alpha)));
        }

        // Animate the subtitle (REMASTERED) logo scaling from large to 0.5f
        static float subtitleAnimTimer = 0.0f;
        static bool subtitleAnimStarted = false;
        static float subtitleScaleAnimated = 2.5f; // Start really huge

        if (whitenedLogo2Alpha == 0.0f && fadeInComplete) { // Only draw subtitle if logo2 is faded out
            if (!subtitleAnimStarted) {
                subtitleAnimStarted = true;
                subtitleAnimTimer = 0.0f;
                subtitleScaleAnimated = 2.5f; // Reset to huge
            }
            // Animate scale down over 0.35 seconds
            if (subtitleScaleAnimated > 0.5f) {
                subtitleAnimTimer += GetFrameTime();
                float t = clamp(subtitleAnimTimer / 0.35f, 0.0f, 1.0f);
                // Ease out cubic for smooth effect
                float eased = 1.0f - pow(1.0f - t, 3.0f);
                subtitleScaleAnimated = 2.5f + (0.5f - 2.5f) * eased;
                if (subtitleScaleAnimated < 0.5f) subtitleScaleAnimated = 0.5f;
            }
            float scaledSubtitleWidth = subtitleTexture.width * subtitleScaleAnimated;
            float scaledSubtitleHeight = subtitleTexture.height * subtitleScaleAnimated;
            DrawTexturePro(
                subtitleTexture,
                Rectangle(0, 0, subtitleTexture.width, subtitleTexture.height),
                Rectangle(
                    VIRTUAL_SCREEN_WIDTH / 2 - scaledSubtitleWidth / 2,
                    logo2Position.y + logo2Texture.height * 0.5f + 20.0f,
                    scaledSubtitleWidth,
                    scaledSubtitleHeight
                ),
                Vector2(0, 0),
                0.0f,
                Colors.WHITE
            );
        } else {
            // Reset animation state if not visible
            subtitleAnimStarted = false;
            subtitleAnimTimer = 0.0f;
            subtitleScaleAnimated = 2.5f;
        }
 
        // Draw fade from black overlay last so it covers everything
        if (screenFadeAlpha > 0.0f) {
            DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, // Changed
                         Fade(Colors.BLACK, screenFadeAlpha));
        }

        // Draw the button (change to hovered texture if mouse is over it)
        Vector2 mousePos = GetMousePositionVirtual(); // Changed
        Rectangle buttonRect = Rectangle(
            buttonPosition.x, 
            buttonPosition.y, 
            buttonTexture.width * buttonScale.x, 
            buttonTexture.height * buttonScale.y
        );

        // Draw menu gadgets if they are on screen or moving
        if (state == TitleState.GAMEMENU && (menuGadgetsOnScreen() || menuGadgetsMovingOn)) {
            // Draw the menu gadgets (main frame) at correct scale and position
            Rectangle srcRec = Rectangle(0, 0, menuGadgetsTexture.width, 628); // Crop at 628px height
            Rectangle dstRec = Rectangle(
                menuGadgetsPosition.x,
                menuGadgetsPosition.y,
                menuGadgetsTexture.width * menuGadgetsScale,
                628 * menuGadgetsScale // Use cropped height
            );
            DrawTexturePro(menuGadgetsTexture, srcRec, dstRec, Vector2(0, 0), 0.0f, Colors.WHITE);

            // Calculate button positions relative to menu gadgets frame
            float menuWidth = menuGadgetsTexture.width * menuGadgetsScale;
            float menuHeight = 628 * menuGadgetsScale; // Use cropped height
            
            float leftX = menuGadgetsPosition.x + menuWidth * 0.255f; 
            float rightX = menuGadgetsPosition.x + menuWidth * 0.745f; 
            float topY = menuGadgetsPosition.y + menuHeight * 0.272f;
            float bottomY = menuGadgetsPosition.y + menuHeight * 0.81f;

            // --- Draw Button Images with Hover Scale ---
            float baseButtonScale = 1.0f;
            float hoverButtonScale = 1.1f;

            // Classic (top left)
            float classicCurrentScale = classicButtonHovered ? hoverButtonScale : baseButtonScale;
            Vector2 classicPos = Vector2(
                leftX - (classicTexture.width * classicCurrentScale / 2.0f), 
                topY - (classicTexture.height * classicCurrentScale / 2.0f)
            );
            DrawTextureEx(classicTexture, classicPos, 0.0f, classicCurrentScale, Colors.WHITE);

            // Action (top right)
            float actionCurrentScale = actionButtonHovered ? hoverButtonScale : baseButtonScale;
            Vector2 actionPos = Vector2(
                rightX - (actionTexture.width * actionCurrentScale / 2.0f), 
                topY - (actionTexture.height * actionCurrentScale / 2.0f)
            );
            DrawTextureEx(actionTexture, actionPos, 0.0f, actionCurrentScale, Colors.WHITE);

            // Puzzle (bottom left)
            float puzzleCurrentScale = puzzleButtonHovered ? hoverButtonScale : baseButtonScale;
            Vector2 puzzlePos = Vector2(
                leftX - (puzzleTexture.width * puzzleCurrentScale / 2.0f), 
                bottomY - (puzzleTexture.height * puzzleCurrentScale / 2.0f)
            );
            DrawTextureEx(puzzleTexture, puzzlePos, 0.0f, puzzleCurrentScale, Colors.WHITE);
            
            // Endless (bottom right)
            float endlessCurrentScale = endlessButtonHovered ? hoverButtonScale : baseButtonScale;
            Vector2 endlessPos = Vector2(
                rightX - (endlessTexture.width * endlessCurrentScale / 2.0f), 
                bottomY - (endlessTexture.height * endlessCurrentScale / 2.0f)
            );
            DrawTextureEx(endlessTexture, endlessPos, 0.0f, endlessCurrentScale, Colors.WHITE);

            // --- Draw Sub-Text Overlays (using Quincy font) ---
            float textFontSize = 20.0f; // You can adjust this
            Color textColor = Colors.WHITE;
            Font subTextFont = app.fontFamily[4]; // Quincy font

            // Y offset for the sub-label text from the *bottom* of the button image.
            float subLabelYOffsetFromImageBottom = 8.0f; // Adjust for desired spacing

            // --- Classic Button Sub-Text ---
            if (classicLevelText != "") {
                float classicButtonImageBottomY = topY + (classicTexture.height * classicCurrentScale / 2.0f);
                Vector2 classicLevelTextSize = MeasureTextEx(subTextFont, classicLevelText.toStringz(), textFontSize, 1.0f);
                float classicLevelTextX = leftX - classicLevelTextSize.x / 2.0f;
                float classicLevelTextY = classicButtonImageBottomY + subLabelYOffsetFromImageBottom;
                
                DrawTextEx(subTextFont, classicLevelText.toStringz(), 
                          Vector2(classicLevelTextX, classicLevelTextY), 
                          textFontSize, 1.0f, textColor);
            }
            
            // --- Action Button Sub-Text ---
            if (actionLevelText != "") {
                float actionButtonImageBottomY = topY + (actionTexture.height * actionCurrentScale / 2.0f);
                Vector2 actionLevelTextSize = MeasureTextEx(subTextFont, actionLevelText.toStringz(), textFontSize, 1.0f);
                float actionLevelTextX = rightX - actionLevelTextSize.x / 2.0f;
                float actionLevelTextY = actionButtonImageBottomY + subLabelYOffsetFromImageBottom;
                
                DrawTextEx(subTextFont, actionLevelText.toStringz(), 
                          Vector2(actionLevelTextX, actionLevelTextY), 
                          textFontSize, 1.0f, textColor);
            }
            
            // --- Puzzle Button Sub-Text ---
            if (puzzlePercentText != "") {
                 float puzzleButtonImageBottomY = bottomY + (puzzleTexture.height * puzzleCurrentScale / 2.0f);
                 Vector2 puzzlePercentTextSize = MeasureTextEx(subTextFont, puzzlePercentText.toStringz(), textFontSize, 1.0f);
                 float puzzlePercentTextX = leftX - puzzlePercentTextSize.x / 2.0f;
                 float puzzlePercentTextY = puzzleButtonImageBottomY + subLabelYOffsetFromImageBottom;
                 
                 DrawTextEx(subTextFont, puzzlePercentText.toStringz(), 
                           Vector2(puzzlePercentTextX, puzzlePercentTextY), 
                           textFontSize, 1.0f, textColor);
            }
            
            // --- Endless Button Sub-Text ---
            if (endlessLevelText != "") {
                float endlessButtonImageBottomY = bottomY + (endlessTexture.height * endlessCurrentScale / 2.0f);
                Vector2 endlessLevelTextSize = MeasureTextEx(subTextFont, endlessLevelText.toStringz(), textFontSize, 1.0f);
                float endlessLevelTextX = rightX - endlessLevelTextSize.x / 2.0f;
                float endlessLevelTextY = endlessButtonImageBottomY + subLabelYOffsetFromImageBottom;
                
                DrawTextEx(subTextFont, endlessLevelText.toStringz(), 
                          Vector2(endlessLevelTextX, endlessLevelTextY), 
                          textFontSize, 1.0f, textColor);
            }

            // Draw the welcome text above the select game mode text
            float welcomeTextFontSize = 24.0f;
            float welcomeTextY = menuGadgetsPosition.y + 42.0f;
            float welcomeTextX = menuGadgetsPosition.x + (menuGadgetsTexture.width * menuGadgetsScale) / 2.0f - MeasureTextEx(app.fontFamily[2], welcomeText.toStringz(), welcomeTextFontSize, 1.0f).x / 2.0f;
            DrawTextEx(app.fontFamily[2], welcomeText.toStringz(), Vector2(welcomeTextX, welcomeTextY), welcomeTextFontSize, 1.0f, Colors.WHITE);

            // Draw the select game mode text at the top of the menu gadgets
            float selectTextFontSize = 18.0f;
            float selectTextY = menuGadgetsPosition.y + 76.0f;
            float selectTextX = menuGadgetsPosition.x + (menuGadgetsTexture.width * menuGadgetsScale) / 2.0f - MeasureTextEx(app.fontFamily[0], selectGameModeText.toStringz(), selectTextFontSize, 1.0f).x / 2.0f;
            DrawTextEx(app.fontFamily[0], selectGameModeText.toStringz(), Vector2(selectTextX, selectTextY), selectTextFontSize, 1.0f, Colors.WHITE);
        
               BeginBlendMode(BlendMode.BLEND_ALPHA); // Enable alpha blending
    
                if (classicButtonHovered) {
                    Vector2 hoverPos = Vector2(
                        leftX + 3.0f - (orbHoverTexture.width / 2.0f), // Center the hover texture
                        topY - (orbHoverTexture.height / 2.0f)
                    );
                    DrawTextureEx(orbHoverTexture, hoverPos, 0.0f, 1.0f, Color(255, 170, 230, 255)); // Lighter pink
                }
                if (actionButtonHovered) {
                    Vector2 hoverPos = Vector2(
                        rightX - (orbHoverTexture.width / 2.0f),
                        topY - (orbHoverTexture.height / 2.0f)
                    );
                    DrawTextureEx(orbHoverTexture, hoverPos, 0.0f, 1.0f, Color(255, 170, 230, 255)); // Brighter pink
                }
                if (puzzleButtonHovered) {
                    Vector2 hoverPos = Vector2(
                        leftX + 3.0f - (orbHoverTexture.width / 2.0f),
                        bottomY - (orbHoverTexture.height / 2.0f)
                    );
                    DrawTextureEx(orbHoverTexture, hoverPos, 0.0f, 1.0f, Color(255, 170, 230, 255)); // Brighter pink
                }
                if (endlessButtonHovered) {
                    Vector2 hoverPos = Vector2(
                        rightX - (orbHoverTexture.width / 2.0f),
                        bottomY - (orbHoverTexture.height / 2.0f)
                    );
                    DrawTextureEx(orbHoverTexture, hoverPos, 0.0f, 1.0f, Color(255, 170, 230, 255)); // Brighter pink
                }
    
                EndBlendMode(); // Disable alpha blending
        }
        
        // Draw the game menu buttons
        if (state == TitleState.GAMEMENU) {
            float menuWidth = menuGadgetsTexture.width * menuGadgetsScale;
            float menuHeight = 628 * menuGadgetsScale;
            float buttonY = menuGadgetsPosition.y + menuHeight + 50.0f; // 30px below menu gadgets
            
            // Left button - "Toggle Secret Modes"
            float leftButtonX = menuGadgetsPosition.x + menuWidth * 0.25f;
            DrawTextureEx(mainMenuButtonTexture, 
                Vector2(leftButtonX - (mainMenuButtonTexture.width / 2.0f), 
                        buttonY - (mainMenuButtonTexture.height / 2.0f)), 
                0.0f, 1.0f, Colors.WHITE);
            
            // Right button - "Return to Main Menu"
            float rightButtonX = menuGadgetsPosition.x + menuWidth * 0.75f;
            DrawTextureEx(mainMenuButtonTexture, 
                Vector2(rightButtonX - (mainMenuButtonTexture.width / 2.0f), 
                        buttonY - (mainMenuButtonTexture.height / 2.0f)), 
                0.0f, 1.0f, Colors.WHITE);

            // Draw button hover effects
            BeginBlendMode(BlendMode.BLEND_ADDITIVE); // Use additive blending for highlight

            // Set highlight scale factors
            float highlightScaleX = 1.7f;
            float highlightScaleY = 1.5f;

            float scaledHighlightWidth = mainMenuButtonHighlightTexture.width * highlightScaleX;
            float scaledHighlightHeight = mainMenuButtonHighlightTexture.height * highlightScaleY;

            // Calculate highlight positions for each button
            float toggleHighlightX = leftButtonX - (mainMenuButtonHighlightTexture.width * highlightScaleX) / 2.0f;
            float toggleHighlightY = buttonY - (mainMenuButtonHighlightTexture.height * highlightScaleY) / 3.0f;
            float returnHighlightX = rightButtonX - (mainMenuButtonHighlightTexture.width * highlightScaleX) / 2.0f;
            float returnHighlightY = buttonY - (mainMenuButtonHighlightTexture.height * highlightScaleY) / 3.0f;

            if (toggleModesButtonHovered) {
                DrawTexturePro(
                    mainMenuButtonHighlightTexture,
                    Rectangle(0, 0, mainMenuButtonHighlightTexture.width, mainMenuButtonHighlightTexture.height),
                    Rectangle(toggleHighlightX, toggleHighlightY, scaledHighlightWidth, scaledHighlightHeight),
                    Vector2(0, 0), // Origin top-left
                    0.0f,
                    Colors.WHITE
                );
            }
            else if (returnToMenuButtonHovered) {
                DrawTexturePro(
                    mainMenuButtonHighlightTexture,
                    Rectangle(0, 0, mainMenuButtonHighlightTexture.width, mainMenuButtonHighlightTexture.height),
                    Rectangle(returnHighlightX, returnHighlightY, scaledHighlightWidth, scaledHighlightHeight),
                    Vector2(0, 0), // Origin top-left
                    0.0f,
                    Colors.WHITE
                );
            }
            EndBlendMode();
            
            // Draw button text
            float buttonTextSize = 28.0f;
            
            // "Toggle Secret Modes" text
            Vector2 toggleTextSize = MeasureTextEx(app.fontFamily[1], toggleModesText.toStringz(), buttonTextSize, 1.0f);
            float toggleTextX = leftButtonX - toggleTextSize.x / 2.0f;
            float toggleTextY = buttonY - toggleTextSize.y / 3.0f; // Adjusted to center vertically
            DrawTextEx(app.fontFamily[1], toggleModesText.toStringz(),
                        Vector2(toggleTextX, toggleTextY),
                        buttonTextSize, 1.0f, Colors.WHITE);
            // Make blue outline for text
            BeginBlendMode(BlendMode.BLEND_ADDITIVE);
            DrawTextEx(app.fontFamily[1], toggleModesText.toStringz(), Vector2(toggleTextX + 1, toggleTextY + 1), buttonTextSize, 1.0f, Colors.BLUE);
            EndBlendMode();
            
            // "Return to Main Menu" text
            Vector2 returnTextSize = MeasureTextEx(app.fontFamily[1], returnToMenuText.toStringz(), buttonTextSize, 1.0f);
            float returnTextX = rightButtonX - returnTextSize.x / 2.0f;
            float returnTextY = buttonY - returnTextSize.y / 3.0f; // Adjusted to center vertically
            DrawTextEx(app.fontFamily[1], returnToMenuText.toStringz(),
                        Vector2(returnTextX, returnTextY),
                        buttonTextSize, 1.0f, Colors.WHITE);
            // Make blue outline for text
            BeginBlendMode(BlendMode.BLEND_ADDITIVE);
            DrawTextEx(app.fontFamily[1], returnToMenuText.toStringz(), Vector2(returnTextX + 1, returnTextY + 1), buttonTextSize, 1.0f, Colors.BLUE);
            EndBlendMode();
        }

        // Draw Main Menu Buttons if they should be shown or animating
        if (mainMenuButtonsAreShown || mainMenuButtonsAnimatingIn || mainMenuButtonsAnimatingOut) {
            if (mainMenuButtonTexture.id != 0) { // Only draw if texture is valid
                for (size_t i = 0; i < mainMenuButtonLabels.length; i++) {
                    float buttonY = mainMenuButtonTopY + i * (mainMenuButtonTexture.height + mainMenuButtonVerticalGap);

                    // Draw Button Texture
                    DrawTexture(mainMenuButtonTexture, cast(int)mainMenuButtonCurrentX, cast(int)buttonY, Colors.WHITE);

                    // Draw Highlight if hovered (and highlight texture is valid) - ON TOP with ADDITIVE BLEND
                    if (mainMenuButtonHoverStates[i] && mainMenuButtonHighlightTexture.id != 0) {
                        BeginBlendMode(BlendMode.BLEND_ADDITIVE); // Use additive blending for highlight
                        
                        // Set highlight scale factors
                        float highlightScaleX = 1.7f;
                        float highlightScaleY = 1.5f; // Use highlightScaleY instead of highlightScale

                        // Calculate centered position for the scaled highlight
                        float scaledHighlightWidth = mainMenuButtonHighlightTexture.width * highlightScaleX;
                        float scaledHighlightHeight = mainMenuButtonHighlightTexture.height * highlightScaleY;

                        float highlightX = mainMenuButtonCurrentX + (mainMenuButtonTexture.width - scaledHighlightWidth) / 2.0f;
                        float highlightY = buttonY + (mainMenuButtonTexture.height - scaledHighlightHeight) / 2.0f;

                        // Draw the scaled highlight texture
                        DrawTexturePro(
                            mainMenuButtonHighlightTexture,
                            Rectangle(0, 0, mainMenuButtonHighlightTexture.width, mainMenuButtonHighlightTexture.height),
                            Rectangle(highlightX, highlightY, scaledHighlightWidth, scaledHighlightHeight),
                            Vector2(0, -10.0f), // Adjust origin to center the highlight
                            0.0f,
                            Colors.WHITE
                        );
                        EndBlendMode();
                    }

                    // Draw Text (centered on the button)
                    Vector2 textSize = MeasureTextEx(app.fontFamily[1], mainMenuButtonLabels[i].toStringz(), mainMenuButtonFontSize, 1.0f);
                    float textX = mainMenuButtonCurrentX + (mainMenuButtonTexture.width - textSize.x) / 2.0f;
                    float textY = buttonY + (mainMenuButtonTexture.height - textSize.y) * (2.0f / 3.0f); // Adjusted to center vertically

                    DrawTextEx(app.fontFamily[1], mainMenuButtonLabels[i].toStringz(), Vector2(textX, textY), mainMenuButtonFontSize, 1.0f, Colors.WHITE);
                    // Make blue outline for text
                    BeginBlendMode(BlendMode.BLEND_ADDITIVE);
                    DrawTextEx(app.fontFamily[1], mainMenuButtonLabels[i].toStringz(), Vector2(textX + 1, textY + 1), mainMenuButtonFontSize, 1.0f, Colors.BLUE);
                    EndBlendMode();
                }
            } else { // Fallback to drawing text only if texture failed (matches old behavior)
                for (size_t i = 0; i < mainMenuButtonLabels.length; i++) {
                    // This uses the old text-based spacing logic if texture failed.
                    float textBasedSpacingY = mainMenuButtonFontSize + 18.0f;
                    float buttonY = mainMenuButtonTopY + i * textBasedSpacingY; // mainMenuButtonTopY would be text-based from init fallback
                    
                    Color textColor = mainMenuButtonHoverStates[i] ? Colors.YELLOW : Colors.WHITE;
                    DrawTextEx(app.fontFamily[1], mainMenuButtonLabels[i].toStringz(), Vector2(mainMenuButtonCurrentX, buttonY), mainMenuButtonFontSize, 1.0f, textColor);
                }
            }
        }

        // Draw small top-left logos if they should be shown
        if (smallLogoIsShown) {
            Vector2 topLeftBejeweledPos = Vector2(smallLogoBasePosition.x, smallLogoCurrentY);
            Vector2 topLeft2Pos = Vector2(
                smallLogoBasePosition.x + smallLogo2RelativePosition.x,
                smallLogoCurrentY + smallLogo2RelativePosition.y
            );

            DrawTextureEx(logoTexture, topLeftBejeweledPos, 0.0f, smallLogoScale, Colors.WHITE);
            DrawTextureEx(logo2Texture, topLeft2Pos, 0.0f, smallLogoScale, Colors.WHITE);
        
            // Include the subtitle
            float smallSubtitleScale = smallLogoScale * 0.5f; // Scale down subtitle
            float subtitleWidth = subtitleTexture.width * smallSubtitleScale;
            float subtitleHeight = subtitleTexture.height * smallSubtitleScale;
            Vector2 subtitlePos = Vector2(
                topLeftBejeweledPos.x + (logoTexture.width * smallLogoScale - subtitleWidth) / 2.0f,
                topLeftBejeweledPos.y + logoTexture.height * smallLogoScale + 10.0f // 10px below the logo
            );
            DrawTexturePro(
                subtitleTexture,
                Rectangle(0, 0, subtitleTexture.width, subtitleTexture.height),
                Rectangle(subtitlePos.x, subtitlePos.y, subtitleWidth, subtitleHeight),
                Vector2(0, 0), // Origin top-left
                0.0f,
                Colors.WHITE
            );
        }

        // Draw fade from black effect
        if (screenFadeAlpha > 0.0f) {
            DrawRectangle(0, 0, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, Fade(Colors.BLACK, screenFadeAlpha));
        }

        // DEBUG: Draw current state
        string stateText = "State: " ~ to!string(state);
        DrawTextEx(app.fontFamily[4], stateText.toStringz(), Vector2(10, VIRTUAL_SCREEN_HEIGHT - 30), 20, 1.0f, Colors.WHITE);

        // Draw Copyright Text in LOGO state
        if (state == TitleState.LOGO) {
            float copyrightFontSize = 16.0f;
            Vector2 copyrightTextSize = MeasureTextEx(app.fontFamily[4], copyrightText.toStringz(), copyrightFontSize, 1.0f);
            float copyrightX = VIRTUAL_SCREEN_WIDTH - copyrightTextSize.x - 10; // 10 pixels from right edge
            float copyrightY = VIRTUAL_SCREEN_HEIGHT - copyrightTextSize.y - 10; // 10 pixels from bottom edge
            DrawTextEx(app.fontFamily[4], copyrightText.toStringz(), Vector2(copyrightX, copyrightY), copyrightFontSize, 1.0f, Colors.LIGHTGRAY);
        }

        // Draw the name entry if it is active
        if (state == TitleState.OPTIONS && nameEntryDialog.hasNameEntry()) {
            nameEntryDialog.draw();    
        }
    }

    void unload() {
        // Unload textures
        UnloadTexture(backgroundTexture);
        UnloadTexture(logoTexture);
        UnloadTexture(logoAlpha);
        UnloadTexture(logo2Texture);
        UnloadTexture(logo2Alpha);
        UnloadTexture(buttonTexture);
        UnloadTexture(buttonHoveredTexture);
        UnloadTexture(buttonAlpha);
        UnloadTexture(sparkleTexture);
        UnloadTexture(planetTexture);
        UnloadTexture(planetAlpha);
        UnloadTexture(whitenedLogo2Texture);
        UnloadTexture(menuGadgetsTexture);
        UnloadTexture(menuGadgetsAlpha);
        UnloadTexture(mistBackgroundTexture);
        UnloadTexture(mistForegroundTexture);
        UnloadTexture(classicTexture);
        UnloadTexture(classicAlpha);
        UnloadTexture(actionTexture);
        UnloadTexture(actionAlpha);
        UnloadTexture(endlessTexture);
        UnloadTexture(endlessAlpha);
        UnloadTexture(puzzleTexture);
        UnloadTexture(puzzleAlpha);

        // New: Unload Main Menu Button Textures
        UnloadTexture(mainMenuButtonTexture);
        UnloadTexture(mainMenuButtonHighlightTexture);
        UnloadTexture(mainMenuButtonHighlightAlphaTexture);

        // Unload sounds
        UnloadSound(welcomeSound);
        UnloadSound(welcomeBackSound);
        UnloadSound(menuClickSound);
        UnloadSound(menuClick2Sound);
        UnloadSound(mainMenuMouseOverSound);
        UnloadSound(mainMenuMouseClickSound);
        UnloadSound(mainMenuMouseOffSound);
        UnloadSound(click2Sound);
        UnloadSound(mainMenuGameStartSound);

        // Reset state
        state = TitleState.LOGO;
    }
    
}