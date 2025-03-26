using System;
using Raylib_cs;

using Bejeweled_2_Remastered.jxl;
using Bejeweled_2_Remastered.Screens;

namespace Bejeweled_2_Remastered.Screens
{
    public class MainMenuScreen : IScreen
    {
        private ScreenManager screenManager;

        public MainMenuScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
        }

        public void Load()
        {
            Console.WriteLine("MainMenuScreen: Loading resources...");
            // Load resources for the main menu
            Console.WriteLine("MainMenuScreen: Resources loaded.");
        }

        public void Unload()
        {
            Console.WriteLine("MainMenuScreen: Unloading resources...");
            // Unload resources for the main menu
            Console.WriteLine("MainMenuScreen: Resources unloaded.");
        }

        public void Update()
        {
            if (Raylib.IsKeyPressed(KeyboardKey.Enter))
            {
                screenManager.ChangeState(ScreenState.Gameplay);
            }
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(Color.White); // Use Color.WHITE instead of RAYWHITE
            Raylib.DrawText("Main Menu", 350, 200, 40, Color.Black);
            Raylib.DrawText("Press ENTER to Start", 300, 300, 20, Color.Gray);
            Raylib.EndDrawing();
        }
    }
}