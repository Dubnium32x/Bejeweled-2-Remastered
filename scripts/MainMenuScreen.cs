using System;
using Raylib_cs;

using Bejeweled_2_Remastered.jxl;
using Bejeweled_2_Remastered.Screens;

namespace Bejeweled_2_Remastered.Screens
{
    public class GameplayScreen : IScreen
    {
        private ScreenManager screenManager;

        public GameplayScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
        }

        public void Load()
        {
            Console.WriteLine("GameplayScreen: Loading resources...");
            // Load resources for gameplay
            Console.WriteLine("GameplayScreen: Resources loaded.");
        }

        public void Unload()
        {
            Console.WriteLine("GameplayScreen: Unloading resources...");
            // Unload resources for gameplay
            Console.WriteLine("GameplayScreen: Resources unloaded.");
        }

        public void Update()
        {
            // Update gameplay logic
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(Color.White);
            // Draw gameplay elements
            Raylib.EndDrawing();
        }
    }
}