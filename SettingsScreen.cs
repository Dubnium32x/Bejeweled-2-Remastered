using System;
using Raylib_cs;

namespace Bejeweled_2_Remastered.Screens
{
    public class SettingsScreen : IScreen
    {
        private ScreenManager screenManager;
        private Resolution currentResolution;

        public SettingsScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
            this.currentResolution = Resolution.R640x360; // Default resolution
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
            if (Raylib.IsKeyPressed(KeyboardKey.One))
            {
                SetResolution(Resolution.R1280x720);
            }
            else if (Raylib.IsKeyPressed(KeyboardKey.Two))
            {
                SetResolution(Resolution.R1920x1080);
            }
            else if (Raylib.IsKeyPressed(KeyboardKey.Three))
            {
                SetResolution(Resolution.R2560x1440);
            }
            else if (Raylib.IsKeyPressed(KeyboardKey.Four))
            {
                SetResolution(Resolution.R3840x2160);
            }
            else if (Raylib.IsKeyPressed(KeyboardKey.Zero))
            {
                SetResolution(Resolution.R1280x720); // Reset to default resolution
            }
            else if (Raylib.IsKeyPressed(KeyboardKey.Five))
            {
                SetResolution(Resolution.R640x360); // Example for a custom resolution
            }
            else

            if (Raylib.IsKeyPressed(KeyboardKey.Backspace))
            {
                screenManager.ChangeState(ScreenState.MainMenu);
            }
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(Color.White); // Use Color.White instead of RAYWHITE
            Raylib.DrawText("Settings", 350, 200, 40, Color.Black);
            Raylib.DrawText("Press 1 for 1280x720", 300, 300, 20, Color.Gray);
            Raylib.DrawText("Press 2 for 1920x1080", 300, 330, 20, Color.Gray);
            Raylib.DrawText("Press 3 for 2560x1440", 300, 360, 20, Color.Gray);
            Raylib.DrawText("Press 4 for 3840x2160", 300, 390, 20, Color.Gray);
            Raylib.DrawText("Press BACKSPACE to return to Main Menu", 300, 450, 20, Color.Gray);
            Raylib.EndDrawing();
        }

        private void SetResolution(Resolution resolution)
        {
            this.currentResolution = resolution;
            switch (resolution)
            {
                case Resolution.R1280x720:
                    Raylib.SetWindowSize(1280, 720);
                    break;
                case Resolution.R1920x1080:
                    Raylib.SetWindowSize(1920, 1080);
                    break;
                case Resolution.R2560x1440:
                    Raylib.SetWindowSize(2560, 1440);
                    break;
                case Resolution.R3840x2160:
                    Raylib.SetWindowSize(3840, 2160);
                    break;
                case Resolution.R640x360:
                    Raylib.SetWindowSize(640, 360);
                    break;
            }
            Console.WriteLine($"Resolution set to {resolution}");
        }
    }
}