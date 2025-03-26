using System;
using Raylib_cs;

using Bejeweled_2_Remastered.Screens;
using Bejeweled_2_Remastered.jxl;

namespace Bejeweled_2_Remastered.Screens
{
    public class TitleScreen : IScreen
    {
        private ScreenManager screenManager;

        public TitleScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
        }

        public void Load()
        {
            Console.WriteLine("TitleScreen: Loading resources...");
            // Load resources for the title screen
            Console.WriteLine("TitleScreen: Resources loaded.");
        }

        public void Unload()
        {
            Console.WriteLine("TitleScreen: Unloading resources...");
            // Unload resources for the title screen
            Console.WriteLine("TitleScreen: Resources unloaded.");
        }

        public void Update()
        {
            if (Raylib.IsKeyPressed(KeyboardKey.Enter))
            {
                screenManager.ChangeState(ScreenState.MainMenu);
            }
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(Color.DarkBlue);
            Raylib.DrawText("Bejeweled 2 Remastered", 300, 200, 40, Color.White);
            Raylib.DrawText("Press ENTER to Start", 450, 400, 20, Color.Gray);
            Raylib.EndDrawing();
        }
    }
}