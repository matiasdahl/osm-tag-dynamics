import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.sql.SQLContext

import org.apache.spark.SparkConf
import OSMTagLoader._

class MainClass {

}

object MainClass {
  
  def main(args: Array[String]) = {
    /*
    val conf = new SparkConf().setAppName("OSM processing (tests)").setMaster("local")
    val sc = new SparkContext(conf)
    //val testFile = sc.textFile("./src/test/resources/4lines.txt").cache()
    //assert(testFile.count == 4)
     
    val sqlContext = new SQLContext(sc)
    val df = OSMTagLoader.loader(sqlContext, "./src/test/resources/test_columns.csv")
    assert(df.count == 1)
    sc.stop*/
  }
}