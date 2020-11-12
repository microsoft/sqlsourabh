using System;
using System.ComponentModel.DataAnnotations;

namespace SensorModule.Models
{
  public class RealtimeSensorRecord
  {
    [Key]
    public Guid RecordId { get; set; }
    public Guid VentilatorId { get; set; }
    public int VentilatorNumber { get; set; }
    public Guid SensorId { get; set; }
    public string SensorType { get; set; }
    public double? SensorValue { get; set; }
    public string Owner { get; set; }
    public DateTime Timestamp { get; set; }
  }
}
