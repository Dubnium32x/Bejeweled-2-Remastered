using System;
using System.Numerics;
using System.IO;
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

        public TitleScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
            InitializeStars();
        }

        public void Load()
        {
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
        }

        private void LoadSparkleEffect()
        {
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
            // Update title screen logic here
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(backgroundColor);
            DrawStars();
            DrawSparkle();
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
            if (!isSparkling)
            {
            sparkleTimer += Raylib.GetFrameTime();
            if (sparkleTimer >= sparklePauseDuration)
            {
                sparkleTimer = 0.0f;
                isSparkling = true;
            }
            return;
            }

            sparkleTimer += Raylib.GetFrameTime();
            if (sparkleTimer >= sparkleDuration)
            {
            isSparkling = false;
            sparkleTimer = 0.0f;
            sparklePauseDuration = new Random().Next(1, 4); // Randomly set pause duration between 1 to 3 seconds
            // Randomly select a new star to sparkle
            sparklePosition = starPositions[new Random().Next(starCount)];
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