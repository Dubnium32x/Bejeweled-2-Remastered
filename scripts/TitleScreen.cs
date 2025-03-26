using System;
using System.Numerics;
using Raylib_cs;

using Bejeweled_2_Remastered.jxl;
using Bejeweled_2_Remastered.Screens;

namespace Bejeweled_2_Remastered.Screens
{
    public class TitleScreen : IScreen
    {
        private ScreenManager screenManager;
        private Texture2D backdrop;

        public TitleScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
        }

        public void Load()
        {
            Console.WriteLine("TitleScreen: Loading resources...");
            string jxlFilePath = "../res/images/backdrops/backdrop_title_A.jxl";
            string pngFilePath = JxlConverter.ConvertJxlToPng(jxlFilePath);
            backdrop = Raylib.LoadTexture(pngFilePath);
            Console.WriteLine("TitleScreen: Resources loaded.");
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
            Raylib.ClearBackground(Color.Black);
            Raylib.DrawTexturePro(backdrop, new Rectangle(0, 0, backdrop.Width, backdrop.Height), new Rectangle(0, 0, Raylib.GetScreenWidth(), Raylib.GetScreenHeight()), new Vector2(0, 0), 0, Color.White);
            Raylib.EndDrawing();
        }
    }
}