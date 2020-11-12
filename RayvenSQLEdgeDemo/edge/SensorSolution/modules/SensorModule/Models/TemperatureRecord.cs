using System;

namespace SensorModule.Models
{
  public class TemperatureRecord
  {
    public Guid RecordId { get; set; }
    public Guid VentilatorId { get; set; }
    public int VentilatorNumber { get; set; }
    public double? Temperature { get; set; }
    public DateTime Timestamp { get; set; }
  }
}
