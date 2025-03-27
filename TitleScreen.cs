using System;
using System.Numerics;
using System.IO;

using Lerp;
using Raylib_cs;

using Bejeweled_2_Remastered.jxl;
using Bejeweled_2_Remastered.Screens;

namespace Bejeweled_2_Remastered.Screens
{
    public class TitleScreen : IScreen
    {
        public Font continuumFont = Raylib.LoadFont("res/font/contm.ttf");
        public Font continuumFontBold = Raylib.LoadFont("res/font/contb.ttf");
        public Font continuumFontLight = Raylib.LoadFont("res/font/contl.ttf");
        private ScreenManager screenManager;
        private Texture2D backdrop;
        private Texture2D sparkle;
        private Texture2D sparkleTextureWithAlpha;
        private Texture2D planetTexture;
        private Texture2D planetTextureWithAlpha;
        private Texture2D titleLogoTexture;
        private Texture2D titleLogoTextureWithAlpha;
        private Texture2D popcapLogoTexture;
        private Texture2D popcapLogoTextureWithAlpha;

        // load in other animation frames for 2 logo
        private string[] _2DLogoTextures = new string[20];
        private Texture2D _2LogoTexture;
        private Texture2D _2LogoTextureWithAlpha;

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

        // Define planet properties
        private Vector2 planetPosition;
        
        // Define title logo properties
        public Vector2 titleLogoPosition;
        private Vector2 logoDest;
        private float titleLogoDuration = 1.0f;
        private float titleLogoTimer = 0.0f;
        private float titlePauseTimer = 0.0f;
        private float firstTitlePauseDuration = 2.2f; // Duration of the first pause before the logo moves
        private float secondTitlePauseTimer = 0.0f;
        private float secondTitlePauseDuration = 0.5f; // Duration of the second pause before the logo moves

        // Define 2 logo properties
        private Vector2 _2LogoPosition;
        private float _2LogoDuration = 1.0f;
        private float _2LogoTimer = 0.0f;
        private float _2LogoPauseTimer = 0.0f;
        private float _2LogoPauseDuration = 2.0f; // Duration of the first pause before the logo moves

        // Define popcap logo properties
        private Vector2 popcapLogoPosition;


        public TitleScreen(ScreenManager screenManager)
        {
            this.screenManager = screenManager;
            InitializeStars();
            InitializePlanet();
            InitializeTitleLogo();
            Initialize2LogoTextures();
            InitializePopcapLogo();
        }

        // Load the 2 logo textures

        public void Initialize2LogoTextures()
        {
            _2DLogoTextures[0] = "res/images/title_logo2.jxl";
            _2DLogoTextures[1] = "res/images/title_logo2__frame_0001.jxl";
            _2DLogoTextures[2] = "res/images/title_logo2__frame_0002.jxl";
            _2DLogoTextures[3] = "res/images/title_logo2__frame_0003.jxl";
            _2DLogoTextures[4] = "res/images/title_logo2__frame_0004.jxl";
            _2DLogoTextures[5] = "res/images/title_logo2__frame_0005.jxl";
            _2DLogoTextures[6] = "res/images/title_logo2__frame_0006.jxl";
            _2DLogoTextures[7] = "res/images/title_logo2__frame_0007.jxl";
            _2DLogoTextures[8] = "res/images/title_logo2__frame_0008.jxl";
            _2DLogoTextures[9] = "res/images/title_logo2__frame_0009.jxl";
            _2DLogoTextures[10] = "res/images/title_logo2__frame_0010.jxl";
            _2DLogoTextures[11] = "res/images/title_logo2_1.jxl";
            _2DLogoTextures[12] = "res/images/title_logo2_2.jxl";
            _2DLogoTextures[13] = "res/images/title_logo2_3.jxl";
            _2DLogoTextures[14] = "res/images/title_logo2_4.jxl";
            _2DLogoTextures[15] = "res/images/title_logo2_5.jxl";
            _2DLogoTextures[16] = "res/images/title_logo2_6.jxl";
            _2DLogoTextures[17] = "res/images/title_logo2_7.jxl";
            _2DLogoTextures[18] = "res/images/title_logo2_8.jxl";
            _2DLogoTextures[19] = "res/images/title_logo2_9.jxl";
        }

