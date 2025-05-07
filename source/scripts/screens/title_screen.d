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

import world.screen_manager;
import world.memory_manager;
import world.audio_manager;
import world.screen_states;
import app; // Import the app module directly

// No need to redeclare fontFamily, it's already imported from app module

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
        if (y > GetScreenHeight()) {
            y = 0.0f;
            x = uniform(0, GetScreenWidth());
        }
    }
}

// ---- CLASS ----
class TitleScreen : IScreen {
    // Singleton instance
    private __gshared TitleScreen instance;
    private MemoryManager memoryManager;
    private AudioManager audioManager;

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
    private float menuGadgetsScale = 0.88f; // Adjusted scale for better fit with original game
    private float menuGadgetsEasingFactor = 4.0f; // New: Easing for menu gadgets movement

    // Resources to preload
    private string[] texturesToPreload;
    private string[] soundsToPreload;
    private string[] musicToPreload;
    
    private Star[] stars; // Array of stars for star field effect

    // Button click state and fade-out animation
    private bool buttonClickedOnce = false;
    private float buttonFadeOutAlpha = 1.0f;
    
    // Menu UI text elements
    static string saveNameText = "Player"; // Will be populated conditionally
    private string selectGameModeText = "Select a game mode.";
    private string welcomeText; // Will be set in constructor or initialize
    private string originalGameText = "THE ORIGINAL\nUNTIMED GAME";
    private string classicLevelText = "";  // Will be populated conditionally
    private string actionLevelText = "";   // Will be populated conditionally
    private string puzzlePercentText = "0%"; // Changed to 0% as requested
    private string endlessLevelText = "LEVEL 1"; // Keep showing Level 1 for Endless
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
        welcomeText = "Welcome, " ~ saveNameText ~ "!";

