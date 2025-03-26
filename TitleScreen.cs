using System;
using System.IO;
using Raylib_cs;

namespace Bejeweled_2_Remastered.Screens
{
    public class TitleScreen : IScreen
    {
        private ScreenManager screenManager;
        private Texture2D backdrop;
        private Texture2D gradientBackground;

        // Define the colors for the gradient
        private Color startColor = new Color(41, 65, 107, 255);
        private Color endColor = new Color(173, 199, 206, 255);

        public TitleScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
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

                // Create the gradient background texture
                gradientBackground = CreateGradientTexture(Raylib.GetScreenWidth(), Raylib.GetScreenHeight(), startColor, endColor);
                Console.WriteLine("TitleScreen: Gradient background created.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading resources: {ex.Message}");
            }
        }

        public void Unload()
        {
            Console.WriteLine("TitleScreen: Unloading resources...");
            Raylib.UnloadTexture(backdrop);
            Raylib.UnloadTexture(gradientBackground);
            Console.WriteLine("TitleScreen: Resources unloaded.");
        }

        public void Update()
        {
            // Update title screen logic here
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.DrawTexturePro(gradientBackground, new Rectangle(0, 0, gradientBackground.width, gradientBackground.height), new Rectangle(0, 0, Raylib.GetScreenWidth(), Raylib.GetScreenHeight()), new Vector2(0, 0), 0, Color.WHITE);
            Raylib.DrawTexturePro(backdrop, new Rectangle(0, 0, backdrop.width, backdrop.height), new Rectangle(0, 0, Raylib.GetScreenWidth(), Raylib.GetScreenHeight()), new Vector2(0, 0), 0, Color.WHITE);
            Raylib.EndDrawing();
        }

        private Texture2D CreateGradientTexture(int width, int height, Color startColor, Color endColor)
        {
            Image gradientImage = Raylib.GenImageGradient(width, height, startColor, endColor, GradientDirection.Vertical);
            Texture2D texture = Raylib.LoadTextureFromImage(gradientImage);
            Raylib.UnloadImage(gradientImage);
            return texture;
        }
    }
}