        public void Load()
        {
            Console.WriteLine("TitleScreen: Loading resources...");
            Program.isLoading = true;
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
            // Load planet texture
            LoadPlanet();
            // Load title logo
            LoadTitleLogo();
            Load2Logo();
            LoadPopcapLogo();
        }

        private void Load2Logo()
        {
            Program.isLoading = true;
            string jxlFilePath1 = _2DLogoTextures[0].ToString();
            string jxlFilePath2 = _2DLogoTextures[1].ToString();
            string jxlFilePath3 = _2DLogoTextures[2].ToString();
            string jxlFilePath4 = _2DLogoTextures[3].ToString();
            string jxlFilePath5 = _2DLogoTextures[4].ToString();
            string jxlFilePath6 = _2DLogoTextures[5].ToString();
            string jxlFilePath7 = _2DLogoTextures[6].ToString();
            string jxlFilePath8 = _2DLogoTextures[7].ToString();
            string jxlFilePath9 = _2DLogoTextures[8].ToString();
            string jxlFilePath10 = _2DLogoTextures[9].ToString();
            string jxlFilePath11 = _2DLogoTextures[10].ToString();
            string jxlFilePath12 = _2DLogoTextures[11].ToString();
            string jxlFilePath13 = _2DLogoTextures[12].ToString();
            string jxlFilePath14 = _2DLogoTextures[13].ToString();
            string jxlFilePath15 = _2DLogoTextures[14].ToString();
            string jxlFilePath16 = _2DLogoTextures[15].ToString();
            string jxlFilePath17 = _2DLogoTextures[16].ToString();
            string jxlFilePath18 = _2DLogoTextures[17].ToString();
            string jxlFilePath19 = _2DLogoTextures[18].ToString();
            string jxlFilePath20 = _2DLogoTextures[19].ToString();

            try
            {
                if (!File.Exists(jxlFilePath1) ||
                    !File.Exists(jxlFilePath2) ||
                    !File.Exists(jxlFilePath3) ||
                    !File.Exists(jxlFilePath4) ||
                    !File.Exists(jxlFilePath5) ||
                    !File.Exists(jxlFilePath6) ||
                    !File.Exists(jxlFilePath7) ||
                    !File.Exists(jxlFilePath8) ||
                    !File.Exists(jxlFilePath9) ||
                    !File.Exists(jxlFilePath10) ||
                    !File.Exists(jxlFilePath11) ||
                    !File.Exists(jxlFilePath12) ||
                    !File.Exists(jxlFilePath13) ||
                    !File.Exists(jxlFilePath14) ||
                    !File.Exists(jxlFilePath15) ||
                    !File.Exists(jxlFilePath16) ||
                    !File.Exists(jxlFilePath17) ||
                    !File.Exists(jxlFilePath18) ||
                    !File.Exists(jxlFilePath19) ||
                    !File.Exists(jxlFilePath20))
                {
                    throw new FileNotFoundException($"A required file does not exist.");
                }

                string pngFilePath1 = JxlConverter.ConvertJxlToPng(jxlFilePath1);
                string pngFilePath2 = JxlConverter.ConvertJxlToPng(jxlFilePath2);
                string pngFilePath3 = JxlConverter.ConvertJxlToPng(jxlFilePath3);
                string pngFilePath4 = JxlConverter.ConvertJxlToPng(jxlFilePath4);
                string pngFilePath5 = JxlConverter.ConvertJxlToPng(jxlFilePath5);
                string pngFilePath6 = JxlConverter.ConvertJxlToPng(jxlFilePath6);
                string pngFilePath7 = JxlConverter.ConvertJxlToPng(jxlFilePath7);
                string pngFilePath8 = JxlConverter.ConvertJxlToPng(jxlFilePath8);
                string pngFilePath9 = JxlConverter.ConvertJxlToPng(jxlFilePath9);
                string pngFilePath10 = JxlConverter.ConvertJxlToPng(jxlFilePath10);
                string pngFilePath11 = JxlConverter.ConvertJxlToPng(jxlFilePath11);
                string pngFilePath12 = JxlConverter.ConvertJxlToPng(jxlFilePath12);
                string pngFilePath13 = JxlConverter.ConvertJxlToPng(jxlFilePath13);
                string pngFilePath14 = JxlConverter.ConvertJxlToPng(jxlFilePath14);
                string pngFilePath15 = JxlConverter.ConvertJxlToPng(jxlFilePath15);
                string pngFilePath16 = JxlConverter.ConvertJxlToPng(jxlFilePath16);
                string pngFilePath17 = JxlConverter.ConvertJxlToPng(jxlFilePath17);
                string pngFilePath18 = JxlConverter.ConvertJxlToPng(jxlFilePath18);
                string pngFilePath19 = JxlConverter.ConvertJxlToPng(jxlFilePath19);
                string pngFilePath20 = JxlConverter.ConvertJxlToPng(jxlFilePath20);
                
                // Check if the PNG files exist after conversion
                if (!File.Exists(pngFilePath1) ||
                    !File.Exists(pngFilePath2) ||
                    !File.Exists(pngFilePath3) ||
                    !File.Exists(pngFilePath4) ||
                    !File.Exists(pngFilePath5) ||
                    !File.Exists(pngFilePath6) ||
                    !File.Exists(pngFilePath7) ||
                    !File.Exists(pngFilePath8) ||
                    !File.Exists(pngFilePath9) ||
                    !File.Exists(pngFilePath10) ||
                    !File.Exists(pngFilePath11) ||
                    !File.Exists(pngFilePath12) ||
                    !File.Exists(pngFilePath13) ||
                    !File.Exists(pngFilePath14) ||
                    !File.Exists(pngFilePath15) ||
                    !File.Exists(pngFilePath16) ||
                    !File.Exists(pngFilePath17) ||
                    !File.Exists(pngFilePath18) ||
                    !File.Exists(pngFilePath19) ||
                    !File.Exists(pngFilePath20))
                {
                    throw new FileNotFoundException($"A logo 2 file does not exist after conversion.");
                }

                Image titleImage1 = Raylib.LoadImage(pngFilePath1);
                Image titleImage2 = Raylib.LoadImage(pngFilePath2);
                Image titleImage3 = Raylib.LoadImage(pngFilePath3);
                Image titleImage4 = Raylib.LoadImage(pngFilePath4);
                Image titleImage5 = Raylib.LoadImage(pngFilePath5);
                Image titleImage6 = Raylib.LoadImage(pngFilePath6);
                Image titleImage7 = Raylib.LoadImage(pngFilePath7);
                Image titleImage8 = Raylib.LoadImage(pngFilePath8);
                Image titleImage9 = Raylib.LoadImage(pngFilePath9);
                Image titleImage10 = Raylib.LoadImage(pngFilePath10);
                Image titleImage11 = Raylib.LoadImage(pngFilePath11);
                Image titleImage12 = Raylib.LoadImage(pngFilePath12);
                Image titleImage13 = Raylib.LoadImage(pngFilePath13);
                Image titleImage14 = Raylib.LoadImage(pngFilePath14);
                Image titleImage15 = Raylib.LoadImage(pngFilePath15);
                Image titleImage16 = Raylib.LoadImage(pngFilePath16);
                Image titleImage17 = Raylib.LoadImage(pngFilePath17);
                Image titleImage18 = Raylib.LoadImage(pngFilePath18);
                Image titleImage19 = Raylib.LoadImage(pngFilePath19);
                Image titleImage20 = Raylib.LoadImage(pngFilePath20);

                Image maskImage = Raylib.LoadImage(jxlFilePath2);

                Image maskedImage1 = ApplyAlphaMask(titleImage1, maskImage);
                Image maskedImage2 = ApplyAlphaMask(titleImage2, maskImage);
                Image maskedImage3 = ApplyAlphaMask(titleImage3, maskImage);
                Image maskedImage4 = ApplyAlphaMask(titleImage4, maskImage);
                Image maskedImage5 = ApplyAlphaMask(titleImage5, maskImage);
                Image maskedImage6 = ApplyAlphaMask(titleImage6, maskImage);
                Image maskedImage7 = ApplyAlphaMask(titleImage7, maskImage);
                Image maskedImage8 = ApplyAlphaMask(titleImage8, maskImage);
                Image maskedImage9 = ApplyAlphaMask(titleImage9, maskImage);
                Image maskedImage10 = ApplyAlphaMask(titleImage10, maskImage);
                Image maskedImage11 = ApplyAlphaMask(titleImage11, maskImage);
                Image maskedImage12 = ApplyAlphaMask(titleImage12, maskImage);
                Image maskedImage13 = ApplyAlphaMask(titleImage13, maskImage);
                Image maskedImage14 = ApplyAlphaMask(titleImage14, maskImage);
                Image maskedImage15 = ApplyAlphaMask(titleImage15, maskImage);
                Image maskedImage16 = ApplyAlphaMask(titleImage16, maskImage);
                Image maskedImage17 = ApplyAlphaMask(titleImage17, maskImage);
                Image maskedImage18 = ApplyAlphaMask(titleImage18, maskImage);
                Image maskedImage19 = ApplyAlphaMask(titleImage19, maskImage);
                Image maskedImage20 = ApplyAlphaMask(titleImage20, maskImage);
                
                _2LogoTextureWithAlpha = Raylib.LoadTextureFromImage(maskedImage3);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading 2 logo: {ex.Message}");
            }

            return maskedImage3, maskedImage4, maskedImage5, maskedImage6, maskedImage7, maskedImage8, maskedImage9, maskedImage10, maskedImage11, maskedImage12, maskedImage13, maskedImage14, maskedImage15, maskedImage16, maskedImage17, maskedImage18, maskedImage19, maskedImage20;
        }

