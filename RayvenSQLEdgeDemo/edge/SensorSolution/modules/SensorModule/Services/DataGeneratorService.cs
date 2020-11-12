using System;
using System.Collections.Generic;
using System.Linq;
using SensorModule.Helpers;
using SensorModule.Models;
using SensorModule.Services.Interfaces;

namespace SensorModule.Services
{
  public class DataGeneratorService : IDataGeneratorService
  {
    private const int AnomalyCycleLength = 36;
    private GeneratorHelper gen = new GeneratorHelper();
    private List<Ventilator> ventilators = new List<Ventilator>();
    private int anomalyCounter;

    public DataGeneratorService()
    {
      for (var i = 1; i <= 20; i++)
      {
        ventilators.Add(
          new Ventilator
          {
            VentilatorGuid = Guid.NewGuid(),
            VentilatorNumber = i
          }
        );
      }
    }

    public List<Ventilator> GetVentilators()
    {
      return ventilators;
    }

    public List<RealtimeSensorRecord> GenerateRealTimeSensorRecords(DateTime timestamp)
    {
      var records = new List<RealtimeSensorRecord>();
      ventilators.ForEach(ventilator =>
      {
        var ventilatorRecords = Constants.SensorsList.Select(sensor =>
        {
          double? sensorValue = null;
          var generateWithNull = gen.GetRandomIntNumber(1, 100) <= 5;
          if (ventilator.VentilatorNumber == 1 ||
            (ventilator.VentilatorNumber == 3 && (anomalyCounter % AnomalyCycleLength) == (AnomalyCycleLength - 1)))
          {
            // For first ventilator set the value with anomalies
            // For third ventilator set the value with anomalies on a cycle
            sensorValue = Math.Round(gen.GetRandomNumber(sensor.AnomalyMin, sensor.AnomalyMax), 1);
          }
          else if (ventilator.VentilatorNumber == 2 && generateWithNull)
          {
            // For second ventilator set the value to null if must
            sensorValue = null;
          }
          else
          {
            sensorValue = Math.Round(gen.GetRandomNumber(sensor.NormalMin, sensor.NormalMax), 1);
          }


          if (ventilator.VentilatorNumber == 2 && generateWithNull)
          {
            sensorValue = null;
          }

          return new RealtimeSensorRecord
          {
            RecordId = Guid.NewGuid(),
            VentilatorId = ventilator.VentilatorGuid,
            VentilatorNumber = ventilator.VentilatorNumber,
            Owner = Constants.Owners[gen.GetRandomIntNumber(0, Constants.Owners.Count())],
            SensorId = sensor.Id,
            SensorType = sensor.Type,
            SensorValue = sensorValue,
            Timestamp = timestamp
          };
        });
        records.AddRange(ventilatorRecords);
      });

      anomalyCounter++;
      return records.ToList();
    }
  }
}
