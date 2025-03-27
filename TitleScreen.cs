using System;
using System.Numerics;
using System.IO;

using Lerp;
using Raylib_cs;

using Bejeweled_2_Remastered.jxl;
using Bejeweled_2_Remastered.Screens;

namespace Bejeweled_2_Remastered.Screens
{
    public class TitleScreen : IScreen
    {
        private ScreenManager screenManager;
        private Texture2D backdrop;
        private Texture2D sparkle;
        private Texture2D sparkleTextureWithAlpha;
        private Texture2D planetTexture;
        private Texture2D planetTextureWithAlpha;
        private Texture2D titleLogoTexture;
        private Texture2D titleLogoTextureWithAlpha;

        // Define the background color
        private Color backgroundColor = new Color(41, 65, 107, 255);

        // Define stars properties
        private const int starCount = 100;
        private Vector2[] starPositions;
        private Color starColor = Color.White;
        private float starSpeed = 5.0f; // Speed at which stars rise

        // Define sparkle effect properties
        private bool isSparkling = false;

        private Vector2 sparklePosition;
        private float sparkleDuration = 0.8f; // Duration of sparkle effect in seconds
        private float sparkleTimer = 0.0f;
        private float sparklePauseDuration = 1.7f; // Duration of pause between sparkles

        // Define planet properties
        private Vector2 planetPosition;
        
        // Define title logo properties
        public Vector2 titleLogoPosition;
        private Vector2 logoDest;
        private float titleLogoDuration = 1.0f;
        private float titleLogoTimer = 0.0f;
        private float titlePauseTimer = 0.0f;
        private float firstTitlePauseDuration = 2.0f; // Duration of the first pause before the logo moves

        public TitleScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
            InitializeStars();
            InitializePlanet();
            InitializeTitleLogo();
        }

        public void Load()
        {
            Program.isLoading = true;
            // Debug: Print the current working directory
            string currentDirectory = Directory.GetCurrentDirectory();
            Console.WriteLine($"Current Directory: {currentDirectory}");

            // Debug: Verify and print the path to the JXL file
            string jxlFilePath = "res/images/backdrops/backdrop_title_A.jxl";
            Console.WriteLine($"JXL File Path: {jxlFilePath}");

            try
            {
                if (!File.Exists(jxlFilePath))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath} does not exist.");
                }

                Console.WriteLine("TitleScreen: Loading resources...");
                string pngFilePath = JxlConverter.ConvertJxlToPng(jxlFilePath);
                Console.WriteLine($"PNG File Path: {pngFilePath}");

