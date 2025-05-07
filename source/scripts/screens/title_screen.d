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
    // Resources to preload
    private string[] texturesToPreload;
    private string[] soundsToPreload;
    private string[] musicToPreload;
    
    private Star[] stars; // Array of stars for star field effect
    this() {
        // Initialize singleton instance
        if (instance is null) {
            instance = this;
        }

        memoryManager = MemoryManager.instance();
        audioManager = AudioManager.getInstance();

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
            "resources/image/Menu-Gadgets_.png" // alpha
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
    
        // Play autonomous music if not already playing
        audioManager.playSound("resources/audio/music/arranged/Autonomous.ogg", AudioType.MUSIC, 1.0f, true);
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
        // Apply alpha mapping to button hovered textures
        Image buttonHoveredImage = LoadImageFromTexture(buttonHoveredTexture);
        ImageAlphaMask(&buttonHoveredImage, buttonAlphaImage);
        buttonHoveredTexture = LoadTextureFromImage(buttonHoveredImage);
        // UnloadImage(buttonAlphaImage); // Commented out to avoid double free
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
        // Handle fade from black effect
        if (screenFadeAlpha > 0.0f) {
            screenFadeAlpha -= deltaTime * 2.0f; // Fade out over 0.5 seconds
            if (screenFadeAlpha < 0.0f) {
                screenFadeAlpha = 0.0f;
                // Start logo animation when fade is complete
                logoAnimationStarted = true;
                // Don't play welcome sound here - it will play when button is clicked
            }
        }

        // Handle logo rising animation with easing
        if (logoAnimationStarted) {
            float easingFactor = 4.0f; // Adjust for speed of easing
            
            // DEBUG: Print logo position information
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
                                PlaySound(welcomeSound);
                                state = TitleState.MAINMENU;
                                if (!isMusicPlaying) {
                                    audioManager.playMusic("resources/audio/music/arranged/Main Theme - Bejeweled 2.ogg");
                                    isMusicPlaying = true;
                                }
                            }
                        }
                    }
                }
                break;

            case TitleState.MAINMENU:
                if (IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
                    // Play click sound when button is clicked
                    audioManager.playSound("resources/audio/sfx/menuclick.ogg", AudioType.SFX, 1.0f, false);
                    // Transition to gameplay or next screen
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

        // Update logo2 fade-in effect after 2 seconds
        static float logo2FadeInTimer = 0.0f;
        logo2FadeInTimer += deltaTime;

        if (!fadeInComplete && logo2FadeInTimer >= 2.0f && whitenedLogo2Alpha < 1.0f) {
            whitenedLogo2Alpha += deltaTime * 3.0f; // Fade in over 2 seconds
            if (whitenedLogo2Alpha >= 1.0f) {
                whitenedLogo2Alpha = 1.0f; // Clamp to max alpha
                fadeInComplete = true;
            }
        }
        else if (fadeInComplete && logo2FadeInTimer >= 2.4f) {
            whitenedLogo2Alpha -= deltaTime * 3.0f; // Fade out after 3 seconds
            if (whitenedLogo2Alpha <= 0.0f) {
                whitenedLogo2Alpha = 0.0f; // Clamp to min alpha
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
        DrawTexturePro(planetTexture, Rectangle(0, 0, planetTexture.width, planetTexture.height), 
            Rectangle(planetPosition.x, planetPosition.y, planetTexture.width * planetScale, planetTexture.height * planetScale), Vector2(0, 0), 0.0f, Colors.WHITE);
        
        // Draw logo
        if (logoAnimationStarted) {
            DrawTexturePro(logoTexture, Rectangle(0, 0, logoTexture.width, logoTexture.height), 
                Rectangle(logoPosition.x, logoPosition.y, logoTexture.width, logoTexture.height), Vector2(0, 0), 0.0f, Colors.WHITE);
        }
        
        // Draw background
        DrawTexturePro(backgroundTexture, Rectangle(0, 0, backgroundTexture.width, backgroundTexture.height), 
            Rectangle(0, 0, GetScreenWidth(), GetScreenHeight()), Vector2(0, 0), 0.0f, Colors.WHITE);

        // Draw click button with scale-in effect
        if (buttonScale.x > 0.0f) {
            Color buttonColor = Colors.WHITE;
            DrawTexturePro(
                buttonTexture,
                Rectangle(0, 0, buttonTexture.width, buttonTexture.height),
                Rectangle(
                    buttonPosition.x,
                    buttonPosition.y,
                    buttonTexture.width * buttonScale.x,
                    buttonTexture.height * buttonScale.y
                ),
                Vector2(0, 0),
                0.0f,
                buttonColor
            );
            
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

        // Draw the actual logo2 texture if the fade is complete
        if (fadeInComplete) {
            DrawTexturePro(logo2Texture, Rectangle(0, 0, logo2Texture.width, logo2Texture.height), 
                Rectangle(logo2Position.x, logo2Position.y, logo2Texture.width, logo2Texture.height), Vector2(0, 0), 0.0f, Colors.WHITE);
        }

        // Draw the whitened logo2 texture
        DrawTextureEx(whitenedLogo2Texture, 
            logo2Position, 
            0.0f, 1.0f, 
            Color(255, 255, 255, cast(uint8_t)(255 * whitenedLogo2Alpha)));

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
        if (buttonScale.x > 0.0f && CheckCollisionPointRec(mousePos, buttonRect)) {
            // Draw hovered button texture
            Color buttonColor = Colors.WHITE;
            DrawTexturePro(
                buttonHoveredTexture,
                Rectangle(0, 0, buttonHoveredTexture.width, buttonHoveredTexture.height),
                Rectangle(
                    buttonPosition.x,
                    buttonPosition.y,
                    buttonHoveredTexture.width * buttonScale.x,
                    buttonHoveredTexture.height * buttonScale.y
                ),
                Vector2(0, 0),
                0.0f,
                buttonColor
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