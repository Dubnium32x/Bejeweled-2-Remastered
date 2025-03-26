using System;
using System.Numerics;
using System.IO;
using Raylib_cs;

using Bejeweled_2_Remastered.Screens;
using Bejeweled_2_Remastered.jxl;

namespace Bejeweled_2_Remastered.Screens
{
    public class TitleScreen : IScreen
    {
        private ScreenManager screenManager;
        private Texture2D backdrop;

        // Define the background color
        private Color backgroundColor = new Color(41, 65, 107, 255);

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
            Console.WriteLine("TitleScreen: Resources unloaded.");
        }

        public void Update()
        {
            // Update title screen logic here
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(backgroundColor);
            Raylib.DrawTexturePro(backdrop, new Rectangle(0, 0, backdrop.Width, backdrop.Height), new Rectangle(0, 0, Raylib.GetScreenWidth(), Raylib.GetScreenHeight()), new Vector2(0, 0), 0, Color.White);
            Raylib.EndDrawing();
        }
    }
}