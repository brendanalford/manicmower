using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace bin2headlerlesstap
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length < 1 || args.Length > 2)
            {
                Console.WriteLine("Usage: bin2headerlesstap <input binary> <optional output file>\n");
                return;
            }
            string filename = args[0];
            string outputFilename = null;
            if (args.Length == 2)
            {
                outputFilename = args[1];
            }
            Console.WriteLine("BIN2HLTAP: converting " + filename);

            FileStream inFile = File.OpenRead(filename);
            byte[] binary = new byte[inFile.Length + 4];
            inFile.Read(binary, 3, (int)inFile.Length);
 
            // Fill in the other bits of data we need
            int totalLen = (int)inFile.Length + 4;
            int dataLen = totalLen - 2;

            binary[0] = (byte)(dataLen % 0x100);
            binary[1] = (byte)(dataLen / 0x100);
            binary[2] = 0xFF;    // Data block
            inFile.Close();
            // Calculate flag byte

            byte flag = 0;
            for (int i = 2; i < totalLen - 1; i++)
            {
                flag ^= binary[i];
            }
            binary[totalLen - 1] = flag;

            // Now write back to file

            if (outputFilename == null)
            {
                outputFilename = filename.Substring(0, filename.LastIndexOf('.')) + ".tap";
            }
            Console.WriteLine("Writing to file " + outputFilename);
            FileStream outFile = File.Create(outputFilename);
            outFile.Write(binary, 0, totalLen);
            outFile.Close();
            Console.WriteLine("Done.");
        }
    }
}
