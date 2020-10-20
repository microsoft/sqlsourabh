using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Azure.Devices.Client;
using Newtonsoft.Json;
using System.Threading;
using System.Threading.Tasks;



namespace IronOreSilicaPercent
{
    class SimulatedIronOreInputs
    {

        public static string GenerateSimulatedIronOreData()
        {
            Random random = new Random();
            DateTime currtimestamp = DateTime.Now;
            double Iron_Feed = random.NextDouble() * (5.853373 - 5.083406) + 5.083406;
            double Silica_Feed = random.NextDouble() * (4.667576 - 0.892093) + 0.892093;
            double Starch_Flow =  random.NextDouble() * (18.097433 - 0.002024) + 0.002024;
            double Amina_Flow = random.NextDouble() * (11.294761 - 8.526940) + 8.526940;
            double Ore_Pulp_pH  = random.NextDouble() * (2.987966 - 2.715038) + 2.715038;
            double Flotation_Column_01_Air_Flow = random.NextDouble() * (9.551099 - 7.818521) + 7.818521;
            double Flotation_Column_02_Air_Flow = random.NextDouble() * (9.564830 - 7.814160) + 7.814160;
            double Flotation_Column_03_Air_Flow = random.NextDouble() * (9.488610 - 7.830299) + 7.830299; 
            double Flotation_Column_04_Air_Flow = random.NextDouble() * (9.536278 - 7.944058) + 7.944058;
            double Flotation_Column_01_Level = random.NextDouble() * (11.071762 - 7.649184) + 7.649184;
            double Flotation_Column_02_Level = random.NextDouble() * (11.053295 - 7.711438) + 7.711438;
            double Flotation_Column_03_Level = random.NextDouble() * (11.143194 - 7.564080) + 7.564080;
            double Flotation_Column_04_Level = random.NextDouble() * (10.990837 - 7.816539) + 7.816539;
            double Iron_Concentrate = random.NextDouble() * (5.915214 - 5.745897) + 5.745897;
                    
            var IronOreDataSet = new
            {
                
                timestamp = currtimestamp,
                cur_Iron_Feed =  Iron_Feed,
                cur_Silica_Feed =  Silica_Feed,
                cur_Starch_Flow =  Starch_Flow,
                cur_Amina_Flow =   Amina_Flow,
                cur_Ore_Pulp_pH  = Ore_Pulp_pH ,
                cur_Flotation_Column_01_Air_Flow = Flotation_Column_01_Air_Flow,
                cur_Flotation_Column_02_Air_Flow = Flotation_Column_02_Air_Flow,
                cur_Flotation_Column_03_Air_Flow = Flotation_Column_03_Air_Flow, 
                cur_Flotation_Column_04_Air_Flow = Flotation_Column_04_Air_Flow,
                cur_Flotation_Column_01_Level = Flotation_Column_01_Level,
                cur_Flotation_Column_02_Level = Flotation_Column_02_Level,
                cur_Flotation_Column_03_Level = Flotation_Column_03_Level,
                cur_Flotation_Column_04_Level = Flotation_Column_04_Level,
                cur_Iron_Concentrate = Iron_Concentrate
            };

            var messageString = JsonConvert.SerializeObject(IronOreDataSet);
            return messageString;
        }      
    }

}
