using System;
using Raylib_cs;

namespace Bejeweled_2_Remastered.Screens
{
    public class GameScreen : IScreen
    {
        private ScreenManager screenManager;
        private Texture2D backdrop;

        public GameScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
        }

        public void Load()
        {
            Console.WriteLine("GameScreen: Loading resources...");
            backdrop = Raylib.LoadTexture("res/images/backdrops/backdrop_title_A.jxl");
            Console.WriteLine("GameScreen: Resources loaded.");
        }

        public void Unload()
        {
            Console.WriteLine("GameScreen: Unloading resources...");
            Raylib.UnloadTexture(backdrop);
            Console.WriteLine("GameScreen: Resources unloaded.");
        }

        public void Update()
        {
            // Update game logic here
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(Color.White);
            Raylib.DrawTexture(backdrop, 100, 100, Color.White);
            Raylib.DrawText("Displaying image.png", 200, 50, 20, Color.Black);
            Raylib.EndDrawing();
        }
    }
}