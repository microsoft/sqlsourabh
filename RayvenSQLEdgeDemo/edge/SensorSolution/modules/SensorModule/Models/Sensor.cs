using System;

namespace SensorModule.Models
{
  public class Sensor
  {
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Type { get; set; }
    public double NormalMin { get; set; }
    public double NormalMax { get; set; }
    public double AnomalyMin { get; set; }
    public double AnomalyMax { get; set; }
  }
}
