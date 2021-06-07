using System;
using Newtonsoft.Json;
using MathNet.Numerics.Distributions;

namespace TelemetryData
{
    class Telemetry
    {
        static double randomSample(double min, double max)
        {
            Random random = new Random();
            System.Random r = new System.Random();
            double voltage = (Beta.Sample(r, 10, 1) * (max - min)) + min;
            return Math.Round(voltage,4);
        }   
        public static string TelemetryData(int machineid)
        {
            DateTime currtimestamp = DateTime.Now;
            double voltage = randomSample(219,154);
            double Rotate = randomSample(499, 265);
            double Pressure = randomSample(153, 89);
            double Vibration = randomSample(62, 34);
            double Error1 = randomSample(0.25, 0.0);
            double Error2 = randomSample(0.1, 0.0);
            var telemetry = new
            {
                timestamp = currtimestamp,
                var_machineid = machineid,
                var_voltate = voltage,
                var_rotate = Rotate,
                var_pressure = Pressure,
                var_vibration = Vibration,
                var_error1 = Error1,
                var_error2 = Error2
            };

            var messageString = JsonConvert.SerializeObject(telemetry);
            return messageString;
        }
    }
}
