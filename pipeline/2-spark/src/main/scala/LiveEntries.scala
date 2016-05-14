import org.apache.spark.sql.SQLContext
import org.apache.spark.sql.types.{StructType, StructField, StringType, IntegerType, BooleanType};

import org.apache.spark.sql.functions._
import org.apache.spark.sql._

object LiveEntries {

  /**
   *  Return a table listing the larger version version of each id
   *
   *  Output schema:
   *
   *    `max_id`         `last_version`
   *    (string)         (int)
   *
   *  Note: entries currently deleted are included.
   */
  def getLatestVersions(df: DataFrame): DataFrame = { 
    df.groupBy("id")
      .max("version")
      .withColumnRenamed("max(version)", "last_version")
  }

  /**
   * Return a data frame (same schema as input csv) that lists the live versions
   * Each `id` has only one row, and currently deleted entries are not included.
   */
  def liveData(df: DataFrame): DataFrame = { 
    val maxDf = getLatestVersions(df)
    maxDf
     .join(df,
         maxDf("last_version") <=> df("version") && 
         maxDf("id") <=> df("id"), "inner")
      .drop(maxDf("id"))
      .drop("last_version")
      .filter("visible = true")
      .drop("visible")
  }
}