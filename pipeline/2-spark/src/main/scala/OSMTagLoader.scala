import org.apache.spark.sql.SQLContext
import org.apache.spark.sql.types.{StructType, StructField, StringType, IntegerType, BooleanType};

import org.apache.spark.sql.functions._
import org.apache.spark.sql._

class OSMTagLoader {
  
}

object OSMTagLoader {
  
  val fullschema = StructType(Array(
    StructField("id", StringType, false),
    StructField("version", IntegerType, false),
    StructField("visible", BooleanType, false),
    StructField("sec1970", StringType, false),
    StructField("amenity", StringType, true),
    StructField("barrier", StringType, true),
    StructField("building", StringType, true),
    StructField("highway", StringType, true),
    StructField("landuse", StringType, true),
    StructField("man_made", StringType, true),
    StructField("natural", StringType, true),
    StructField("railway", StringType, true),
    StructField("shop", StringType, true),
    StructField("sport", StringType, true),
    StructField("surface", StringType, true),
    StructField("tourism", StringType, true)))
    
  def loadCSV(sqlContext: SQLContext, filename: String): DataFrame = {
    import sqlContext.implicits._

    sqlContext.read
      .format("com.databricks.spark.csv")
      .option("header", "true")
      .schema(fullschema)
      .option("delimiter", "\t")
      .load(filename)
      .drop("sec1970")
  }

  def prefaceId(prefix: String, df: DataFrame): DataFrame = {
    val udf_preface = udf((x: String) => prefix + x)
    df.withColumn("id", udf_preface(col("id")))
  }

  def loader(sqlContext: SQLContext, prefix: String, filename: String): DataFrame = {
    prefaceId(prefix, loadCSV(sqlContext, filename))
  }

}

import OSMTagLoader._