        texturesToPreload = [
            // Textures for the title screen
            "resources/image/title_loaderbar_clickhere.png",
            "resources/image/title_loaderbar_clickhere_over.png",
            "resources/image/title_loaderbarlit_.png", // alpha
            "resources/image/title_logo.png",
            "resources/image/title_logo_.png", // alpha
            "resources/image/title_logo2.png",
            "resources/image/title_logo2_.png", // alpha
            "resources/image/sparkle.png", // same texture is used for alpha
            "resources/image/backdrops/backdrop_title_A.png",
            "resources/image/planet1.png",
            "resources/image/planet1_.png", // alpha
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
            "resources/image/Puzzle_.png" // alpha
            // add more later
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

        // Load textures
        backgroundTexture = LoadTexture("resources/image/backdrops/backdrop_title_A.png");
        logoTexture = LoadTexture("resources/image/title_logo.png");
        logoAlpha = LoadTexture("resources/image/title_logo_.png");
        logo2Texture = LoadTexture("resources/image/title_logo2.png");
        logo2Alpha = LoadTexture("resources/image/title_logo2_.png");
        buttonTexture = LoadTexture("resources/image/title_loaderbar_clickhere.png");
        buttonHoveredTexture = LoadTexture("resources/image/title_loaderbar_clickhere_over.png");
        buttonAlpha = LoadTexture("resources/image/title_loaderbarlit_.png");
        sparkleTexture = LoadTexture("resources/image/sparkle.png");
        planetTexture = LoadTexture("resources/image/planet1.png");
        planetAlpha = LoadTexture("resources/image/planet1_.png");
        menuGadgetsTexture = LoadTexture("resources/image/Menu-Gadgets.png");
        menuGadgetsAlpha = LoadTexture("resources/image/Menu-Gadgets_.png");
        
        // Load menu button textures
        classicTexture = LoadTexture("resources/image/Classic.png");
        classicAlpha = LoadTexture("resources/image/Classic_.png");
        actionTexture = LoadTexture("resources/image/Action.png");
        actionAlpha = LoadTexture("resources/image/Action_.png");
        endlessTexture = LoadTexture("resources/image/Endless.png");
        endlessAlpha = LoadTexture("resources/image/Endless_.png");
        puzzleTexture = LoadTexture("resources/image/Puzzle.png");
        puzzleAlpha = LoadTexture("resources/image/Puzzle_.png");

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
        mainMenuGameStartSound = LoadSound("resources/audio/sfx/mainmenu_gamestart.ogg");

        // Set initial state
        state = TitleState.LOGO;
        
        // Check for saved game files (for demo, these are set to false)
        // TODO: Add actual save file detection
        hasClassicSavedGame = false;
        hasActionSavedGame = false;
        
        // Set up level text based on saved game state
        if (hasClassicSavedGame) {
            classicLevelText = "LEVEL 2";
        }
        
        if (hasActionSavedGame) {
            actionLevelText = "LEVEL 1";
        }

        alphaMapTextures();
        sliceSparkleTextures();

        // Initialize positions
        logoTargetY = (GetScreenHeight() - logoTexture.height) / 8;
        logoStartY = GetScreenHeight() + 50.0f; // Start below screen
        logoPosition = Vector2((GetScreenWidth() - logoTexture.width) / 2.0f, GetScreenHeight()); // Start below screen
        logo2Position = Vector2((GetScreenWidth() - logo2Texture.width) / 2.0f, (GetScreenHeight() - logo2Texture.height) / 3.0f);
        buttonPosition = Vector2((GetScreenWidth() - buttonTexture.width) / 2.0f, GetScreenHeight() - buttonTexture.height - 50.0f);
        planetPosition = Vector2(GetScreenWidth() - (planetTexture.width / (3.0/2.0)), GetScreenHeight() - planetTexture.height);
        buttonScale = Vector2(0, 0);

        // Initialize menu gadgets positions
        menuGadgetsTargetY = (GetScreenHeight() - (menuGadgetsTexture.height * menuGadgetsScale)) / 2.0f; // Adjusted for scale
        menuGadgetsStartY = GetScreenHeight(); // Start below screen
        menuGadgetsPosition = Vector2((GetScreenWidth() - (menuGadgetsTexture.width * menuGadgetsScale)) / 2.0f, menuGadgetsStartY); // Adjusted for scale
        
        // Initialize menu button positions centered within menu gadgets texture
        // Calculate the center point of the menu gadgets
        centerX = GetScreenWidth() / 2.0f;
        centerY = menuGadgetsTargetY + (menuGadgetsTexture.height * menuGadgetsScale) / 2.0f;
        
        // Position buttons precisely to match the reference image
        // Set position values to match the desired menu layout
        float topRowY = menuGadgetsTargetY + menuGadgetsTexture.height * menuGadgetsScale * 0.22f; // Keep top row at this good position
        float bottomRowY = menuGadgetsTargetY + menuGadgetsTexture.height * menuGadgetsScale * 0.67f; // Adjusted to align with purple orbs
        
        // Position buttons horizontally to align with the circles - closer to center than before
        float halfWidth = (menuGadgetsTexture.width * menuGadgetsScale) / 2.0f;
        float leftX = centerX - halfWidth * 0.48f;  // 48% from center to the left (for better alignment)
        float rightX = centerX + halfWidth * 0.48f; // 48% from center to the right (for better alignment)

        classicButtonPosition = Vector2(leftX, topRowY);
        actionButtonPosition = Vector2(rightX, topRowY);
        // Swap Endless and Puzzle positions based on the screenshot
        puzzleButtonPosition = Vector2(leftX, bottomRowY);
        endlessButtonPosition = Vector2(rightX, bottomRowY);
    
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
        
        // Apply alpha mapping to logo textures
        ImageAlphaMask(&logoImage, logoAlphaImage);
        logoTexture = LoadTextureFromImage(logoImage);
        // UnloadImage(logoAlphaImage); // Commented out to avoid double free
        // Apply alpha mapping to logo2 textures
        ImageAlphaMask(&logo2Image, logo2AlphaImage);
        logo2Texture = LoadTextureFromImage(logo2Image);
        // UnloadImage(logo2AlphaImage); // Commented out to avoid double free
        // Apply alpha mapping to button textures
        ImageAlphaMask(&buttonImage, buttonAlphaImage);
        buttonTexture = LoadTextureFromImage(buttonImage);
        // UnloadImage(buttonAlphaImage); // Commented out to avoid double free
        
        // Apply alpha mapping to button hovered texture
        Image buttonHoveredImage = LoadImageFromTexture(buttonHoveredTexture);
        ImageAlphaMask(&buttonHoveredImage, buttonAlphaImage);
        buttonHoveredTexture = LoadTextureFromImage(buttonHoveredImage);
        UnloadImage(buttonHoveredImage);
        // Apply alpha mapping to planet textures
        ImageAlphaMask(&planetImage, planetAlphaImage);
        planetTexture = LoadTextureFromImage(planetImage);
        // UnloadImage(planetAlphaImage); // Commented out to avoid double free
        // Apply alpha mapping to sparkle textures
        Image sparkleImage = LoadImageFromTexture(sparkleTexture);
        Image sparkleAlphaImage = LoadImageFromTexture(sparkleTexture);
        ImageAlphaMask(&sparkleImage, sparkleAlphaImage);
        sparkleTexture = LoadTextureFromImage(sparkleImage);
        // UnloadImage(sparkleAlphaImage); // Commented out to avoid double free
        // Apply alpha mapping to whitened logo2 texture
        Image whitenedLogo2Image = LoadImageFromTexture(logo2Alpha);
        ImageAlphaMask(&whitenedLogo2Image, whitenedLogo2Image);
        whitenedLogo2Texture = LoadTextureFromImage(whitenedLogo2Image);
        // UnloadImage(whitenedLogo2Image); // Commented out to avoid double free
        // Apply alpha mapping to menu gadgets texture
        ImageAlphaMask(&menuGadgetsImage, menuGadgetsAlphaImage);
        menuGadgetsTexture = LoadTextureFromImage(menuGadgetsImage);
        UnloadImage(menuGadgetsImage); // Unload original image
        UnloadImage(menuGadgetsAlphaImage); // Unload alpha image
        
        // Apply alpha mapping to menu button textures
        Image classicImage = LoadImageFromTexture(classicTexture);
        Image classicAlphaImage = LoadImageFromTexture(classicAlpha);
        ImageAlphaMask(&classicImage, classicAlphaImage);
        classicTexture = LoadTextureFromImage(classicImage);
        UnloadImage(classicImage);
        UnloadImage(classicAlphaImage);
        
        Image actionImage = LoadImageFromTexture(actionTexture);
        Image actionAlphaImage = LoadImageFromTexture(actionAlpha);
        ImageAlphaMask(&actionImage, actionAlphaImage);
        actionTexture = LoadTextureFromImage(actionImage);
        UnloadImage(actionImage);
        UnloadImage(actionAlphaImage);
        
        Image endlessImage = LoadImageFromTexture(endlessTexture);
        Image endlessAlphaImage = LoadImageFromTexture(endlessAlpha);
        ImageAlphaMask(&endlessImage, endlessAlphaImage);
        endlessTexture = LoadTextureFromImage(endlessImage);
        UnloadImage(endlessImage);
        UnloadImage(endlessAlphaImage);
        
        Image puzzleImage = LoadImageFromTexture(puzzleTexture);
        Image puzzleAlphaImage = LoadImageFromTexture(puzzleAlpha);
        ImageAlphaMask(&puzzleImage, puzzleAlphaImage);
        puzzleTexture = LoadTextureFromImage(puzzleImage);
        UnloadImage(puzzleImage);
        UnloadImage(puzzleAlphaImage);
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
            
            // We can unload the alpha image since we're done with it
            UnloadImage(croppedAlpha);
        }
        
