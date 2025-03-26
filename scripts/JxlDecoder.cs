using System;
using System.Diagnostics;

namespace Bejeweled_2_Remastered.jxl
{
    public static class JxlConverter
    {
        public static string ConvertJxlToPng(string jxlFilePath)
        {
            string pngFilePath = jxlFilePath.Replace(".jxl", ".png");

            // Use an external tool to convert JXL to PNG
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = "jxl2png", // Assuming jxl2png is installed and available in PATH
                Arguments = $"{jxlFilePath} {pngFilePath}",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using (Process process = new Process { StartInfo = startInfo })
            {
                process.Start();
                process.WaitForExit();

                if (process.ExitCode != 0)
                {
                    string error = process.StandardError.ReadToEnd();
                    throw new Exception($"Conversion failed: {error}");
                }
            }

            return pngFilePath;
        }
    }
}