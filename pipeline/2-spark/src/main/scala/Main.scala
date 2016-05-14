import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.sql.SQLContext

import org.apache.spark.SparkConf
import OSMTagLoader._

class MainClass {

}

object MainClass {
  
  def main(args: Array[String]) = {
    
    val conf = new SparkConf()
      .setAppName("OSM processing (tests)")
      .setMaster("local[*]")
    val sc = new SparkContext(conf)
    sc.defaultParallelism
     
    // The below code will generate warnings:
    //
    // WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
    // WARN : Your hostname, MM.local resolves to a loopback/non-reachable address: 192.168.0.102, but we couldn't find any external IP address!
    // WARN TaskMemoryManager: leak 32.3 MB memory from org.apache.spark.unsafe.map.BytesToBytesMap@57396d93
    // ERROR Executor: Managed memory leak detected; size = 33816576 bytes, TID = 4
    // 
    // See:
    //   https://issues.apache.org/jira/browse/SPARK-11293
    //
    val sqlContext = new SQLContext(sc)
    val df = OSMTagLoader.loader(sqlContext, "W", "/Users/MM/osm-data/ways-1e5.txt")
    
    println(df.count)
    println(LiveEntries.getLatestVersions(df).show())
    println(LiveEntries.liveData(df).show())
    sc.stop
  }
}