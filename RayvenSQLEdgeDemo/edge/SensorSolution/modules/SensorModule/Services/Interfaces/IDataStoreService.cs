using System;
using System.Collections.Generic;
using SensorModule.Models;

namespace SensorModule.Services.Interfaces
{
  public interface IDataStoreService
  {
    void SetSqlConnectionString(string sqlConnectionString);
    void DropAndCreateModelTable();
    void InsertModelFromUrl(string url);
    int GetModelResult(Ventilator ventilator, DateTime timestamp);
    void TruncateRealtimeSensorRecordTable();
    void WriteSensorRecordsToDB(List<RealtimeSensorRecord> records);
  }
}
