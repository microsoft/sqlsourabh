using System;
using System.Collections.Generic;
using System.Linq;

namespace SensorModule.Helpers
{
  public class GeneratorHelper
  {
    private Random _random = new Random();

    public double GetRandomNumber(double minimum, double maximum)
    {
      return _random.NextDouble() * (maximum - minimum) + minimum;
    }

    public int GetRandomIntNumber(int min, int max)
    {
      return _random.Next(min, max);
    }
  }
}
