using System;
using System.Collections.Generic;
using SensorModule.Models;

namespace SensorModule.Services.Interfaces
{
  public interface IDataGeneratorService
  {
    List<RealtimeSensorRecord> GenerateRealTimeSensorRecords(DateTime timestamp);
    List<Ventilator> GetVentilators();
  }
}
