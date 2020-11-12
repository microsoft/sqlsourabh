using System;
using System.Collections.Generic;
using SensorModule.Models;

namespace SensorModule
{
  public static class Constants
  {
    public static class Sensors
    {
      public const string OxygenConcentration = "OxygenConcentration";
      public const string Oxygen = "Oxygen";
      public const string VT = "VT";
      public const string ITime = "ITime";
      public const string Epap = "Epap";
      public const string Rise = "Rise";
      public const string TrackerBattery = "TrackerBattery";
      public const string VentilatorBattery = "VentilatorBattery";
      public const string PlateauPressure = "PlateauPressure";
      public const string PeakPressure = "PeakPressure";
      public const string RespiratoryRate = "RespiratoryRate";
      public const string Peep = "Peep";
      public const string FilterPressure = "FilterPressure";
      public const string Rssi = "Rssi";
      public const string Temperature = "Temperature";
      public const string Current = "Current";
    }

    public static List<Sensor> SensorsList = new List<Sensor>{
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.Temperature, NormalMin = 64, NormalMax = 66, AnomalyMin = 81, AnomalyMax = 84},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.Current, NormalMin = 4.9, NormalMax = 5.1, AnomalyMin = 8, AnomalyMax = 9},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.PeakPressure, NormalMin = 30, NormalMax = 32, AnomalyMin = 20, AnomalyMax = 22},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.OxygenConcentration, NormalMin = 90, NormalMax = 99, AnomalyMin = 90, AnomalyMax = 99},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.Oxygen, NormalMin = 21, NormalMax = 21, AnomalyMin = 21, AnomalyMax = 21},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.VT, NormalMin = 750, NormalMax = 750, AnomalyMin = 750, AnomalyMax = 750},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.ITime, NormalMin = 2, NormalMax = 2, AnomalyMin = 2, AnomalyMax = 2},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.Epap, NormalMin = 10, NormalMax = 10, AnomalyMin = 10, AnomalyMax = 10},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.Rise, NormalMin = 2, NormalMax = 2, AnomalyMin = 2, AnomalyMax = 2},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.TrackerBattery, NormalMin = 1, NormalMax = 2, AnomalyMin = 1, AnomalyMax = 2},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.VentilatorBattery, NormalMin = 11, NormalMax = 19, AnomalyMin = 11, AnomalyMax = 19},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.PlateauPressure, NormalMin = 20, NormalMax = 24, AnomalyMin = 20, AnomalyMax = 24},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.RespiratoryRate, NormalMin = 15, NormalMax = 15, AnomalyMin = 15, AnomalyMax = 15},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.Peep, NormalMin = 3, NormalMax = 4, AnomalyMin = 3, AnomalyMax = 4},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.FilterPressure, NormalMin = 153, NormalMax = 200, AnomalyMin = 153, AnomalyMax = 200},
      new Sensor {Id = Guid.NewGuid(), Type = Sensors.Rssi, NormalMin = -65, NormalMax = -50, AnomalyMin = -65, AnomalyMax = -50},
    };

    public static List<string> Owners = new List<string> { "TECH-01", "TECH-02", "TECH-03", "TECH-04" };
  }
}