                if (!File.Exists(pngFilePath))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath} does not exist after conversion.");
                }

                backdrop = Raylib.LoadTexture(pngFilePath);
                Console.WriteLine("TitleScreen: Resources loaded.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading resources: {ex.Message}");
            }

            // Load sparkle effect
            LoadSparkleEffect();
            // Load planet texture
            LoadPlanet();
            // Load title logo
            LoadTitleLogo();
        }

        private void LoadPlanet()
        {
            Program.isLoading = true;
            string jxlFilePath1 = "res/images/planet1_frame_0001.jxl";
            string jxlFilePath2 = "res/images/planet1__frame_0001.jxl";
            try
            {
                if (!File.Exists(jxlFilePath1))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath1} does not exist.");
                }

                string pngFilePath1 = JxlConverter.ConvertJxlToPng(jxlFilePath1);

                if (!File.Exists(pngFilePath1))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath1} does not exist after conversion.");
                }

                if (!File.Exists(jxlFilePath2))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath2} does not exist.");
                }
                string pngFilePath2 = JxlConverter.ConvertJxlToPng(jxlFilePath2);
                if (!File.Exists(pngFilePath2))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath2} does not exist after conversion.");
                }

                Image planetImage = Raylib.LoadImage(pngFilePath1);
                Image maskImage = Raylib.LoadImage(pngFilePath2);
                Image maskedImage = ApplyAlphaMask(planetImage, maskImage);
                planetTextureWithAlpha = Raylib.LoadTextureFromImage(maskedImage);
                Console.WriteLine("Planet texture loaded successfully.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading planet texture: {ex.Message}");
            }
        }

        private void LoadSparkleEffect()
        {
            Program.isLoading = true;
            string jxlFilePath1 = "res/images/bigstar_frame_0001.jxl";
            string jxlFilePath2 = "res/images/bigstar_frame_0002.jxl";
            try
            {
                // Load first frame
                if (!File.Exists(jxlFilePath1))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath1} does not exist.");
                }

                string pngFilePath1 = JxlConverter.ConvertJxlToPng(jxlFilePath1);

                if (!File.Exists(pngFilePath1))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath1} does not exist after conversion.");
                }

                sparkle = Raylib.LoadTexture(pngFilePath1);

                // Load second frame as mask
                if (!File.Exists(jxlFilePath2))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath2} does not exist.");
                }

                string pngFilePath2 = JxlConverter.ConvertJxlToPng(jxlFilePath2);

                if (!File.Exists(pngFilePath2))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath2} does not exist after conversion.");
                }

                Image sparkleImage = Raylib.LoadImage(pngFilePath1);
                Image maskImage = Raylib.LoadImage(pngFilePath2);
                Image maskedImage = ApplyAlphaMask(sparkleImage, maskImage);
                sparkleTextureWithAlpha = Raylib.LoadTextureFromImage(maskedImage);

                Console.WriteLine("Sparkle effect: Loaded successfully.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading sparkle effect: {ex.Message}");
            }
        }

        public void LoadTitleLogo()
        {
            Program.isLoading = true;
            bool isLoaded = false;
            // Load the title logo texture
            string jxlFilePath1 = "res/images/title_logo.jxl";
            string jxlFilePath2 = "res/images/title_logo__frame_0001.jxl";

            try
            {
                if (!File.Exists(jxlFilePath1))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath1} does not exist.");
                }

                string pngFilePath1 = JxlConverter.ConvertJxlToPng(jxlFilePath1);

                if (!File.Exists(pngFilePath1))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath1} does not exist after conversion.");
                }

                if (!File.Exists(jxlFilePath2))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath2} does not exist.");
                }
                string pngFilePath2 = JxlConverter.ConvertJxlToPng(jxlFilePath2);
                if (!File.Exists(pngFilePath2))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath2} does not exist after conversion.");
                }

                Image titleImage = Raylib.LoadImage(pngFilePath1);
                Image maskImage = Raylib.LoadImage(pngFilePath2);
                Image maskedImage = ApplyAlphaMask(titleImage, maskImage);
                titleLogoTextureWithAlpha = Raylib.LoadTextureFromImage(maskedImage);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading title logo: {ex.Message}");
            }
            // Check if the title logo texture was loaded successfully
            if (File.Exists("res/images/title_logo.png"))
            {
                isLoaded = true;
                Console.WriteLine("Title logo loaded successfully.");
            }
            else
            {
                Console.WriteLine("Failed to load title logo.");
            }
        }

        public void Unload()
        {
            Console.WriteLine("TitleScreen: Unloading resources...");
            Raylib.UnloadTexture(backdrop);
            Raylib.UnloadTexture(sparkle);
            Raylib.UnloadTexture(sparkleTextureWithAlpha);
            Console.WriteLine("TitleScreen: Resources unloaded.");
        }

        public void Update()
        {
            UpdateStars();
            UpdateSparkle();
            UpdateTitleLogo();
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(backgroundColor);
            DrawStars();
            DrawSparkle();
            DrawPlanet();
            DrawTitleLogo();
            Raylib.DrawTexturePro(backdrop, new Rectangle(0, 0, backdrop.Width, backdrop.Height), new Rectangle(0, 0, Raylib.GetScreenWidth(), Raylib.GetScreenHeight()), new Vector2(0, 0), 0, Color.White);
            Raylib.EndDrawing();
        }

        private void InitializeStars()
        {
            Random rand = new Random();
            starPositions = new Vector2[starCount];
            for (int i = 0; i < starCount; i++)
            {
                starPositions[i] = new Vector2(rand.Next(Raylib.GetScreenWidth()), rand.Next(Raylib.GetScreenHeight()));
            }

            // Initialize sparkle
            sparklePosition = starPositions[rand.Next(starCount)];
            isSparkling = true;
        }

        private void InitializePlanet()
        {
            Random rand = new Random();
            planetPosition = new Vector2(Raylib.GetScreenWidth(), Raylib.GetScreenHeight());
        }

        private void InitializeTitleLogo()
        {
            float logoScale = Math.Min(Raylib.GetScreenWidth() / 1280.0f, Raylib.GetScreenHeight() / 720.0f) + 0.5f;
            float initialXPercent = 0.5f; // Center horizontally (0.5 = 50%)
            float initialYPercent = 1.1f;  // Start below the screen (1.1 = 110%)

            titleLogoPosition = new Vector2(
                (Raylib.GetScreenWidth() * initialXPercent) - ((titleLogoTextureWithAlpha.Width * logoScale) / 2),
                Raylib.GetScreenHeight() * initialYPercent
            );
        }

        private void UpdateTitleLogo()
        {
            bool clickedPlay = false;
            titlePauseTimer += Raylib.GetFrameTime();
            if (titlePauseTimer > firstTitlePauseDuration)
            {
                float deltaTime = Raylib.GetFrameTime();
                float targetXPercent = 0.5f; // Center horizontally
                float targetYPercent = 0.05f; // 5% from the top

                Vector2 logoDest = new Vector2(
                    (Raylib.GetScreenWidth() * targetXPercent) - (titleLogoTextureWithAlpha.Width / 2),
                    (Raylib.GetScreenHeight() * targetYPercent) + (100.0f * ((Raylib.GetScreenWidth() / 1280f) + (Raylib.GetScreenHeight() / 720f)) / 2));
                titleLogoTimer += deltaTime;

                if (titleLogoTimer >= titleLogoDuration)
                {
                    titleLogoPosition.Y -= (titleLogoPosition.Y - logoDest.Y) * 0.1f;
                }
            }
        }

        private void UpdateStars()
        {
            float deltaTime = Raylib.GetFrameTime();
            for (int i = 0; i < starCount; i++)
            {
                starPositions[i].Y -= starSpeed * deltaTime;
                if (starPositions[i].Y < 0)
                {
                    starPositions[i].Y = Raylib.GetScreenHeight();
                    starPositions[i].X = new Random().Next(Raylib.GetScreenWidth());
                }
            }
        }

        private void UpdateSparkle()
        {
            if (!isSparkling) return;

            sparkleTimer += Raylib.GetFrameTime();
            if (sparkleTimer >= sparkleDuration)
            {
            isSparkling = false;
            sparkleTimer = 0.0f;
            // Randomly select a new star to sparkle
            sparklePosition = starPositions[new Random().Next(starCount)];
            isSparkling = true;
            }
        }

        private void DrawSparkle()
        {
            if (!isSparkling) return;

            // Update sparkle position to move upwards
            sparklePosition.Y -= starSpeed * Raylib.GetFrameTime();
            if (sparklePosition.Y < 0)
            {
            // Reset sparkle position to a random star when it moves off-screen
            sparklePosition = starPositions[new Random().Next(starCount)];
            }

            // Calculate scale based on sparkle timer to create a grow-shrink effect
            float scale = 0.07f + 0.06f * (float)Math.Sin((sparkleTimer / sparkleDuration / 1.25f) * Math.PI * 2);

            // Calculate rotation angle based on sparkle timer
            float rotation = (sparkleTimer / sparkleDuration) * 360.0f;

            Rectangle sourceRect = new Rectangle(0, 0, sparkleTextureWithAlpha.Width, sparkleTextureWithAlpha.Height);
            Rectangle destRect = new Rectangle(sparklePosition.X, sparklePosition.Y, sparkleTextureWithAlpha.Width * scale, sparkleTextureWithAlpha.Height * scale);
            Vector2 origin = new Vector2((sparkleTextureWithAlpha.Width * scale) / 2, (sparkleTextureWithAlpha.Height * scale) / 2);

            Raylib.DrawTexturePro(sparkleTextureWithAlpha, sourceRect, destRect, origin, rotation, Color.White);
        }

        private void DrawStars()
        {
            foreach (var position in starPositions)
            {
                Raylib.DrawCircle((int)position.X, (int)position.Y, 1, starColor);
            }
        }
        private void DrawPlanet()
        {
            float scale = 0.5f * ((Raylib.GetScreenWidth() / 1280f) + (Raylib.GetScreenHeight() / 720f)) / 2;

            planetPosition.Y -= (starSpeed / 2) * Raylib.GetFrameTime();
            planetPosition.X = Raylib.GetScreenWidth();

            Rectangle sourceRect = new Rectangle(0, 0, planetTextureWithAlpha.Width, planetTextureWithAlpha.Height);
            Rectangle destRect = new Rectangle(planetPosition.X, planetPosition.Y, planetTextureWithAlpha.Width * scale, planetTextureWithAlpha.Height * scale);
            Vector2 origin = new Vector2((planetTextureWithAlpha.Width * scale) / 2, (planetTextureWithAlpha.Height * scale) / 2);
            Raylib.DrawTexturePro(planetTextureWithAlpha, sourceRect, destRect, origin, 0, Color.White);
        }

        private void DrawTitleLogo()
        {
            float scale = 0.25f * ((Raylib.GetScreenWidth() / 1280f) + (Raylib.GetScreenHeight() / 720f)) / 2;
            Rectangle sourceRect = new Rectangle(0, 0, titleLogoTextureWithAlpha.Width, titleLogoTextureWithAlpha.Height);
            Rectangle destRect = new Rectangle(titleLogoPosition.X, titleLogoPosition.Y, titleLogoTextureWithAlpha.Width * scale, titleLogoTextureWithAlpha.Height * scale);
            Vector2 origin = new Vector2((titleLogoTextureWithAlpha.Width * scale) / 2, (titleLogoTextureWithAlpha.Height * scale) / 2);
            Raylib.DrawTexturePro(titleLogoTextureWithAlpha, sourceRect, destRect, origin, 0, Color.White);
        }

        private Image ApplyAlphaMask(Image baseImage, Image maskImage)
        {
            // Ensure both images have the same dimensions
            if (baseImage.Width != maskImage.Width || baseImage.Height != maskImage.Height)
            {
                throw new ArgumentException("Base image and mask image must have the same dimensions.");
            }

            // Apply the alpha mask using Raylib's built-in function
            Raylib.ImageAlphaMask(ref baseImage, maskImage);

            return baseImage;
        }
    }
}