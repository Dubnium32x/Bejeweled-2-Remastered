using System;
using Raylib_cs;

namespace Bejeweled_2_Remastered.Screens
{
    public class SettingsScreen : IScreen
    {
        private ScreenManager screenManager;

        public SettingsScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
        }

        public void Load()
        {
            Console.WriteLine("SettingsScreen: Loading resources...");
            // Load resources for settings
            Console.WriteLine("SettingsScreen: Resources loaded.");
        }

        public void Unload()
        {
            Console.WriteLine("SettingsScreen: Unloading resources...");
            // Unload resources for settings
            Console.WriteLine("SettingsScreen: Resources unloaded.");
        }

        public void Update()
        {
            // Update settings logic
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(Color.White);
            // Draw settings elements
            Raylib.EndDrawing();
        }
    }
}