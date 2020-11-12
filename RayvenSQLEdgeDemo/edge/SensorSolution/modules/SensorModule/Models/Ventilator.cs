using System;

namespace SensorModule.Models
{
  public class Ventilator
  {
    public Guid VentilatorGuid { get; set; } = Guid.NewGuid();
    public int VentilatorNumber { get; set; }
  }
}
