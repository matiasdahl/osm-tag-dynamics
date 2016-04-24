import org.scalatest._
import org.apache.spark.sql.SQLContext
import com.holdenkarau.spark.testing._
import OSMTagLoader._

class SparkTests extends FlatSpec with SharedSparkContext {
  
 "spark" should "load text file" in {
   val testFile = sc.textFile("./src/test/resources/4lines.txt")
   assert(testFile.count == 4)
 } 
 
 it should "load 1-line csv file" in {
   val sqlContext = new SQLContext(sc)
   val df = OSMTagLoader.loader(sqlContext, "./src/test/resources/test_columns.tsv")
   assert(df.count == 1)
 }
}