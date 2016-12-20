using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace buildtzx
{
   class Program
   {
       const byte XORVAL = 0x09;
 
        static FileStream outFile;
        static BinaryWriter bw;

        static void Main(string[] args)
        {
            if (args.Length < 2)
            {
                Console.WriteLine("Usage: buildtzx <output> <input tap> .. <input tzx>\n");
                return;
            }

            string outputFilename = args[0];
           
            Console.WriteLine("BUILDTZX: Creating " + outputFilename);

            outFile = File.Create(outputFilename);
            bw = new BinaryWriter(outFile);

            byte[] tzxHeader = new byte[10];
            Array.Copy(Encoding.UTF8.GetBytes("ZXTape!"), tzxHeader, 7);
            tzxHeader[6] = (byte)'!';
            tzxHeader[7] = 0x1a;
            tzxHeader[8] = 1;
            tzxHeader[9] = 19;

            outFile.Write(tzxHeader, 0, 10);

            WriteDescription("BuildTZX (ManicMower build tools) (C) Brendan Alford 2016");

            for (int i = 1; i < args.Length; i++)
            {
                string param = args[i].ToLower();
                Console.WriteLine("Processing {0}", param);
                if (param.EndsWith(".tap"))
                {
                    ConvertTAP(param);
                }
                else if (param.EndsWith(".bin"))
                {
                    ConvertBIN(param);
                }
                else if (param.EndsWith(".scr"))
                {
                    WriteSCREncoded(param);
                }
            }
            bw.Close();
            outFile.Close();
            Console.WriteLine("Done.");
        }

        static void WriteDescription(string description)
        {
            byte[] binary = new byte[2 + description.Length];
            binary[0] = 0x30;
            binary[1] = (byte)description.Length;
            Array.Copy(Encoding.UTF8.GetBytes(description), 0,  binary, 2, description.Length);

            bw.Write(binary, 0, binary.Length);

        }

        static void WriteSCREncoded(string name)
        {
            FileStream inFile = File.OpenRead(name);
            byte[] buffer = new byte[inFile.Length];
            inFile.Read(buffer, 0, (int)inFile.Length);
            inFile.Close();

            byte xorVal = 0;
            for (int i = 0; i < buffer.Length; i++)
            {
                buffer[i] ^= xorVal++;
            }


            outFile = File.Create("encoded.scr");
            bw = new BinaryWriter(outFile);
            bw.Write(buffer, 0, buffer.Length);
            bw.Close();

        }
        static void ConvertBIN(string name)
        {
            // Construct a custom ID 11 (Turbo loading) block for the data given
            FileStream inFile = File.OpenRead(name);
            byte[] buffer = new byte[inFile.Length];
            inFile.Read(buffer, 0, (int)inFile.Length);
            inFile.Close();

            byte[] binary = new byte[21 + buffer.Length];

            int payLoad = buffer.Length + 2;

            binary[0] = 0x11;   // Turbo block
            binary[1] = 120; // 120, 8 = 0x0878 = 2168
            binary[2] = 8;
            binary[3] = 155; // 155, 2 = 0x29B = 667
            binary[4] = 2;
            binary[5] = 223; // 0x2df = 735
            binary[6] = 2;
            binary[7] = 88; // 0x258 = 600
            binary[8] = 2;
            binary[9] = 176; // 0x4b0 = 1200
            binary[10] = 4;
            binary[11] = 0;
            binary[12] = 4;
            binary[13] = 8;
            binary[14] = 0;
            binary[15] = 1;
            binary[16] = (byte)(payLoad % 0x100);
            binary[17] = (byte)(payLoad / 0x100);
            binary[18] = 0;
            binary[19] = 0xff;

            // Binary[19] and onwards contain data, and binary[length - 1] contains checksum byte

            Array.Copy(buffer, 0, binary, 20, buffer.Length);
            byte xorVal = 0;
            for (int i = 19; i < binary.Length - 1; i++)
            {
                xorVal ^= binary[i];
                binary[i] ^= XORVAL;
            }
            binary[binary.Length - 1] = (byte)(xorVal ^ XORVAL);

            bw.Write(binary, 0, binary.Length);
        }
        static void ConvertTAP(string name)
        {
            // TAP blocks are just ID10 blocks (0x10, Pause, Length and full TAP data).

            FileStream inFile = File.OpenRead(name);
            byte[] buffer = new byte[inFile.Length];
            inFile.Read(buffer, 0, (int)inFile.Length);
            inFile.Close();
            int ptr = 0;
        
            while (ptr < buffer.Length)
            {
                int curBlockLen = buffer[ptr] + (256 * buffer[ptr + 1]);
                byte[] binary = new byte[curBlockLen + 5];
                ptr += 2;
                Array.Copy(buffer, ptr, binary, 5, curBlockLen);
                binary[0] = 0x10;
                binary[1] = 100;
                binary[2] = 0;
                binary[3] = (byte)(curBlockLen % 0x100);
                binary[4] = (byte)(curBlockLen / 0x100);
                bw.Write(binary, 0, binary.Length);
                    ptr += curBlockLen;
            }
        }
    }
}
