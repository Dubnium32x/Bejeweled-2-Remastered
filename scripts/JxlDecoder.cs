using System;
using System.Diagnostics;
using System.IO;

namespace Bejeweled_2_Remastered.jxl
{
    public static class JxlDecoder
    {
        private static string ffmpegPath = "ffmpeg"; // FFmpeg should be in the system PATH

        public static void ConvertJxlToPng(string inputJxlFile, string outputPngFile)
        {
            ProcessStartInfo processStartInfo = new ProcessStartInfo
            {
                FileName = ffmpegPath,
                Arguments = $"-f jpegxl_pipe -i \"{inputJxlFile}\" \"{outputPngFile}\"",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using (Process process = new Process { StartInfo = processStartInfo })
            {
                process.OutputDataReceived += (sender, e) => Console.WriteLine(e.Data);
                process.ErrorDataReceived += (sender, e) => Console.WriteLine($"ERROR: {e.Data}");

                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                process.WaitForExit();

                if (process.ExitCode != 0)
                {
                    throw new Exception($"FFmpeg failed with exit code {process.ExitCode}");
                }
            }
        }
    }
}