        // Unload the original image after slicing
        UnloadImage(sparkleImage);
    }

    void update(float deltaTime) {
        // Handle title elements moving off screen
        if (titleElementsMovingOff) {
            bool logoOffScreen = false;
            bool logo2OffScreen = false;
            bool buttonOffScreen = false;

            // Animate logo
            if (logoPosition.y > -logoTexture.height) {
                logoPosition.y -= offScreenAnimationSpeed * deltaTime;
            } else {
                logoOffScreen = true;
            }

            // Animate logo2
            if (logo2Position.y > -logo2Texture.height) {
                logo2Position.y -= offScreenAnimationSpeed * deltaTime;
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
                buttonFadeOutAlpha -= 1.5f * deltaTime; // Adjust fade speed as needed
                buttonScale.x += 0.75f * deltaTime;      // Adjust scale speed as needed
                buttonScale.y += 0.75f * deltaTime;
                
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
                menuGadgetsMovingOn = true;
                // Ensure gadgets start from their off-screen position, adjusted for scale
                menuGadgetsPosition = Vector2((GetScreenWidth() - (menuGadgetsTexture.width * menuGadgetsScale)) / 2.0f, menuGadgetsStartY);
                state = TitleState.MAINMENU; // Transition to main menu state as gadgets start appearing
            }
        }

        // Handle menu gadgets moving on screen with easing
        if (menuGadgetsMovingOn) {
            // Define all positioning variables for use in both branches
            float offsetFromTarget = menuGadgetsPosition.y - menuGadgetsTargetY;
            float centerX = GetScreenWidth() / 2.0f;
            float centerY;
            float topRowY;
            float bottomRowY;
            float halfWidth;
            float leftX;
            float rightX;
            
            if (abs(menuGadgetsPosition.y - menuGadgetsTargetY) > 0.5f) { // Check if not close enough to target
                menuGadgetsPosition.y += (menuGadgetsTargetY - menuGadgetsPosition.y) * menuGadgetsEasingFactor * deltaTime;
                
                // Position buttons with same relative positions but adjusted for current gadget position
                centerY = menuGadgetsPosition.y + (menuGadgetsTexture.height * menuGadgetsScale) / 2.0f;
                topRowY = menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale * 0.22f; // Top row position
                bottomRowY = menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale * 0.67f; // Aligned with purple orbs
                halfWidth = (menuGadgetsTexture.width * menuGadgetsScale) / 2.0f;
                leftX = centerX - halfWidth * 0.48f;  // 48% from center to the left for better alignment
                rightX = centerX + halfWidth * 0.48f; // 48% from center to the right for better alignment
                
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
                    leftX = centerX - halfWidth * 0.48f; // 48% from center for better alignment
                    rightX = centerX + halfWidth * 0.48f; // 48% from center for better alignment
                    
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
                leftX = centerX - halfWidth * 0.48f; // 48% from center for better alignment
                rightX = centerX + halfWidth * 0.48f; // 48% from center for better alignment
                
                classicButtonPosition = Vector2(leftX, topRowY);
                actionButtonPosition = Vector2(rightX, topRowY);
                puzzleButtonPosition = Vector2(leftX, bottomRowY);
                endlessButtonPosition = Vector2(rightX, bottomRowY);
            }
        }

        // Handle fade from black effect
        if (screenFadeAlpha > 0.0f) { // No change here, initial fade is fine
            screenFadeAlpha -= deltaTime * 2.0f; 
            if (screenFadeAlpha < 0.0f) {
                screenFadeAlpha = 0.0f;
                logoAnimationStarted = true;
            }
        }

        // Handle logo rising animation with easing (only if not moving off AND button not clicked)
        if (logoAnimationStarted && !titleElementsMovingOff && !buttonClickedOnce) { // MODIFIED: Added !buttonClickedOnce
            float easingFactor = 4.0f; 
            
            static float logoPosTimer = 0.0f;
            logoPosTimer += deltaTime;
            if (logoPosTimer >= 1.0f) {
                logoPosTimer = 0.0f;
                writeln("Logo position debug - current Y: ", logoPosition.y, " target Y: ", logoTargetY);
                writeln("Logo started: ", logoAnimationStarted);
            }
            
            if (logoPosition.y > logoTargetY) {
                logoPosition.y = logoPosition.y + (logoTargetY - logoPosition.y) * easingFactor * deltaTime;
                if (logoPosition.y < logoTargetY) {
                    logoPosition.y = logoTargetY; // Snap to target position
                }
            }

            if (logoPosition.y <= logoTargetY) {
                logoPosition.y = logoTargetY; // Snap to target position
            }
            
            // Force logo to reach target after 3 seconds to avoid potential animation glitches
            static float logoForceTimer = 0.0f;
            logoForceTimer += deltaTime;
            if (logoForceTimer > 3.0f && logoAnimationStarted) {
                logoPosition.y = logoTargetY;
            }
        }

        // Update position of planet
        planetPosition.y -= 2.5f * deltaTime; // Move planet downwards
        if (planetPosition.y > GetScreenHeight()) {
            planetPosition.y = -planetTexture.height; // Reset position when it goes off screen
        }
        
        // Optimize sparkle animation - don't do heavy image manipulation every frame
        // Instead update the animation less frequently
        static float sparkleUpdateTime = 0.0f;
        sparkleTimer += deltaTime;
        sparkleUpdateTime += deltaTime;
        
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
        sparkleFrameTimer += deltaTime;
        sparkleStarTimer += deltaTime;
        
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
                        buttonAppearDelayTimer += deltaTime;
                    } else {
                        // Improved animation with smoother transition from scale-in to pulsing
                        static float buttonAnimTime = 0.0f;
                        buttonAnimTime += deltaTime;
                        
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
                        buttonPosition.x = (GetScreenWidth() - buttonTexture.width * finalScale) / 2.0f;
                        buttonPosition.y = GetScreenHeight() - buttonTexture.height * finalScale - 50.0f;
                        
                        // Button click logic
                        if (buttonScale.x >= 0.9f && IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
                            Vector2 mousePos = GetMousePosition();
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
                // If title elements are still moving or gadgets are moving, don't process main menu logic yet
                if (titleElementsMovingOff || menuGadgetsMovingOn) {
                    // Waiting for animations to complete
                } else {
                    // Main menu logic here - handle button hover states and clicks
                    Vector2 mousePosition = GetMousePosition();
                    
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
                    Vector2 toggleModesSize = MeasureTextEx(fontFamily[0], toggleModesText.toStringz(), 20, 1.0f);
                    Rectangle toggleModesRect = Rectangle(
                        centerX - toggleModesSize.x / 2.0f,
                        menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale - 110, // Updated to match new position
                        toggleModesSize.x,
                        20
                    );
                    
                    Vector2 returnToMenuSize = MeasureTextEx(fontFamily[0], returnToMenuText.toStringz(), 20, 1.0f);
                    Rectangle returnToMenuRect = Rectangle(
                        centerX - returnToMenuSize.x / 2.0f,
                        menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale - 70, // Updated to match new position
                        returnToMenuSize.x,
                        20
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
                            // Return to main menu
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
            int starCount = 200; // Reduced from 400 to 200 
            stars = new Star[starCount];
            for (int i = 0; i < starCount; i++) {
                stars[i] = Star(
                    x: uniform(0, GetScreenWidth()),
                    y: uniform(0, GetScreenHeight()),
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
                stars[i].update(deltaTime);
            }
        }

        // Update logo2 fade-in effect after 2 seconds (only if not moving off AND button not clicked)
        if (!titleElementsMovingOff && !buttonClickedOnce) { // MODIFIED: Added !buttonClickedOnce
            static float logo2FadeInTimer = 0.0f;
            logo2FadeInTimer += deltaTime;

            if (!fadeInComplete && logo2FadeInTimer >= 2.0f && whitenedLogo2Alpha < 1.0f) {
                whitenedLogo2Alpha += deltaTime * 3.0f; 
                if (whitenedLogo2Alpha >= 1.0f) {
                    whitenedLogo2Alpha = 1.0f; 
                    fadeInComplete = true;
                }
            }
            else if (fadeInComplete && logo2FadeInTimer >= 2.4f) { 
                whitenedLogo2Alpha -= deltaTime * 3.0f; 
                if (whitenedLogo2Alpha <= 0.0f) {
                    whitenedLogo2Alpha = 0.0f; 
                }
            }
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

        // Draw logo (only if not moving off or if still on screen)
        if (logoAnimationStarted && logoPosition.y < GetScreenHeight()) {
            DrawTexturePro(logoTexture, Rectangle(0, 0, logoTexture.width, logoTexture.height), 
                Rectangle(logoPosition.x, logoPosition.y, logoTexture.width, logoTexture.height), Vector2(0, 0), 0.0f, Colors.WHITE);
        }
        
        // Draw background
        DrawTexturePro(backgroundTexture, Rectangle(0, 0, backgroundTexture.width, backgroundTexture.height), 
            Rectangle(0, 0, GetScreenWidth(), GetScreenHeight()), Vector2(0, 0), 0.0f, Colors.WHITE);

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

                if (!buttonClickedOnce && CheckCollisionPointRec(GetMousePosition(), buttonRect)) {
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
        if (fadeInComplete && logo2Position.y < GetScreenHeight() && logo2Position.y > -logo2Texture.height) {
            DrawTexturePro(logo2Texture, Rectangle(0, 0, logo2Texture.width, logo2Texture.height), 
                Rectangle(logo2Position.x, logo2Position.y, logo2Texture.width, logo2Texture.height), Vector2(0, 0), 0.0f, Colors.WHITE);
        }

        // Draw the whitened logo2 texture (if on screen)
        if (whitenedLogo2Alpha > 0.0f && logo2Position.y < GetScreenHeight() && logo2Position.y > -logo2Texture.height) {
            DrawTextureEx(whitenedLogo2Texture, 
                logo2Position, 
                0.0f, 1.0f, 
                Color(255, 255, 255, cast(uint8_t)(255 * whitenedLogo2Alpha)));
        }

        // Draw fade from black overlay last so it covers everything
        if (screenFadeAlpha > 0.0f) {
            DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), 
                         Fade(Colors.BLACK, screenFadeAlpha));
        }

        // Draw the button (change to hovered texture if mouse is over it)
        Vector2 mousePos = GetMousePosition();
        Rectangle buttonRect = Rectangle(
            buttonPosition.x, 
            buttonPosition.y, 
            buttonTexture.width * buttonScale.x, 
            buttonTexture.height * buttonScale.y
        );

        // Draw menu gadgets if they are moving on or have arrived (and title elements are not moving off)
        if ((menuGadgetsMovingOn || (menuGadgetsPosition.y == menuGadgetsTargetY && !titleElementsMovingOff)) && menuGadgetsTexture.id != 0) {
            // Only draw the top 625px of menu gadgets
            float visibleHeight = 625.0f;
            float originalHeight = menuGadgetsTexture.height;
            
            // Modify source rectangle to only use the top portion
            Rectangle sourceRec = Rectangle(
                0, 0, 
                menuGadgetsTexture.width, 
                min(originalHeight, visibleHeight)
            );
            
            // Calculate the scaled visible height
            float scaledVisibleHeight = min(originalHeight, visibleHeight) * menuGadgetsScale;
            
            Rectangle destRec = Rectangle(
                (GetScreenWidth() - (menuGadgetsTexture.width * menuGadgetsScale)) / 2.0f, // Center horizontally
                menuGadgetsPosition.y, // Current Y position
                menuGadgetsTexture.width * menuGadgetsScale, // Apply scale
                scaledVisibleHeight // Apply scale to visible height only
            );
            Vector2 origin = Vector2(0, 0); // Draw from top-left
            DrawTexturePro(menuGadgetsTexture, sourceRec, destRec, origin, 0.0f, Colors.WHITE);
            
            // Debug printing to verify position and scale
            static float menuGadgetsDebugTimer = 0.0f;
            menuGadgetsDebugTimer += GetFrameTime();
            if (menuGadgetsDebugTimer > 1.0f) {
                menuGadgetsDebugTimer = 0.0f;
                writeln("Menu Gadgets Position: ", menuGadgetsPosition);
                writeln("Menu Gadgets Scale: ", menuGadgetsScale);
                writeln("Screen Width: ", GetScreenWidth());
                writeln("Menu Gadgets Width: ", menuGadgetsTexture.width);
            }

            // Draw the "welcome" text above the "select a game mode" text
            Vector2 welcomeSize = MeasureTextEx(fontFamily[0], welcomeText.toStringz(), 18, 1.0f);
            DrawTextEx(
                fontFamily[0], // Quincy font
                welcomeText.toStringz(),
                Vector2(
                    centerX - welcomeSize.x / 2.0f,
                    menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale * 0.06f // Adjusted to be higher
                ),
                18,
                1.0f,
                Colors.WHITE
            );
            
            // Draw "Select a game mode" text at the top
            Vector2 selectGameModeSize = MeasureTextEx(fontFamily[2], selectGameModeText.toStringz(), 24, 1.0f);
            DrawTextEx(
                fontFamily[2], // Quincy font
                selectGameModeText.toStringz(),
                Vector2(
                    centerX - selectGameModeSize.x / 2.0f,
                    menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale * 0.09f // Reduced from 0.15f to move higher
                ),
                24,
                1.0f,
                Colors.WHITE
            );
            
            // "The Original Untimed Game" text has been removed as requested
            
            // Only draw menu buttons if they should be visible (menu is fully shown)
            // Draw Classic button
            float classicScale = classicButtonHovered ? menuButtonScale * 1.1f : menuButtonScale;
            DrawTexturePro(
                classicTexture,
                Rectangle(0, 0, classicTexture.width, classicTexture.height),
                Rectangle(
                    classicButtonPosition.x - (classicTexture.width * classicScale / 2.0f),
                    classicButtonPosition.y - (classicTexture.height * classicScale / 2.0f),
                    classicTexture.width * classicScale,
                    classicTexture.height * classicScale
                ),
                Vector2(0, 0),
                0.0f,
                classicButtonHovered ? Colors.WHITE : Fade(Colors.WHITE, 0.95f)
            );
            
            // Draw "LEVEL 2" under Classic button, only if there's a saved game
            if (hasClassicSavedGame && classicLevelText.length > 0) {
                Vector2 classicLevelSize = MeasureTextEx(fontFamily[4], classicLevelText.toStringz(), 18, 1.0f);
                DrawTextEx(
                    fontFamily[4], // Quincy font
                    classicLevelText.toStringz(),
                    Vector2(
                        classicButtonPosition.x - classicLevelSize.x / 2.0f,
                        classicButtonPosition.y + classicTexture.height * classicScale / 2.0f + 5
                    ),
                    18,
                    1.0f,
                    Colors.WHITE
                );
            }
            
            // Draw Action button
            float actionScale = actionButtonHovered ? menuButtonScale * 1.1f : menuButtonScale;
            DrawTexturePro(
                actionTexture,
                Rectangle(0, 0, actionTexture.width, actionTexture.height),
                Rectangle(
                    actionButtonPosition.x - (actionTexture.width * actionScale / 2.0f),
                    actionButtonPosition.y - (actionTexture.height * actionScale / 2.0f),
                    actionTexture.width * actionScale,
                    actionTexture.height * actionScale
                ),
                Vector2(0, 0),
                0.0f,
                actionButtonHovered ? Colors.WHITE : Fade(Colors.WHITE, 0.95f)
            );
            
            // Draw "LEVEL 1" under Action button, only if there's a saved game
            if (hasActionSavedGame && actionLevelText.length > 0) {
                Vector2 actionLevelSize = MeasureTextEx(fontFamily[4], actionLevelText.toStringz(), 18, 1.0f);
                DrawTextEx(
                    fontFamily[4], // Quincy font
                    actionLevelText.toStringz(),
                    Vector2(
                        actionButtonPosition.x - actionLevelSize.x / 2.0f,
                        actionButtonPosition.y + actionTexture.height * actionScale / 2.0f + 5
                    ),
                    18,
                    1.0f,
                    Colors.WHITE
                );
            }
            
            // Draw Endless button
            float endlessScale = endlessButtonHovered ? menuButtonScale * 1.1f : menuButtonScale;
            DrawTexturePro(
                endlessTexture,
                Rectangle(0, 0, endlessTexture.width, endlessTexture.height),
                Rectangle(
                    endlessButtonPosition.x - (endlessTexture.width * endlessScale / 2.0f),
                    endlessButtonPosition.y - (endlessTexture.height * endlessScale / 2.0f),
                    endlessTexture.width * endlessScale,
                    endlessTexture.height * endlessScale
                ),
                Vector2(0, 0),
                0.0f,
                endlessButtonHovered ? Colors.WHITE : Fade(Colors.WHITE, 0.95f)
            );
            
            // Draw "LEVEL 11" under Endless button
            Vector2 endlessLevelSize = MeasureTextEx(fontFamily[4], endlessLevelText.toStringz(), 18, 1.0f);
            DrawTextEx(
                fontFamily[4], // Quincy font
                endlessLevelText.toStringz(),
                Vector2(
                    endlessButtonPosition.x - endlessLevelSize.x / 2.0f,
                    endlessButtonPosition.y + endlessTexture.height * endlessScale / 2.0f + 5
                ),
                18,
                1.0f,
                Colors.WHITE
            );
            
            // Draw Puzzle button
            float puzzleScale = puzzleButtonHovered ? menuButtonScale * 1.1f : menuButtonScale;
            DrawTexturePro(
                puzzleTexture,
                Rectangle(0, 0, puzzleTexture.width, puzzleTexture.height),
                Rectangle(
                    puzzleButtonPosition.x - (puzzleTexture.width * puzzleScale / 2.0f),
                    puzzleButtonPosition.y - (puzzleTexture.height * puzzleScale / 2.0f),
                    puzzleTexture.width * puzzleScale,
                    puzzleTexture.height * puzzleScale
                ),
                Vector2(0, 0),
                0.0f,
                puzzleButtonHovered ? Colors.WHITE : Fade(Colors.WHITE, 0.95f)
            );
            
            // Draw "100%" under Puzzle button
            Vector2 puzzlePercentSize = MeasureTextEx(fontFamily[4], puzzlePercentText.toStringz(), 18, 1.0f);
            DrawTextEx(
                fontFamily[4], // Quincy font
                puzzlePercentText.toStringz(),
                Vector2(
                    puzzleButtonPosition.x - puzzlePercentSize.x / 2.0f,
                    puzzleButtonPosition.y + puzzleTexture.height * puzzleScale / 2.0f + 5
                ),
                18,
                1.0f,
                Colors.WHITE
            );
            
            // Draw bottom menu buttons with proper button backgrounds
            // Toggle Secret Modes button
            Vector2 toggleModesSize = MeasureTextEx(fontFamily[0], toggleModesText.toStringz(), 20, 1.0f);
            
            // Draw button background for Toggle Secret Modes
            Rectangle toggleModesButtonRect = Rectangle(
                centerX - (toggleModesSize.x / 2.0f) - 10,
                menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale - 115, // Moved up from -75
                toggleModesSize.x + 20,
                30
            );
            DrawRectangleRounded(toggleModesButtonRect, 0.2f, 10, 
                toggleModesButtonHovered ? Color(70, 100, 150, 180) : Color(50, 80, 120, 180));
            
            // Draw Toggle Secret Modes text
            DrawTextEx(
                fontFamily[0], // ContinuumBold font
                toggleModesText.toStringz(),
                Vector2(
                    centerX - toggleModesSize.x / 2.0f,
                    menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale - 110 // Moved up from -70
                ),
                20,
                1.0f,
                toggleModesButtonHovered ? Colors.WHITE : Fade(Colors.WHITE, 0.9f)
            );
            
            // Return to Main Menu button
            Vector2 returnToMenuSize = MeasureTextEx(fontFamily[0], returnToMenuText.toStringz(), 20, 1.0f);
            
            // Draw button background for Return to Main Menu
            Rectangle returnToMenuButtonRect = Rectangle(
                centerX - (returnToMenuSize.x / 2.0f) - 10,
                menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale - 75, // Moved up from -45
                returnToMenuSize.x + 20,
                30
            );
            DrawRectangleRounded(returnToMenuButtonRect, 0.2f, 10, 
                returnToMenuButtonHovered ? Color(70, 100, 150, 180) : Color(50, 80, 120, 180));
            
            // Draw Return to Main Menu text
            DrawTextEx(
                fontFamily[0], // ContinuumBold font
                returnToMenuText.toStringz(),
                Vector2(
                    centerX - returnToMenuSize.x / 2.0f,
                    menuGadgetsPosition.y + menuGadgetsTexture.height * menuGadgetsScale - 70 // Moved up from -40
                ),
                20,
                1.0f,
                returnToMenuButtonHovered ? Colors.WHITE : Fade(Colors.WHITE, 0.9f)
            );
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
        UnloadTexture(buttonAlpha);
        UnloadTexture(sparkleTexture);
        UnloadTexture(planetTexture);
        UnloadTexture(planetAlpha);
        UnloadTexture(menuGadgetsTexture);
        UnloadTexture(menuGadgetsAlpha);
        
        // Unload menu button textures
        UnloadTexture(classicTexture);
        UnloadTexture(classicAlpha);
        UnloadTexture(actionTexture);
        UnloadTexture(actionAlpha);
        UnloadTexture(endlessTexture);
        UnloadTexture(endlessAlpha);
        UnloadTexture(puzzleTexture);
        UnloadTexture(puzzleAlpha);

        // Unload sparkle frame textures
        for (int i = 0; i < sparkleFrameTextures.length; i++) {
            UnloadTexture(sparkleFrameTextures[i]);
        }

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