        private void LoadPopcapLogo()
        {
            Program.isLoading = true;
            string jxlFilePath1 = "res/images/title_popcap.jxl";
            string jxlFilePath2 = "res/images/title_popcap__frame_0001.jxl";
            try
            {
                if (!File.Exists(jxlFilePath1))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath1} does not exist.");
                }

                string pngFilePath1 = JxlConverter.ConvertJxlToPng(jxlFilePath1);

                if (!File.Exists(pngFilePath1))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath1} does not exist after conversion.");
                }

                if (!File.Exists(jxlFilePath2))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath2} does not exist.");
                }
                string pngFilePath2 = JxlConverter.ConvertJxlToPng(jxlFilePath2);
                if (!File.Exists(pngFilePath2))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath2} does not exist after conversion.");
                }

                Image popcapImage = Raylib.LoadImage(pngFilePath1);
                Image maskImage = Raylib.LoadImage(pngFilePath2);
                Image maskedImage = ApplyAlphaMask(popcapImage, maskImage);
                popcapLogoTextureWithAlpha = Raylib.LoadTextureFromImage(maskedImage);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading popcap logo: {ex.Message}");
            }
        }

        private void LoadPlanet()
        {
            Program.isLoading = true;
            string jxlFilePath1 = "res/images/planet1_frame_0001.jxl";
            string jxlFilePath2 = "res/images/planet1__frame_0001.jxl";
            try
            {
                if (!File.Exists(jxlFilePath1))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath1} does not exist.");
                }

                string pngFilePath1 = JxlConverter.ConvertJxlToPng(jxlFilePath1);

                if (!File.Exists(pngFilePath1))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath1} does not exist after conversion.");
                }

                if (!File.Exists(jxlFilePath2))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath2} does not exist.");
                }
                string pngFilePath2 = JxlConverter.ConvertJxlToPng(jxlFilePath2);
                if (!File.Exists(pngFilePath2))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath2} does not exist after conversion.");
                }

                Image planetImage = Raylib.LoadImage(pngFilePath1);
                Image maskImage = Raylib.LoadImage(pngFilePath2);
                Image maskedImage = ApplyAlphaMask(planetImage, maskImage);
                planetTextureWithAlpha = Raylib.LoadTextureFromImage(maskedImage);
                Console.WriteLine("Planet texture loaded successfully.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading planet texture: {ex.Message}");
            }
        }

        private void LoadSparkleEffect()
        {
            Program.isLoading = true;
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

        public void LoadTitleLogo()
        {
            Program.isLoading = true;
            bool isLoaded = false;
            // Load the title logo texture
            string jxlFilePath1 = "res/images/title_logo.jxl";
            string jxlFilePath2 = "res/images/title_logo__frame_0001.jxl";

            try
            {
                if (!File.Exists(jxlFilePath1))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath1} does not exist.");
                }

                string pngFilePath1 = JxlConverter.ConvertJxlToPng(jxlFilePath1);

                if (!File.Exists(pngFilePath1))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath1} does not exist after conversion.");
                }

                if (!File.Exists(jxlFilePath2))
                {
                    throw new FileNotFoundException($"The file {jxlFilePath2} does not exist.");
                }
                string pngFilePath2 = JxlConverter.ConvertJxlToPng(jxlFilePath2);
                if (!File.Exists(pngFilePath2))
                {
                    throw new FileNotFoundException($"The PNG file {pngFilePath2} does not exist after conversion.");
                }

                Image titleImage = Raylib.LoadImage(pngFilePath1);
                Image maskImage = Raylib.LoadImage(pngFilePath2);
                Image maskedImage = ApplyAlphaMask(titleImage, maskImage);
                titleLogoTextureWithAlpha = Raylib.LoadTextureFromImage(maskedImage);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading title logo: {ex.Message}");
            }
            // Check if the title logo texture was loaded successfully
            if (File.Exists("res/images/title_logo.png"))
            {
                isLoaded = true;
                Console.WriteLine("Title logo loaded successfully.");
            }
            else
            {
                Console.WriteLine("Failed to load title logo.");
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
            UpdateTitleLogo();
            Update2Logo();
        }

        public void Draw()
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(backgroundColor);
            DrawStars();
            DrawSparkle();
            DrawPlanet();
            DrawTitleLogo();
            Draw2Logo();
            Raylib.DrawTexturePro(backdrop, new Rectangle(0, 0, backdrop.Width, backdrop.Height), new Rectangle(0, 0, Raylib.GetScreenWidth(), Raylib.GetScreenHeight()), new Vector2(0, 0), 0, Color.White);
            DrawPopcapLogo();            
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

        private void InitializePlanet()
        {
            Random rand = new Random();
            planetPosition = new Vector2(Raylib.GetScreenWidth(), Raylib.GetScreenHeight());
        }

        private void InitializeTitleLogo()
        {
            float logoScale = Math.Min(Raylib.GetScreenWidth() / 1280.0f, Raylib.GetScreenHeight() / 720.0f) + 0.5f;
            float initialXPercent = 0.5f; // Center horizontally (0.5 = 50%)
            float initialYPercent = 1.1f;  // Start below the screen (1.1 = 110%)

            titleLogoPosition = new Vector2(
                (Raylib.GetScreenWidth() * initialXPercent) - ((titleLogoTextureWithAlpha.Width * logoScale) / 2),
                Raylib.GetScreenHeight() * initialYPercent
            );
        }

        private void Initialize2Logo()
        {
            float logoScale = Math.Min(Raylib.GetScreenWidth() / 1280.0f, Raylib.GetScreenHeight() / 720.0f) + 0.5f;
            float initialXPercent = 0.5f; // Center horizontally (0.5 = 50%)
            float initialYPercent = 1.1f;  // Start below the screen (1.1 = 110%)

            _2LogoPosition = new Vector2(
                (Raylib.GetScreenWidth() * initialXPercent) - ((_2LogoTextureWithAlpha.Width * logoScale) / 2),
                Raylib.GetScreenHeight() * initialYPercent
            );
        }
        private void InitializePopcapLogo()
        {
            float logoScale = Math.Min(Raylib.GetScreenWidth() / 1280.0f, Raylib.GetScreenHeight() / 720.0f) + 0.5f;
            popcapLogoPosition.X = (Raylib.GetScreenWidth()) - ((logoScale * 50) - (popcapLogoTextureWithAlpha.Width * logoScale));
            popcapLogoPosition.Y = (Raylib.GetScreenHeight() * 0.9f) - ((popcapLogoTextureWithAlpha.Height * logoScale) / 2);
        }
        private void UpdateTitleLogo()
        {
            bool clickedPlay = false;
            titlePauseTimer += Raylib.GetFrameTime();
            if (titlePauseTimer > firstTitlePauseDuration)
            {
                float deltaTime = Raylib.GetFrameTime();
                float targetXPercent = 0.5f; // Center horizontally
                float targetYPercent = 0.05f; // 5% from the top

                Vector2 logoDest = new Vector2(
                    (Raylib.GetScreenWidth() * targetXPercent) - (titleLogoTextureWithAlpha.Width / 2),
                    (Raylib.GetScreenHeight() * targetYPercent) + (100.0f * ((Raylib.GetScreenWidth() / 1280f) + (Raylib.GetScreenHeight() / 720f)) / 2));
                titleLogoTimer += deltaTime;

                if (titleLogoTimer >= titleLogoDuration)
                {
                    titleLogoPosition.Y -= (titleLogoPosition.Y - logoDest.Y) * 0.08f;
                }
                else if (titleLogoPosition.Y == logoDest.Y)
                {
                    if (secondTitlePauseTimer > secondTitlePauseDuration)
                    {
                        titleLogoPosition.Y = logoDest.Y;
                        titleLogoTimer = 0.0f;
                        titlePauseTimer = 0.0f;
                        secondTitlePauseTimer = 0.0f;
                        clickedPlay = true;
                    }
                    else
                    {
                        //secondTitlePauseTimer += deltaTime;
                    }
                }
                else if (titleLogoPosition.Y == logoDest.Y)
                {
                    titleLogoPosition.Y = logoDest.Y;
                }
            }
        }

        private void Update2Logo()
        {
            // Place 2 logo in the center, just below the title logo
            float logoScale = Math.Min(Raylib.GetScreenWidth() / 1280.0f, Raylib.GetScreenHeight() / 720.0f) + 0.5f;
            if (titleLogoPosition.Y > _2LogoPosition.Y)
            {
                // Start animating by swapping image textures
                _2LogoTimer += Raylib.GetFrameTime();
                float t = 0.0f;

                if (_2LogoTimer == 0.05f)
                {
                    _2LogoTextureWithAlpha = Raylib.LoadTexture(maskedImage4);
                }
                else if (_2LogoTimer == 0.1f)
                {
                    _2LogoTextureWithAlpha = Raylib.LoadTexture(_2DLogoTextures[5]);
                }
                else if (_2LogoTimer == 0.15f)
                {
                    _2LogoTextureWithAlpha = Raylib.LoadTexture(_2DLogoTextures[6]);
                }
                else if (_2LogoTimer == 0.2f)
                {
                    _2LogoTextureWithAlpha = Raylib.LoadTexture(_2DLogoTextures[7]);
                }
                else if (_2LogoTimer == 0.25f)
                {
                    _2LogoTextureWithAlpha = Raylib.LoadTexture(_2DLogoTextures[8]);
                }
                else if (_2LogoTimer == 0.3f)
                {
                    _2LogoTextureWithAlpha = Raylib.LoadTexture(_2DLogoTextures[9]);
                }
            }
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
            if (!isSparkling) return;

            sparkleTimer += Raylib.GetFrameTime();
            if (sparkleTimer >= sparkleDuration)
            {
            isSparkling = false;
            sparkleTimer = 0.0f;
            // Randomly select a new star to sparkle
            sparklePosition = starPositions[new Random().Next(starCount)];
            isSparkling = true;
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
        private void DrawPlanet()
        {
            float scale = 0.45f * ((Raylib.GetScreenWidth() / 1280f) + (Raylib.GetScreenHeight() / 720f)) / 2;

            planetPosition.Y -= (starSpeed / 2) * Raylib.GetFrameTime();
            planetPosition.X = Raylib.GetScreenWidth();

            Rectangle sourceRect = new Rectangle(0, 0, planetTextureWithAlpha.Width, planetTextureWithAlpha.Height);
            Rectangle destRect = new Rectangle(planetPosition.X, planetPosition.Y, planetTextureWithAlpha.Width * scale, planetTextureWithAlpha.Height * scale);
            Vector2 origin = new Vector2((planetTextureWithAlpha.Width * scale) / 2, (planetTextureWithAlpha.Height * scale) / 2);
            Raylib.DrawTexturePro(planetTextureWithAlpha, sourceRect, destRect, origin, 0, Color.White);
        }

        private void DrawTitleLogo()
        {
            float scale = 0.25f * ((Raylib.GetScreenWidth() / 1280f) + (Raylib.GetScreenHeight() / 720f)) / 2;
            Rectangle sourceRect = new Rectangle(0, 0, titleLogoTextureWithAlpha.Width, titleLogoTextureWithAlpha.Height);
            Rectangle destRect = new Rectangle(titleLogoPosition.X, titleLogoPosition.Y, titleLogoTextureWithAlpha.Width * scale, titleLogoTextureWithAlpha.Height * scale);
            Vector2 origin = new Vector2((titleLogoTextureWithAlpha.Width * scale) / 2, (titleLogoTextureWithAlpha.Height * scale) / 2);
            Raylib.DrawTexturePro(titleLogoTextureWithAlpha, sourceRect, destRect, origin, 0, Color.White);
        }

        private void DrawPopcapLogo()
        {
            float scale = 0.25f * ((Raylib.GetScreenWidth() / 1280f) + (Raylib.GetScreenHeight() / 720f)) / 2;
            Raylib.DrawTextEx(continuumFont, "Original game by", 
                new Vector2(popcapLogoPosition.X - (250 * scale), (Raylib.GetScreenHeight() * 0.75f)), 
                20, 1, Color.White);
            Rectangle sourceRect = new Rectangle(0, 0, popcapLogoTextureWithAlpha.Width, popcapLogoTextureWithAlpha.Height);
            Rectangle destRect = new Rectangle(popcapLogoPosition.X, popcapLogoPosition.Y, popcapLogoTextureWithAlpha.Width * scale, popcapLogoTextureWithAlpha.Height * scale);
            Vector2 origin = new Vector2((popcapLogoTextureWithAlpha.Width * scale) / 2, (popcapLogoTextureWithAlpha.Height * scale) / 2);
            Raylib.DrawTexturePro(popcapLogoTextureWithAlpha, sourceRect, destRect, origin, 0, Color.White);
        }

        private void Draw2Logo()
        {
            // Draw 2 logo in center of screen
            float scale = 0.25f * ((Raylib.GetScreenWidth() / 1280f) + (Raylib.GetScreenHeight() / 720f)) / 2;
            
            _2LogoPosition.X = (Raylib.GetScreenWidth() / 2) - (_2LogoTextureWithAlpha.Width * scale / 8);
            _2LogoPosition.Y = (Raylib.GetScreenHeight() / 2) - (500 * scale);
            
            Rectangle sourceRect = new Rectangle(0, 0, _2LogoTextureWithAlpha.Width, _2LogoTextureWithAlpha.Height);
            Rectangle destRect = new Rectangle(_2LogoPosition.X, _2LogoPosition.Y, _2LogoTextureWithAlpha.Width * scale, _2LogoTextureWithAlpha.Height * scale);
            Vector2 origin = new Vector2((_2LogoTextureWithAlpha.Width * scale) / 2, (_2LogoTextureWithAlpha.Height * scale) / 2);
            Raylib.DrawTexturePro(_2LogoTextureWithAlpha, sourceRect, destRect, origin, 0, Color.White);
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